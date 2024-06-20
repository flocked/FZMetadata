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

 // Searches for files at the downloads and documents directory
 query.searchLocations = [.downloadsDirectory, .documentsDirectory]
 
 // Image & videos files, added this week, large than 10mb
 query.predicate = {
     $0.fileTypes(.image, .video) &&
     $0.addedDate.isThisWeek &&
     $0.fileSize.megabytes >= 10
 }
 
 query.resultsHandler = { files, _ in
 // found files
 }
 query.start()
 ```

 It can also fetch metadata attributes for large batches of file URLs.
 ```swift
 // URLs for querying of attributes
 query.urls = videoFileURLs
 
 // Attributes to query
 query.attributes = [.pixelSize, .duration, .fileSize, .creationDate]
 
 query.resultsHandler = { files in
     for file in files {
     // file.pixelSize, file.duration, file.fileSize, file.creationDate
     }
 }
 query.start()
 ```

 It can also monitor for updates to the results via ``monitorResults``.  The query calls your results handler, whenever new files match the query or the observed file attributes change.

 ```swift
 query.predicate = { $0.isScreenCapture } // Screenshots files
 
 // Enables monitoring. Whenever a new screenshot gets captures the results handler gets called
 query.monitorResults = true
 
 query.resultsHandler = { files, _ in
    for file in files {
    // screenshot files
    }
 }
 query.start()
 ```

 Using the query to search files and to fetch metadata attributes is much faster compared to manually search them e.g. via `FileMananger` or `NSMetadataItem`.
 */
open class MetadataQuery: NSObject {
    /// The state of the query.
    public enum State: Int {
        /// The query is in it's initial phase of gathering matching items.
        case isGatheringFiles

        /// The query is monitoring for updates to the result.
        case isMonitoring

        /// The query is stopped.
        case isStopped
    }

    let query = NSMetadataQuery()

    /// The handler that gets called when the results changes with the items of the results and the difference compared to the previous results.
    open var resultsHandler: ((_ items: [MetadataItem], _ difference: ResultsDifference) -> Void)?

    /// The handler that gets called when the state changes.
    open var stateHandler: ((_ state: State) -> Void)?

    let delegate = DelegateProxy()
    
    /// The state of the query.
    open var state: State = .isStopped {
        didSet {
            guard oldValue != state else { return }
            stateHandler?(state)
        }
    }

    /**
     An array of URLs whose metadata attributes are gathered by the query.

     Use this property to scope the metadata query to a collection of existing URLs. The query will gather metadata attributes for these urls.

     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    open var urls: [URL] {
        get { (query.searchItems as? [URL]) ?? [] }
        set { query.searchItems = newValue.isEmpty ? nil : (newValue as [NSURL]) }
    }

    /**
     An array of metadata attributes whose values are fetched by the query.

     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    open var attributes: [MetadataItem.Attribute] {
        get { MetadataItem.Attribute.values(for: query.valueListAttributes) }
        set { let newValue: [MetadataItem.Attribute] = [.path] + newValue
            query.valueListAttributes = newValue.flatMap(\.mdKeys).uniqued()
        }
    }

    /**
     An array of attributes for grouping the result.

     The grouped results can be accessed via ``groupedResults``.

     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    open var groupingAttributes: [MetadataItem.Attribute] {
        get { query.groupingAttributes?.compactMap { MetadataItem.Attribute(rawValue: $0) } ?? [] }
        set {
            let newValue = newValue.flatMap(\.mdKeys).uniqued()
            query.groupingAttributes = newValue.isEmpty ? nil : newValue
        }
    }

    /**
     The predicate used to filter query results.

     The predicate is constructed by comparing ``MetadataItem`` properties to values using operators and functions. For example:

     ```swift
     // fileName begins with "vid", fileSize is larger or equal 1gb and creationDate is before otherDate.
     query.predicate = {
        $0.fileName.begins(with: "vid") &&
        $0.fileSize.gigabytes >= 1 &&
        $0.creationDate.isBefore(otherDate)
     }
     ```

     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     
     A value of `nil` returns any file or directory.

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

     The query can alternativly search globally or at specific scopes via ``searchScopes``.

     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    open var searchLocations: [URL] {
        get { query.searchScopes.compactMap { $0 as? URL } }
        set { query.searchScopes = newValue }
    }

    /**
     An array containing the seatch scopes.

     The query searches for files at the search scropes. The default value is an empty array which indicates that the query searches globally.

     The query can alternativly also search at specific file-system directories via ``searchLocations``.

     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    open var searchScopes: [SearchScope] {
        get { query.searchScopes.compactMap { $0 as? String }.compactMap { SearchScope(rawValue: $0) } }
        set { query.searchScopes = newValue.compactMap(\.rawValue) }
    }

    /**
     An array of sort descriptor objects for sorting the query result.

     Example usage:

     ```swift
     query.sortedBy = [.ascending(.fileSize), .descending(.creationDate)]
     ```

     The result can be sorted by item relevance via the ``MetadataItem/Attribute/queryRelevance`` attribute.

     ```swift
     query.sortedBy = [.ascending(.queryRelevance)]
     ```

     The sorted result can be accessed via ``groupedResults``.

     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    open var sortedBy: [SortDescriptor] {
        set { query.sortDescriptors = newValue }
        get { query.sortDescriptors.compactMap { $0 as? SortDescriptor } }
    }

    /// The interval (in seconds) at which notification of updated results occurs. The default value is `1.0` seconds.
    open var updateNotificationInterval: TimeInterval {
        get { query.notificationBatchingInterval }
        set { query.notificationBatchingInterval = newValue }
    }

    /**
     The queue on whicht results handler gets called.

     Use this property to decouple the processing of results from the thread used to execute the query. This makes it easier to synchronize query result processing with other related operations—such as updating the data model or user interface—which you might want to perform on the main queue.
     */
    open var operationQueue: OperationQueue? {
        get { query.operationQueue }
        set { query.operationQueue = newValue }
    }

    /// Starts the query, if it isn't running and resets the current result.
    open func start() {
        runWithOperationQueue {
            if self.query.start() {
                self.state = .isGatheringFiles
                self.resetResults()
            }
        }
    }
    
    

    /// Stops the  current query from gathering any further results.
    open func stop() {
        state = .isStopped
        query.stop()
    }

    func reset() {
        resultsHandler = nil
        searchScopes = []
        urls = []
        predicate = nil
        attributes = []
        groupingAttributes = []
        sortedBy = []
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
     An array containing the query’s results.

     The array contains ``MetadataItem`` objects. Accessing the result before a query is finished will momentarly pause the query and provide  a snapshot of the current query results.
     */
    open var results: [MetadataItem] {
        updateResults()
        return _results.synchronized
    }

    var resultsCount: Int {
        query.resultCount
    }
    
    var _results: SynchronizedArray<MetadataItem> = []
    var currentResults: SynchronizedArray<MetadataItem> = []

    func updateResults() {
        _results.synchronized = results(at: Array(0 ..< query.resultCount))
    }

    func resetResults() {
        _results.removeAll()
        currentResults.removeAll()
    }

    func results(at indexes: [Int]) -> [MetadataItem] {
        indexes.compactMap { result(at: $0) }
    }

    func result(at index: Int) -> MetadataItem? {
        let result = query.result(at: index) as? MetadataItem
        //    values["kMDItemPath"] = result?.path
        result?.values = resultAttributeValues(at: index)
        return result
    }

    func resultAttributeValues(at index: Int) -> [String: Any] {
        query.values(of: allAttributeKeys, forResultsAt: index)
    }

    var allAttributeKeys: [String] {
        var attributes = query.valueListAttributes
        attributes += ["kMDQueryResultContentRelevance"]
        attributes += predicate?(.root).mdKeys ?? ["kMDItemContentTypeTree"]
        attributes += sortedBy.compactMap(\.key)
        attributes += groupingAttributes.compactMap(\.rawValue)
        return attributes.uniqued()
    }

    /**
     An array containing hierarchical groups of query results.

     These groups are based on the ``groupingAttributes``.
     */
    open var groupedResults: [ResultGroup] {
        query.groupedResults.compactMap { ResultGroup($0) }
    }

    /**
     A Boolean value indicating whether the monitoring of changes to the results is enabled.

     If `true` the ``resultsHandler-swift.property`` gets called whenever the results changes.

     By default, notification of updated results occurs at 1.0 seconds. Use ``updateNotificationInterval`` to change the internval.
     */
    open var monitorResults = false {
        didSet {
            guard oldValue != monitorResults else { return }
            if monitorResults {
                query.enableUpdates()
                if isStarted || !isStopped {
                    state = .isMonitoring
                }
            } else {
                query.disableUpdates()
                if state == .isMonitoring {
                    state = .isStopped
                }
            }
        }
    }
    
    var isStarted: Bool { query.isStarted }
    var isGathering: Bool { query.isGathering }
    var isStopped: Bool { query.isStopped }

    @objc func queryGatheringDidStart(_: Notification) {
        // Swift.debugPrint("MetadataQuery gatheringDidStart")
        resetResults()
        state = .isGatheringFiles
    }

    @objc func queryGatheringFinished(_: Notification) {
        // Swift.debugPrint("MetadataQuery gatheringFinished")
        if monitorResults {
            state = .isMonitoring
        } else {
            state = .isStopped
        }
        
        runWithPausedMonitoring {
            let results = results
            let diff = ResultsDifference.added(_results.synchronized)
            postResults(results, difference: diff)
        }
    }

    @objc func queryGatheringProgress(_: Notification) {
        // Swift.debugPrint("MetadataQuery gatheringProgress")
    }

    @objc func queryUpdated(_ notification: Notification) {
        // Swift.debugPrint("MetadataQuery updated")
        runWithPausedMonitoring {
            let added: [MetadataItem] = (notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [MetadataItem]) ?? []
            let removed: [MetadataItem] = (notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [MetadataItem]) ?? []
            let changed: [MetadataItem] = (notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [MetadataItem]) ?? []

            guard !added.isEmpty || !removed.isEmpty || !changed.isEmpty else { return }
            // Swift.debugPrint("MetadataQuery updated, added: \(added.count), removed: \(removed.count), changed: \(changed.count)")
            _results.remove(removed)
            _results = _results + added
            if !changed.isEmpty {
                (changed + added).forEach { _results.move($0, to: query.index(ofResult: $0) + 1) }
            }
            let diff = ResultsDifference(added: added, removed: removed, changed: changed)
            postResults(_results.synchronized, difference: diff)
            /*
            if currentResults.synchronized != _results.synchronized {
                currentResults.synchronized = _results.synchronized
                postResults(_results.synchronized, difference: diff)
            }
             */
        }
    }
    
    func postResults(_ items: [MetadataItem], difference: ResultsDifference) {
        runWithOperationQueue {
            self.resultsHandler?(items, difference)
        }
    }

    func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringDidStart(_:)), name: .NSMetadataQueryDidStartGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringFinished(_:)), name: .NSMetadataQueryDidFinishGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryUpdated(_:)), name: .NSMetadataQueryDidUpdate, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringProgress(_:)), name: .NSMetadataQueryGatheringProgress, object: query)
    }
    
    /// Creates a metadata query with the specified operation queue.
    public convenience init(queue: OperationQueue) {
        self.init()
        operationQueue = queue
    }

    override public init() {
        super.init()
        reset()
        addObserver()
        query.delegate = delegate
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


#if os(macOS)
import AppKit
extension MetadataQuery {
    /// Displays a Spotlight search results window in Finder for the ``predicate-swift.property``.
    open func showSearchResultsInFinder() {
        if let format = query.predicate?.predicateFormat {
            NSWorkspace.shared.showSearchResults(forQueryString: format)
        }
    }
}
#endif

