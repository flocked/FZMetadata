//
//  MetadataQuery.swift
//
//
//  Created by Florian Zand on 23.08.22.
//

import Foundation
import FZSwiftUtils

/**
 An object that can search file system items and fetch metadata attributes for large batches of items.

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

 It can also fetch metadata attributes for large batches of items via ``attributes``:
 
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

 Using the query to search items and to fetch metadata attributes is much faster compared to manually search them e.g. via `FileMananger` or `NSMetadataItem`.
 */
open class MetadataQuery: NSObject {
    
    /// The state of the query.
    public enum State: Int {
        /// The query is in it's initial phase of gathering matching items.
        case isGatheringItems

        /// The query is monitoring for updates to the results.
        case isMonitoring

        /// The query is stopped.
        case isStopped
    }

    let query = NSMetadataQuery()
    let delegate = Delegate()
    
    var isStarted: Bool { query.isStarted }
    var isGathering: Bool { query.isGathering }
    var isStopped: Bool { query.isStopped }
    
    var _results: SynchronizedArray<MetadataItem> = []
    var _filteredResults: SynchronizedArray<MetadataItem> = []
    var queryAttributes: [String] = []
    var resultsCount: Int { query.resultCount }
    
    let resultsUpdateQueue = OperationQueue(maxConcurrentOperationCount: 1)
    var resultsUpdates = ResultsUpdate()
    
    struct ResultsUpdate: Hashable {
        var added: [MetadataItem] = []
        var removed: [MetadataItem] = []
        var changed: [MetadataItem] = []
        var isEmpty: Bool { self == .init() }
        mutating func reset() { self = .init() }
    }
    
    
    /// The state of the query.
    open internal(set) var state: State = .isStopped
    
    /// The handler that gets called when the results changes with the metadata items of the results and the difference to the previous results.
    open var resultsHandler: ((_ items: [MetadataItem], _ difference: ResultsDifference) -> Void)? = nil

    /**
     An array of URLs whose metadata attributes are gathered by the query.

     Use this property to scope the metadata query to a collection of existing URLs. The query will gather metadata attributes for these urls.

     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var urls: [URL] {
        get { query.searchItems as? [URL] ?? [] }
        set { query.searchItems = newValue.isEmpty ? nil : (newValue as [NSURL]) }
    }

    /**
     An array of metadata attributes whose values are gathered by the query.
     
     If ``monitorResults`` is enabled, any changes to those attributes updates the results and calls the results handler.

     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
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
     
     **For more details about how to construct the predicate and a list of all operators and functions, take a look at ``Predicate-swift.struct``.**
     
     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var predicate: ((Predicate<MetadataItem>) -> (Predicate<Bool>))? {
        didSet {
            query.predicate = predicate?(.init()).predicate ?? NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey)
        }
    }
    
    /// The format string of the predicate.
    open var predicateFormat: String {
        query.predicate?.predicateFormat ?? ""
    }

    /**
     An array of file-system directory URLs.

     The query searches for items at these search locations. An empty array indicates that there is no limitation on where the query searches.
     
     The query can alternativly also search at specific scopes via ``searchScopes``.

     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var searchLocations: [URL] {
        get { query.searchScopes.compactMap { $0 as? URL } }
        set { query.searchScopes = newValue }
    }
    
    /**
     The maximum depth of items at the search locations.
     
     A value of `0` returns only items from the specified search locations and skips any sub directories, while a value of `nil` returns all items.
     */
    var maxSearchLocationsDepth: Int? = nil {
        didSet {
            guard oldValue != maxSearchLocationsDepth else { return }
            updateFilteredResults()
        }
    }
    
    func updateFilteredResults() {
        if !searchLocations.isEmpty, let depth = maxSearchLocationsDepth {
            var results = _results.synchronized
            results = results.sorted(by: \.path)
            let searchLocations = searchLocations.sorted(by: \.path)
            _filteredResults.synchronized = results.filter({
                if let url = $0.url {
                    return self.searchLocations.contains(where: { url.childDepth(in: $0) <= depth })
                }
                return false
            })
        } else {
            _filteredResults.removeAll()
        }
    }

    /**
     An array containing the seatch scopes.

     The query searches for items at the search scropes. The default value is an empty array which indicates that there is no limitation on where the query searches.
          
     The query can alternativly also search at specific file-system directories via ``searchLocations``.

     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
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

     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
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
     query.groupingAttributes = [.contentType, .extension]
     
     // ... later
     for group in query.groupedResults {
     
        // items with matching contentType.
        let items = group.items
  
        for subGroup in group.subGroups! {
     // items with matching finder tags.
            let items = subGroup.items
        }
     }
     ```

     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var groupingAttributes: [MetadataItem.Attribute] {
        get { query.groupingAttributes?.compactMap { MetadataItem.Attribute(rawValue: $0) } ?? [] }
        set { query.groupingAttributes = newValue.flatMap(\.mdKeys).uniqued() }
    }

    /**
     The queue on which results handler gets called.

     Use this property to decouple the processing of results from the thread used to execute the query. This makes it easier to synchronize query result processing with other related operations—such as updating the data model or user interface—which you might want to perform on the main queue.
     */
    open var operationQueue: OperationQueue? {
        get { query.operationQueue }
        set { query.operationQueue = newValue }
    }
    
    /**
     A Boolean value indicating whether the monitoring of changes to the results is enabled.

     If `true` the ``resultsHandler`` gets called whenever the results changes. In the following example the result handler is called whenever a screenshot is captured.
     
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
    
    /**
     A Boolean value indicating whether changes to the results are posted during gathering the final results.
     
     If `true` changes to the results while gathering are posted at the interval specified by ``updateNotificationInterval``.
     */
    open var postGatheringUpdates: Bool = false

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

     The array contains ``MetadataItem`` objects. Accessing the results before a query is finished will momentarly pause the query and provide a snapshot of the current query results.
     */
    open var results: [MetadataItem] {
        if state == .isGatheringItems, _results.count != resultsCount {
            updateResults()
        }
        return _results.synchronized
    }
            
    func updateResults() {
        runWithPausedMonitoring {
            var results = (0..<resultsCount).compactMap({ result(at: $0) })
            var prependResults: [MetadataItem] = []
            if sortURLResults, sortedBy.isEmpty, !urls.isEmpty {
                for url in urls {
                    if let index = results.firstIndex(where: {$0.url == url }) {
                        prependResults.append(results.remove(at: index))
                    }
                }
            }
            _results.synchronized = prependResults + results
        }
    }
    
    ///  Sorts results in order of the provided ``urls``.
    var sortURLResults: Bool = false
    
    func updateResults(added: [MetadataItem], removed: [MetadataItem], changed: [MetadataItem], post: Bool = true) {
        runWithPausedMonitoring {
            guard !added.isEmpty || !removed.isEmpty || !changed.isEmpty else { return }
            var results = _results.synchronized
            results.remove(removed)
            results.forEach({ item in
                item._updatedAttributes = []
                item.previousValues = nil
            })
            results = results + added
            (changed + added).forEach { item in
                let index = query.index(ofResult: item)
                updateResult(item, index: index, inital: false)
            }
            results.forEach({ item in
                let index = query.index(ofResult: item)
                item.queryIndex = index
            })
            results = results.sorted(by: \.queryIndex)
            _results.synchronized = results
            guard post else { return }
            let diff = ResultsDifference(added: added, removed: removed, changed: changed)
            if added.isEmpty, removed.isEmpty, !changed.isEmpty {
                if changed.contains(where: { !$0.updatedAttributes.isEmpty }) {
                    postResults(difference: diff)
                }
            } else {
                postResults(difference: diff)
            }
        }
    }
    
    func updateResultsAsync(added: [MetadataItem], removed: [MetadataItem], changed: [MetadataItem]) {
        resultsUpdateQueue.addOperation(ResultsUpdateOperation(self, added: added, removed: removed, changed: changed))
    }
        
    func cancelAllResultsUpdates() {
        resultsUpdateQueue.cancelAllOperations()
        resultsUpdates = ResultsUpdate()
    }

    func result(at index: Int) -> MetadataItem? {
        guard let result = query.result(at: index) as? MetadataItem else { return nil }
        result.queryIndex = index
        updateResult(result, index: index, inital: true)
        return result
    }
        
    func updateResult(_ item: MetadataItem, index: Int, inital: Bool) {
        var values = query.values(of: queryAttributes, forResultsAt: index)
        values[MetadataItem.Attribute.path.rawValue] = item.item.value(forAttribute: MetadataItem.Attribute.path.rawValue)
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

    @objc func queryGatheringDidStart(_: Notification) {
        // Swift.debugPrint("MetadataQuery gatheringDidStart")
        _results.removeAll()
        queryAttributes = (query.valueListAttributes + sortedBy.compactMap(\.key) + (query.groupingAttributes ?? [])).uniqued()
        state = .isGatheringItems
        cancelAllResultsUpdates()
    }

    @objc func queryGatheringFinished(_ notification: Notification) {
        // Swift.debugPrint("MetadataQuery gatheringFinished")
      //  cancelAllResultsUpdates()
        if monitorResults {
            state = .isMonitoring
        } else {
            stop()
        }
        if !postGatheringUpdates {
            updateResults()
            postResults(difference: .added(results))
            resultsUpdates.reset()
        }
    }

    @objc func queryGatheringProgress(_ notification: Notification) {
        // Swift.debugPrint("MetadataQuery gatheringProgress", notification.added.count, notification.removed.count, notification.changed.count, _results.count)
        if postGatheringUpdates {
            if !resultsUpdates.isEmpty {
                updateResults(added: resultsUpdates.added, removed: resultsUpdates.removed, changed: resultsUpdates.changed)
                resultsUpdates.reset()
            }
            updateResults(added: notification.added, removed: notification.removed, changed: notification.changed)
        } else {
            resultsUpdates.added += notification.added
            resultsUpdates.removed += notification.removed
            resultsUpdates.changed += notification.changed
        }
        
        if state != .isGatheringItems {
            let results = results.sorted(by: \.queryIndex)
            updateResults()
            Swift.print("Funushed", self._results.synchronized == results, self._results.synchronized.count, results.count)
        }
    }

    @objc func queryUpdated(_ notification: Notification) {
        // Swift.debugPrint("MetadataQuery updated, added: \(notification.added.count), removed: \(notification.removed.count), changed: \(notification.changed.count)", _results.count)
        updateResults(added: notification.added, removed: notification.removed, changed: notification.changed)
    }
        
    func postResults(difference: ResultsDifference? = nil) {
        let results = _results.synchronized
        runWithOperationQueue {
            self.resultsHandler?(results, difference ?? .added(results))
        }
    }
    
    func runWithPausedMonitoring(_ block: () -> Void) {
        let monitors = monitorResults
        monitorResults = false
        block()
        monitorResults = monitors
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
    
    func reset() {
        predicate = nil
        attributes = []
        searchScopes = []
        urls = []
        groupingAttributes = []
        sortedBy = []
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
        reset()
        
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringDidStart(_:)), name: .NSMetadataQueryDidStartGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringFinished(_:)), name: .NSMetadataQueryDidFinishGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryUpdated(_:)), name: .NSMetadataQueryDidUpdate, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringProgress(_:)), name: .NSMetadataQueryGatheringProgress, object: query)
    }
}

extension MetadataQuery {
    class Delegate: NSObject, NSMetadataQueryDelegate {
        func metadataQuery(_ query: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> Any {
            MetadataItem(item: result)
        }
    }
    
    class ResultsUpdateOperation: Operation {
        weak var query: MetadataQuery?
        let added: [MetadataItem]
        let changed: [MetadataItem]
        let removed: [MetadataItem]
        
        init(_ query: MetadataQuery? = nil, added: [MetadataItem], removed: [MetadataItem], changed: [MetadataItem]) {
            self.query = query
            self.added = added
            self.removed = removed
            self.changed = changed
            super.init()
        }
        
        override func start() {
            guard isCancelled == false, let query = query else { return }
            query.runWithPausedMonitoring {
                var results = query._results.synchronized
                results.remove(removed)
                results.forEach({ item in
                    guard !isCancelled else { return }
                    item._updatedAttributes = []
                    item.previousValues = nil
                })
                results = results + added
                guard !isCancelled else { return }
                if !changed.isEmpty || !added.isEmpty {
                    (changed + added).forEach { item in
                        guard !isCancelled else { return }
                        let index = query.query.index(ofResult: item)
                        results.move(item, to: index)
                        query.updateResult(item, index: index, inital: false)
                    }
                }
                query._results.synchronized = results
                let diff = ResultsDifference(added: added, removed: removed, changed: changed)
                guard !isCancelled else { return }
                if added.isEmpty, removed.isEmpty, !changed.isEmpty {
                    if changed.contains(where: { !$0.updatedAttributes.isEmpty }) {
                        query.postResults(difference: diff)
                    }
                } else {
                    query.postResults(difference: diff)
                }
            }
        }
    }
}

extension Notification {
    var added: [MetadataItem] { userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [MetadataItem] ?? [] }
    var removed: [MetadataItem] { userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [MetadataItem] ?? [] }
    var changed: [MetadataItem] { userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [MetadataItem] ?? [] }
}


#if os(macOS)
import AppKit
// Not working
extension MetadataQuery {
    /// Displays a Spotlight search results window in Finder for the ``predicate-swift.property``.
    func showSearchResultsInFinder() {
        if let format = query.predicate?.predicateFormat {
            NSWorkspace.shared.showSearchResults(forQueryString: format)
        }
    }
}
#endif

