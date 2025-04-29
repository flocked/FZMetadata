//
//  MetadataQuery.swift
//
//
//  Created by Florian Zand on 23.08.22.
//

import Foundation
import FZSwiftUtils
import _MDQueryInterposer

/**
 A query object that can search and observe file system items and fetch large batches of metadata attributes.
 
 With `MetadataQuery`you can perform complex queries on the file system using various search parameters, such as search loction and metadata attributes like file name, type, size, creation date, pixel size, video duration, and more.
 
 In the following example the query collects all video files that are larger than 10MB and were added this week:
 
 ```swift
 let query = MetadataQuery()
 query.searchLocations = [.downloadsDirectory]
 query.predicate = {
     $0.fileType == .video &&
     $0.addedDate == .thisWeek &&
     $0.fileSize.megabytes >= 10
 }
 query.resultsHandler = { files, _ in
    // matching files
 }
 query.start()
 ```
 
 The handler is called when all matching files are found. By enabling ``postGatheringUpdates``
 
 By enabling ``monitorResults``, the query can monitor for updates to the results and posts the updated results also to the results handler.
 
 ## Fetching Attributes

 It can also fetch metadata attributes for large batches of items via ``attributes``.
 
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

 It can also monitor for updates to the results via ``monitorResults``.  The query calls the results handler, whenever the matching results updates or attributes change.

 In the following example the results handler is called whenever the available screenshots change:
 
 ```swift
 query.predicate = { $0.isScreenCapture } // Screenshots files
 query.monitorResults = true
 query.resultsHandler = { items, _ in
    // Screenshot files
 }
 query.start()
 ```

 Using the query for searching items and fetching metadata attributes is much faster compared to manually gather them e.g. via `FileMananger` or `NSMetadataItem`.
 */
open class MetadataQuery: NSObject {
    
    /// The state of the query.
    @objc public enum State: Int, CustomStringConvertible {
        /// The query is in it's initial phase of gathering all matching items.
        case isGathering
        /// The query is monitoring for updates to the results.
        case isMonitoring
        /// The query is stopped.
        case isStopped
        /// The query is paused.
        case isPaused
        
        public var description: String {
            switch self {
            case .isGathering: return "isGathering"
            case .isMonitoring: return "isMonitoring"
            case .isStopped: return "isStopped"
            case .isPaused: return "isPaused"
            }
        }
    }

    static var query: MetadataQuery?
    static var maxResults: Int?
    static var batchingParameters: ResultsUpdateOptions?
    static var options: Options?
    public let query = NSMetadataQuery()
    var pausedState: State = .isPaused
    let delegate = Delegate()
    var _results: SynchronizedArray<MetadataItem> = []
    var pendingResultsUpdate = ResultsDifference()
    var queryAttributes: [String] = []
    var isFinished = false
    var didPostFinished = false
    var delayedPostFinishedResults: DispatchWorkItem?
    var prefetchesItemPathsInBackground = true
    let itemPathPrefetchOperationQueue = OperationQueue(maxConcurrentOperationCount: 80)
    var resultsUpdateLock = NSLock()
    var mdQuery: MDQuery?
    /// A Boolean value indicating whether the query should output debug messages.
    public var debug = false
    
    /// The state of the query.
    @objc dynamic open internal(set) var state: State = .isStopped
    
    /// The handler that gets called when the results changes with the metadata items of the results and the difference to the previous results.
    open var resultsHandler: ((_ items: [MetadataItem], _ difference: ResultsDifference) -> Void)? = nil

    /**
     An array of metadata attributes whose values are gathered by the query.
     
     If ``monitorResults`` is enabled, any changes to those attributes updates the results and calls the results handler.

     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var attributes: [MetadataItem.Attribute] {
        get { MetadataItem.Attribute.values(for: query.valueListAttributes) }
        set {
            runWithOperationQueue {
                self.interceptMDQuery()
                self.query.valueListAttributes = (newValue + .path).flatMap(\.mdKeys).uniqued()
            }
        }
    }

    /**
     The predicate used to filter the query results.
          
     Set this property to define filtering logic for files and directories.
     If the value is `nil`, all items are included in the query results.

     The predicate is expressed by comparing properties of ``MetadataItem`` using operators and helper functions.
     For example:

     ```swift
     // Matches items whose file name starts with "vid", file size is at least 1 GB,
     // and creation date is earlier than `otherDate`.
     query.predicate = {
        $0.fileName.begins(with: "vid") &&
        $0.fileSize.gigabytes >= 1 &&
        $0.creationDate.isBefore(otherDate)
     }
     ```
     
     **For more details about how to construct the predicate and a list of all operators and functions, take a look at ``PredicateItem``.**
     
     If ``monitorResults`` is enabled, the r``esults`` gets updated during the live-update phase when a file starts or stops matching the predicate.
     
     Files that begin to match the predicate are added to ``results``, while files that no longer match are removed.
     
     The ``resultsHandler`` gets called for any changes.
          
     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var predicate: ((PredicateItem) -> (PredicateResult))? {
        didSet {
            runWithOperationQueue {
                self.interceptMDQuery()
                self.query.predicate = self.predicate?(.root).predicate ?? NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey)
                Swift.print(self.predicateFormat)
            }
        }
    }
    
    var predicateFormat: String {
        query.predicate?.predicateFormat ?? ""
    }
    
    /**
     An array of URLs whose metadata attributes are gathered by the query.

     Use this property to scope the metadata query to a collection of existing URLs. The query will gather metadata attributes for these urls.

     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var urls: [URL] {
        get { query.searchItems as? [URL] ?? [] }
        set {
            runWithOperationQueue {
                self.interceptMDQuery()
                self.query.searchItems = newValue.isEmpty ? nil : newValue as [NSURL]
            }
        }
    }

    /**
     An array of file-system directory URLs.

     The query searches for items at these search locations. An empty array indicates that there is no limitation on where the query searches.
     
     The query can alternativly also search at specific scopes via ``searchScopes``.

     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var searchLocations: [URL] {
        get { query.searchScopes.compactMap { $0 as? URL } }
        set {
            runWithOperationQueue {
                self.interceptMDQuery()
                self.query.searchScopes = newValue
            }
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
        set {
            runWithOperationQueue{
                self.interceptMDQuery()
                self.query.searchScopes = newValue.compactMap(\.rawValue)
            }
        }
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
     
     - Note that ``MetadataItem/Attribute/path`` can't be used for sorting.
     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var sortedBy: [SortDescriptor] = [] {
        didSet {
            runWithOperationQueue{
                self.interceptMDQuery()
                self.query.sortDescriptors = self.sortedBy.compactMap({ $0.sortDescriptor })
            }
        }
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
        set {
            runWithOperationQueue{
                self.interceptMDQuery()
                self.query.groupingAttributes = newValue.flatMap(\.mdKeys).uniqued()
            }
        }
    }

    /**
     The queue on which the results gets gathered and the results handler gets called.

     Use this property to decouple the processing of results from the thread used to execute the query. This makes it easier to synchronize query result processing with other related operations—such as updating the data model or user interface—which you might want to perform on the main queue.
     */
    open var operationQueue: OperationQueue? {
        get { query.operationQueue }
        set { runWithOperationQueue{ self.query.operationQueue = newValue } }
    }
    
    /**
     A Boolean value indicating whether the monitoring of changes to the results is enabled.

     Updates are triggered during the live-update phase when a file starts or stops matching the ``predicate-swift.property``, or when a file changes one of it's attributes specified in ``attributes``.

     Files that begin to match the query are added to ``results``, while files that no longer match are removed.
     
     The ``resultsHandler`` gets called for any changes.

     The default value is `false`, which specifies that the ``resultsHandler`` gets called whenever the results changes. The query also monitors for changes to the given ``attributes``.
     
     ``resultsUpdateInterval`` specifies the interval at which results changes are posted.

     In the following example the result handler is called whenever a screenshot is captured or deleted.
     
     ```swift
     query.predicate = { $0.isScreenCapture }
     query.monitorResults = true
     query.resultsHandler = { items, _ in
        // Is called whenever a new screenshot is taken.
     }
     query.start()
     ```
          
     - Note: Enabling monitoring can have a significant performance impact. You should define a operation queue via ``operationQueue`` as otherwise any updates can cause a log on the main thread.
     */
    open var monitorResults = false {
        didSet {
            guard oldValue != monitorResults else { return }
            updateMonitoring()
        }
    }
    
    /**
     The maximum number of results.
     
     The property must be set before the query is executed else the value is ignored.
     */
    open var maxResults: Int?
    
    /**
     The interval (in seconds) at which the results gets updated with accumulated changes.
     
     This value is advisory, in that the update will be triggered at some point after the specified seconds passed since the last update.
     */
    open var resultsUpdateInterval: TimeInterval {
        get { resultsUpdateOptions.gatheringInterval }
        set {
            resultsUpdateOptions.gatheringInterval = newValue
            resultsUpdateOptions.monitoringInterval = newValue
        }
    }
    
    /// The maximum number of changes that can accumulate before updating the results.
    open var resultsUpdateThreshold: Int {
        get { resultsUpdateOptions.gatheringThreshold }
        set {
            resultsUpdateOptions.gatheringThreshold = newValue
            resultsUpdateOptions.monitoringThreshold = newValue
        }
    }
    
    /**
     Options for when the metadata query updates it's results with accumulated changes.
     
     This provides more granular configuration options compared to ``resultsUpdateInterval`` and ``resultsUpdateThreshold``.
     */
    var resultsUpdateOptions = ResultsUpdateOptions() {
        didSet {
            guard oldValue != resultsUpdateOptions, !query.isStopped else { return }
            Self.batchingParameters = resultsUpdateOptions
            Self.options = options
            Self.maxResults = maxResults
            query.notificationBatchingInterval = Double.random(max: 100.0)
        }
    }
    
    /**
     A Boolean value indicating whether the query blocks during the initial gathering phase.
     
     It’s run loop will run in the default mode.
     
     The default value is `false`.
     */
    var isGatheringSynchronous: Bool {
        get { options.contains(.synchronous) }
        set { options[.synchronous] = newValue }
    }
        
    /**
     Execution options for the query.
     
     The default value is `wantsUpdates`.
     */
    var options: Options = [.wantsUpdates]
    
    /**
     A Boolean value indicating whether changes to the results are posted while gathering the inital results.
     
     The default value is `false`.
          
     - Note: Enabling gathering updates can have a significant performance impact. You should define a operation queue via ``operationQueue`` as otherwise any updates can cause a log on the main thread.
     */
    open var postGatheringUpdates: Bool = false

    /// Starts the query and discards the previous results.
    open func start() {
        if state == .isPaused {
            state = pausedState
            query.enableUpdates()
        } else {
            runWithOperationQueue {
                guard self.state == .isStopped else { return }
                Self.batchingParameters = self.resultsUpdateOptions
                Self.options = self.options
                Self.maxResults = self.maxResults
                self.runWithOperationQueue {
                    self.query.enableUpdates()
                    self.query.start()
                }
            }
        }
    }
    
    /// Pauses the query, if it's running.
    open func pause() {
        guard state == .isGathering || state == .isMonitoring else { return }
        query.disableUpdates()
        pausedState = state
        state = .isPaused
    }
    
    /// Stops the query from gathering any further results.
    open func stop() {
        runWithOperationQueue {
            self.itemPathPrefetchOperationQueue.cancelAllOperations()
            self.state = .isStopped
            self.query.stop()
        }
    }

    /**
     An array containing the query’s results.

     The array contains ``MetadataItem`` objects. Accessing the results before a query is finished will momentarly pause the query and provide a snapshot of the current query results.
     */
    open var results: [MetadataItem] {
        if !pendingResultsUpdate.isEmpty {
            updateResults()
        }
        return _results.synchronized
    }
    
    /**
     An array containing hierarchical groups of query results.

     These groups are based on the ``groupingAttributes``.
     */
    open var groupedResults: [ResultGroup] {
        query.groupedResults.compactMap { ResultGroup($0) }
    }
    
    /**
     The hierarchical query results.
     
     The items of the query’s results are mapped hierarchically to their file system path.
     */
    open var hierarchicalResults: HierarchicalResults {
        HierarchicalResults(results)
    }
    
    func updateResults(post: Bool = false) {
        resultsUpdateLock.lock()
        runWithPausedMonitoring {
            let results = (0..<self.query.resultCount).compactMap({ self.query.result(at: $0) as? MetadataItem })
            let pending = self.pendingResultsUpdate
            self.pendingResultsUpdate = .init()
            pending.added.forEach({ self.updateResult($0, isInital: true) })
            pending.changed.forEach({ self.updateResult($0) })
            self._results.synchronized = results
            guard post else { return }
            self.resultsHandler?(results, pending)
        }
        resultsUpdateLock.unlock()
    }
        
    func updateResult(_ result: MetadataItem, isInital: Bool = false) {
        result.previousValues = isInital ? nil : result.values
        result.values = query.values(of: queryAttributes, forResultsAt: query.index(ofResult: result))
        result.filePath = nil
        if prefetchesItemPathsInBackground {
            itemPathPrefetchOperationQueue.addOperation(ItemPathPrefetchOperation(result))
        }
    }
        
    @objc func gatheringStarted(_ notification: Notification) {
        debugPrint("MetadataQuery gatheringStarted")
        _results.removeAll()
        itemPathPrefetchOperationQueue.cancelAllOperations()
        pendingResultsUpdate = .init()
        queryAttributes = (query.valueListAttributes + sortedBy.compactMap(\.attribute.rawValue) + (query.groupingAttributes ?? []) + MetadataItem.Attribute.path.mdKeys).uniqued()
        state = .isGathering
        isFinished = false
        didPostFinished = false
        delayedPostFinishedResults?.cancel()
    }

    @objc func gatheringProgressed(_ notification: Notification) {
        let resultsUpdate = notification.resultsUpdate
        pendingResultsUpdate = pendingResultsUpdate + resultsUpdate
        debugPrint("MetadataQuery gatheringProgressed, results: \(_results.count) \(pendingResultsUpdate._description)")
        (resultsUpdate.added + resultsUpdate.changed).forEach({
            $0.filePath = nil
            $0.filePathOperation?.cancel()
        })
        if prefetchesItemPathsInBackground {
            (resultsUpdate.added + resultsUpdate.changed).forEach({ item in
                let operation = ItemPathPrefetchOperation(item)
                item.filePathOperation = operation
                itemPathPrefetchOperationQueue.addOperation(operation)
            })
        }
        if postGatheringUpdates || isFinished {
            didPostFinished = isFinished
            updateResults(post: true)
        }
    }
            
    @objc func gatheringFinished(_ notification: Notification) {
        debugPrint("MetadataQuery gatheringFinished, results: \(_results.count) \(pendingResultsUpdate._description)")
        isFinished = true
        updateMonitoring()
        if !pendingResultsUpdate.isEmpty || query.resultCount == 0 || (query.resultCount == _results.count && !monitorResults) {
            updateResults(post: true)
        } else if !monitorResults {
            delayedPostFinishedResults = .init { [weak self] in
                guard let self = self, self.isFinished, !self.didPostFinished else { return }
                self.debugPrint("MetadataQuery delayedPostFinishResults")
                self.resultsHandler?(results, .init())
            }.perform(after: 0.1)
        }
    }
    
    @objc func queryUpdated(_ notification: Notification) {
        pendingResultsUpdate = pendingResultsUpdate + notification.resultsUpdate
        debugPrint("MetadataQuery updated, results: \(_results.count) \(pendingResultsUpdate._description)")
        updateResults(post: true)
    }
    
    func updateMonitoring() {
        guard isFinished else { return }
        if monitorResults {
            query.enableUpdates()
            state = .isMonitoring
        } else {
            query.disableUpdates()
            state = .isStopped
        }
    }
    
    func runWithPausedMonitoring(_ block: () -> Void) {
        query.disableUpdates()
        block()
        query.enableUpdates()
    }
    
    func runWithOperationQueue(_ block: @escaping () -> Void) {
        if let operationQueue = operationQueue {
            operationQueue.addOperation {
                self.itemPathPrefetchOperationQueue.cancelAllOperations()
                block()
            }
        } else {
            itemPathPrefetchOperationQueue.cancelAllOperations()
            block()
        }
    }
    
    func debugPrint(_ string: String) {
        guard debug else { return }
        Swift.print(string)
    }
    
    func interceptMDQuery() {
        guard !query.isStopped else { return }
        Self.maxResults = maxResults
        Self.options = options
        Self.batchingParameters = resultsUpdateOptions
    }
        
    /**
     Creates a metadata query with the specified operation queue.
     
     - Parameter queue: The queue on which the results handler gets called.
     */
    public convenience init(queue: OperationQueue) {
        self.init()
        operationQueue = queue
    }

    /// Creates a metadata query.
    override public init() {
        super.init()
        query.delegate = delegate
        query.predicate = NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey)
        query.enableUpdates()

        NotificationCenter.default.addObserver(self, selector: #selector(gatheringStarted(_:)), name: .NSMetadataQueryDidStartGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(gatheringProgressed(_:)), name: .NSMetadataQueryGatheringProgress, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(gatheringFinished(_:)), name: .NSMetadataQueryDidFinishGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryUpdated(_:)), name: .NSMetadataQueryDidUpdate, object: query)
    }
    
    deinit {
        query.stop()
    }
}

extension MetadataQuery {
    class Delegate: NSObject, NSMetadataQueryDelegate {
        func metadataQuery(_ query: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> Any {
            MetadataItem(item: result)
        }
    }
}

extension Notification {
    var resultsUpdate: MetadataQuery.ResultsDifference {
        .init(added: userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [MetadataItem] ?? [], removed: userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [MetadataItem] ?? [], changed: userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [MetadataItem] ?? [])
    }
}

class ItemPathPrefetchOperation: Operation {
    weak var item: MetadataItem?
    
    init(_ item: MetadataItem) {
        self.item = item
    }
    
    override func main() {
       
        guard !isCancelled else { return }
        if let item = item, item.filePath == nil {
            item.filePath = item.value(for: .path)
        }
    }
}

/*
@_cdecl("swizzled_MDQueryCreate")
func swizzled_MDQueryCreate(_ allocator: CFAllocator!, _ queryString: CFString!, _ valueListAttrs: CFArray!, _ sortingAttrs: CFArray!) -> MDQuery! {
    Swift.print("MDQuery")
    return MDQueryCreate(allocator, queryString, valueListAttrs, sortingAttrs)
}
 */


@_cdecl("swizzled_MDQueryExecute")
func swizzled_MDQueryExecute(_ query: MDQuery!,  _ optionFlags: CFOptionFlags
) -> Bool {
    MetadataQuery.query?.mdQuery = query
    MetadataQuery.query = nil
    let optionFlags = MetadataQuery.options?.rawValue ?? optionFlags
    MetadataQuery.options = nil
    if let maxResults = MetadataQuery.maxResults {
        MetadataQuery.maxResults = nil
        MDQuerySetMaxCount(query, CFIndex(maxResults))
    }
    return MDQueryExecute(query, optionFlags)
}

@_cdecl("swizzled_MDQuerySetBatchingParameters")
func swizzled_MDQuerySetBatchingParameters( _ query: MDQuery, _ params: MDQueryBatchingParams) {
    // Swift.print("MDQuerySetBatchingParameters")
    var params = params
    if let batching = MetadataQuery.batchingParameters {
        params.first_max_num = batching.initialThreshold
        params.first_max_ms = Int((batching.initialDelay * 1000).rounded())
        params.progress_max_num = batching.gatheringThreshold
        params.progress_max_ms = Int((batching.gatheringInterval * 1000).rounded())
        params.update_max_num = batching.monitoringThreshold
        params.update_max_ms = Int((batching.monitoringInterval * 1000).rounded())
        MetadataQuery.batchingParameters = nil
    }
    MDQuerySetBatchingParameters(query, params)
}
