//
//  MetadataQuery.swift
//
//
//  Created by Florian Zand on 23.08.22.
//

import Foundation
import FZSwiftUtils

/**
 An object that can search files and fetch metadata attributes for large batches of files.

 With `MetadataQuery`, you can perform complex queries on the file system using various search parameters, such as search loction and metadata attributes like file name, type, creation date, modification date, and more.

 ```swift
 let query = MetadataQuery()
 query.searchLocations = [.downloadsDirectory]
 
 // Videos files, added this week, large than 10mb
 query.predicate = {
     $0.fileType == .video &&
     $0.addedDate.isThisWeek &&
     $0.fileSize.megabytes >= 10
 }
 query.resultsHandler = { files, _ in
    // matching files
 }
 query.start()
 ```
 
 ## Fetching Attributes

 It can also fetch metadata attributes for large batches of files via ``attributes``:
 
 ```swift
 query.urls = videoFileURLs
 query.attributes = [.pixelSize, .duration, .fileSize, .creationDate]
 query.resultsHandler = { files in
     for file in files {
     // file.pixelSize, file.duration, file.fileSize, file.creationDate
     }
 }
 query.start()
 ```
 
 ## Monitoring Results

 It can also monitor for updates to the results via ``monitorResults``.  The query calls your results handler, whenever the matching items changes or the observed attributes of the items change.

 In the following example the results handler is called whenever the available screenshots change:
 
 ```swift
 query.predicate = { $0.isScreenCapture } // Screenshots files
 query.monitorResults = true
 query.resultsHandler = { items, _ in
    // Screenshot files
 }
 query.start()
 ```

 Using the query to search files and to fetch metadata attributes is much faster compared to manually search them e.g. via `FileMananger` or `NSMetadataItem`.
 */
open class MetadataQuery: NSObject {

    let query = NSMetadataQuery()
    let delegate = Delegate()
    
    /// The state of the query.
    open var state: State = .isStopped
    
    /// The state of the query.
    public enum State: Int {
        /// The query is in it's initial phase of gathering matching items.
        case isGatheringFiles

        /// The query is monitoring for updates to the results.
        case isMonitoring

        /// The query is stopped.
        case isStopped
    }
    
    /// The handler that gets called when the results changes with the metadata items of the results and the difference to the previous results.
    open var resultsHandler: ((_ items: [MetadataItem], _ difference: ResultsDifference) -> Void)? = nil

    /**
     An array of URLs whose metadata attributes are gathered by the query.

     Use this property to scope the metadata query to a collection of existing URLs. The query will gather metadata attributes for these urls.

     Setting this property while a query is running stops the query and discards the current results and immediately starts a new query.
     */
    open var urls: [URL] {
        get { (query.searchItems as? [URL]) ?? [] }
        set { query.searchItems = newValue.isEmpty ? nil : (newValue as [NSURL]) }
    }

    /**
     An array of metadata attributes whose values are gathered by the query.
     
     If ``monitorResults`` is enabled, any changes to those attributes updates the results and calls the results handler.

     Setting this property while a query is running stops the query and discards the current results and immediately starts a new query.
     */
    open var attributes: [MetadataItem.Attribute] {
        get { MetadataItem.Attribute.values(for: query.valueListAttributes) }
        set { query.valueListAttributes = (newValue + [.path]).flatMap(\.mdKeys).uniqued() }
    }

    /**
     The predicate used to filter query results.
     
     A value of `nil` returns all files and directories.

     The predicate is constructed by comparing ``MetadataItem`` properties to values using operators and functions. For example:

     ```swift
     // fileName begins with "vid", fileSize is larger or equal 1gb and creationDate is before otherDate.
     query.predicate = {
        $0.fileName.begins(with: "vid") &&
        $0.fileSize.gigabytes >= 1 &&
        $0.creationDate.isBefore(otherDate)
     }
     ```

     Setting this property while a query is running stops the query and discards the current results and immediately starts a new query.
     
     **For more details about how to construct the predicate and a list of all operators and functions, take a look at ``Predicate-swift.struct``.**
     */
    open var predicate: ((Predicate<MetadataItem>) -> (Predicate<Bool>))? {
        didSet {
            query.predicate = predicate?(.root).predicate ?? NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey)
        }
    }
    
    /// The format string of the predicate.
    open var predicateFormat: String {
        query.predicate?.predicateFormat ?? ""
    }

    /**
     An array of file-system directory URLs.

     The query searches for files at these search locations. An empty array indicates that there is no limitation on where the query searches.
     
     The query can alternativly also search at specific scopes via ``searchScopes``.

     Setting this property while a query is running stops the query and discards the current results and immediately starts a new query.
     */
    open var searchLocations: [URL] {
        get { query.searchScopes.compactMap { $0 as? URL } }
        set { query.searchScopes = newValue }
    }

    /**
     An array containing the seatch scopes.

     The query searches for files at the search scropes. The default value is an empty array which indicates that there is no limitation on where the query searches.
          
     The query can alternativly also search at specific file-system directories via ``searchLocations``.

     Setting this property while a query is running stops the query and discards the current results and immediately starts a new query.
     */
    open var searchScopes: [SearchScope] {
        get { query.searchScopes.compactMap { $0 as? String }.compactMap { SearchScope(rawValue: $0) } }
        set { query.searchScopes = newValue.compactMap(\.rawValue) }
    }

    /**
     The sort descriptors for sorting the query results.

     Example usage:

     ```swift
     query.sortedBy = [.descending(.creationDate), .ascending(.fileSize)]
     ```

     The results can also be sorted by item relevance via ``MetadataItem/Attribute/queryContentRelevance``:

     ```swift
     query.sortedBy = [.ascending(.queryRelevance)]
     ```

     Setting this property while a query is running stops the query and discards the current results and immediately starts a new query.
     */
    open var sortedBy: [SortDescriptor] {
        get { query.sortDescriptors.compactMap { $0 as? SortDescriptor } }
        set { query.sortDescriptors = newValue }
    }
    
    /**
     An array of attributes for grouping the results.

     The grouped results can be accessed via ``groupedResults``.
     the items of the results are grouped by unique content types (e.g. video, image…). Each group contains the matching items and sub groups where it's matching items are grouped by unique finder tags:
     
     ```
     query.groupingAttributes = [.contentType, .finderTags]
     
     // ... later
     for group in query.groupedResults {
     
        group.items // items with same content type
  
        for subGroup in group.subGroups! {
            subGroup.items // items with same finder tags
        }
     }
     ```

     Setting this property while a query is running stops the query and discards the current results and immediately starts a new query.
     */
    open var groupingAttributes: [MetadataItem.Attribute] {
        get { query.groupingAttributes?.compactMap { MetadataItem.Attribute(rawValue: $0) } ?? [] }
        set {
            let newValue = newValue.flatMap(\.mdKeys).uniqued()
            query.groupingAttributes = newValue.isEmpty ? nil : newValue
        }
    }

    /**
     The queue on whicht results handler gets called.

     Use this property to decouple the processing of results from the thread used to execute the query. This makes it easier to synchronize query result processing with other related operations—such as updating the data model or user interface—which you might want to perform on the main queue.
     */
    open var operationQueue: OperationQueue? {
        get { query.operationQueue }
        set { query.operationQueue = newValue }
    }
    
    /**
     A Boolean value indicating whether the monitoring of changes to the results is enabled.

     If `true` the ``resultsHandler`` gets called whenever the results changes. For example:
     
     ```swift
     query.predicate = { $0.isScreenCapture }
     query.monitorResults = true
     query.resultsHandler = { items, _ in
        // Is called whenever a new screenshot is taken.
     }
     query.start()
     ```
     
     By default, notification of updated results occurs at 1.0 seconds. Use ``updateNotificationInterval`` to change the internval.
     */
    open var monitorResults = false {
        didSet {
            guard oldValue != monitorResults else { return }
            if monitorResults {
                query.enableUpdates()
            } else {
                query.disableUpdates()
            }
        }
    }
    /// The interval (in seconds) at which notification of updated results occurs. The default value is `1.0` seconds.
    open var updateNotificationInterval: TimeInterval {
        get { query.notificationBatchingInterval }
        set { query.notificationBatchingInterval = newValue }
    }

    /// Starts the query and discards the previous results.
    open func start() {
        runWithOperationQueue {
            self.query.start()
        }
    }
    
    /// Stops the query from gathering any further results.
    open func stop() {
        state = .isStopped
        query.stop()
    }

    /**
     An array containing the query’s results.

     The array contains ``MetadataItem`` objects. Accessing the results before a query is finished will momentarly pause the query and provide  a snapshot of the current query results.
     */
    open var results: [MetadataItem] {
        if state != .isStopped {
            updateResults()
        }
        return _results.synchronized
    }

    var resultsCount: Int {
        query.resultCount
    }
    
    var _results: SynchronizedArray<MetadataItem> = []

    /*
    func updateResults() {
        runWithPausedMonitoring {
            _results.synchronized = self.results(at: Array(0 ..< self.query.resultCount))
        }
    }
     */
    
    func updateResults() {
        var results: [MetadataItem] = []
        query.enumerateResults { item, index, _ in
            let item = item as! MetadataItem
            updateResult(item, index: index, inital: true)
            results.append(item)
        }
        _results.synchronized = results
    }
    
    func updateResults(added: [MetadataItem], removed: [MetadataItem], changed: [MetadataItem]) {
        runWithPausedMonitoring {
            guard !added.isEmpty || !removed.isEmpty || !changed.isEmpty else { return }
            // Swift.debugPrint("MetadataQuery updated, added: \(added.count), removed: \(removed.count), changed: \(changed.count)")
            var results = _results.synchronized
            results.remove(removed)
            results.forEach({ item in
                item._updatedAttributes = []
                item.previousValues = nil
            })
            results = results + added
            if !changed.isEmpty || !added.isEmpty {
                (changed + added).forEach { item in
                    let index = query.index(ofResult: item)
                    results.move(item, to: index)
                    updateResult(item, index: index, inital: false)
                }
            }
            _results.synchronized = results
            let diff = ResultsDifference(added: added, removed: removed, changed: changed)
            if added.isEmpty, removed.isEmpty, !changed.isEmpty {
                if changed.contains(where: { !$0.updatedAttributes.isEmpty }) {
                    postResults(results, difference: diff)
                }
            } else {
                postResults(results, difference: diff)
            }
        }
    }

    func result(at index: Int) -> MetadataItem? {
        guard let result = query.result(at: index) as? MetadataItem else { return nil }
        updateResult(result, index: index, inital: true)
        return result
    }
    
    func results(at indexes: [Int]) -> [MetadataItem] {
        return indexes.compactMap { result(at: $0) }
    }
    /// All attributes of the query.
    var queryAttributes: [String] = []
    
    func updateQueryAttributes() {
        queryAttributes = query.valueListAttributes
        queryAttributes += ["kMDQueryResultContentRelevance"]
        queryAttributes += predicate?(.root).mdKeys ?? []
        queryAttributes += sortedBy.compactMap(\.key)
        queryAttributes += groupingAttributes.compactMap(\.rawValue)
        queryAttributes = queryAttributes.uniqued()
    }
    
    func updateResult(_ item: MetadataItem, index: Int, inital: Bool) {
        var values = query.values(of: queryAttributes, forResultsAt: index)
        if queryAttributes.contains("kMDItemURL"), values["kMDItemURL"] == nil {
            values["kMDItemURL"] = item.item.value(forAttribute: "kMDItemURL")
        }
        values["kMDItemPath"] = item.item.value(forAttribute: "kMDItemPath")
        item.previousValues = inital ? nil : item.values
        item.values = values
    }

    /**
     An array containing hierarchical groups of query results.

     These groups are based on the ``groupingAttributes``.
     */
    open var groupedResults: [ResultGroup] {
        query.groupedResults.compactMap { ResultGroup($0) }
    }
    
    var isStarted: Bool { query.isStarted }
    var isGathering: Bool { query.isGathering }
    var isStopped: Bool { query.isStopped }

    @objc func queryGatheringDidStart(_: Notification) {
        // Swift.debugPrint("MetadataQuery gatheringDidStart")
        _results.removeAll()
        updateQueryAttributes()
        state = .isGatheringFiles
    }

    @objc func queryGatheringFinished(_: Notification) {
        // Swift.debugPrint("MetadataQuery gatheringFinished")
        if monitorResults {
            state = .isMonitoring
        } else {
            stop()
        }
        
        updateResults()
        let results = _results.synchronized
        postResults(results, difference: .added(results))
    }

    @objc func queryGatheringProgress(_: Notification) {
        // Swift.debugPrint("MetadataQuery gatheringProgress")
    }

    @objc func queryUpdated(_ notification: Notification) {
        let added = (notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [MetadataItem]) ?? []
        let removed = (notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [MetadataItem]) ?? []
        let changed = (notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [MetadataItem]) ?? []
        // Swift.debugPrint("MetadataQuery updated, added: \(added.count), removed: \(removed.count), changed: \(changed.count)")
        updateResults(added: added, removed: removed, changed: changed)
    }
    
    func postResults(_ items: [MetadataItem], difference: ResultsDifference) {
        runWithOperationQueue {
            self.resultsHandler?(items, difference)
        }
    }
    
    func runWithPausedMonitoring(_ block: () -> Void) {
        let _monitorResults = monitorResults
        monitorResults = false
        block()
        monitorResults = _monitorResults
    }
    
    func runWithOperationQueue(_ block: @escaping () -> Void) {
        if let operationQueue = operationQueue {
            operationQueue.addOperation {
                block()
            }
        } else {
            block()
        }
    }
    
    /**
     Creates a metadata query with the specified operation queue.
     
     - Parameter queue: The queue on whicht results handler gets called.
     */
    public convenience init(queue: OperationQueue) {
        self.init()
        operationQueue = queue
    }

    /// Creates a metadata query.
    override public init() {
        super.init()
        query.delegate = delegate
        
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringDidStart(_:)), name: .NSMetadataQueryDidStartGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringFinished(_:)), name: .NSMetadataQueryDidFinishGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryUpdated(_:)), name: .NSMetadataQueryDidUpdate, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringProgress(_:)), name: .NSMetadataQueryGatheringProgress, object: query)
    }
}


/*
#if os(macOS)
import AppKit
extension MetadataQuery {
    /// Displays a Spotlight search results window in Finder for the ``predicate-swift.property``.
    public func showSearchResultsInFinder() {
        if let format = query.predicate?.predicateFormat {
            NSWorkspace.shared.showSearchResults(forQueryString: format)
        }
    }
}
#endif
*/
