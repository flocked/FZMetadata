//
//  MetadataQuery.swift
//
//
//  Created by Florian Zand on 23.08.22.
//

import Foundation
import FZSwiftUtils
#if os(macOS)
import _MDQueryInterposer
#endif
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
 
 The handler is called when all matching files are found. By enabling ``postsGatheringUpdates``
 
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

    let query = NSMetadataQuery()
    let delegate = Delegate()
    var _results: SynchronizedArray<MetadataItem> = []
    var pendingResultsUpdate = ResultDifference()
    var queryAttributes: [String] = []
    var resultCount: Int = 0
    var didFinishGathering = false
    var didPostFinished = false
    var prefetchesItemPathsInBackground = true
    let itemPathPrefetchOperationQueue = OperationQueue(maxConcurrentOperationCount: 80)
    var resultsUpdateLock = NSLock()
    var debug = false
    
    /// The state of the query.
    @objc dynamic open internal(set) var state: State = .isStopped
    
    /// The handler that gets called when the results changes with the metadata items of the results and the difference to the previous results.
    open var resultsHandler: ((_ items: [MetadataItem], _ difference: ResultDifference) -> Void)? = nil
    
    /**
     An array of metadata attributes whose values are gathered by the query.
     
     If ``monitorResults`` is enabled, any changes to those attributes updates the results and calls the results handler.
     
     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var attributes: [MetadataItem.Attribute] {
        get { MetadataItem.Attribute.values(for: query.valueListAttributes) }
        set {
            runWithOperationQueue {
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
                self.query.predicate = self.predicate?(.root).predicate ?? NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey)
            }
        }
    }
    
    public var predicateFormat: String {
        query.predicate?.predicateFormat ?? NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey).predicateFormat
    }
    
    /**
     An array of URLs to use for the predicate.
     
     Use this property to scope the metadata query to a collection of existing URLs. The query will gather metadata attributes for these urls.
     
     Alternative use ``searchScopes`` or ``searchLocations`` tp scope the query to collect URLs at the specific locations.
     
     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var urls: [URL] {
        get { query.searchItems as? [URL] ?? [] }
        set {
            runWithOperationQueue {
                self.query.searchItems = newValue.isEmpty ? nil : newValue as [NSURL]
            }
        }
    }
    
    /**
     An array of file-system directory URLs to search at.
     
     The query searches for items at these search locations. An empty array indicates that there is no limitation on where the query searches.
     
     The query can alternativly also search at specific scopes via ``searchScopes``.
     
     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var searchLocations: [URL] {
        get { query.searchScopes.compactMap { $0 as? URL } }
        set {
            runWithOperationQueue {
                self.query.searchScopes = newValue.uniqued()
            }
        }
    }
    
    /**
     An array of search scopes to search at.
     
     The query searches for items at the search scopes. The default value is an empty array which indicates that there is no limitation on where the query searches.
     
     The query can alternativly also search at specific file-system directories via ``searchLocations``.
     
     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var searchScopes: [SearchScope] {
        get { query.searchScopes.compactMap { $0 as? String }.compactMap { SearchScope(rawValue: $0) } }
        set {
            runWithOperationQueue {
                self.query.searchScopes = newValue.compactMap(\.rawValue).uniqued()
            }
        }
    }
    
    /**
     The sort descriptors for sorting the query results.
     
     Example usage:
     
     ```swift
     query.sortedBy = [.fileSize, .creationDate.descending]
     ```
     
     The results can also be sorted by item relevance via ``MetadataQuery/SortDescriptor/queryContentRelevance``:
     
     ```swift
     query.sortedBy = [.queryRelevance]
     ```
     
     - Note that ``MetadataItem/Attribute/path`` can't be used for sorting.
     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var sortedBy: [SortDescriptor] = [] {
        didSet {
            sortedBy = sortedBy.uniqued(by: \.attribute)
            runWithOperationQueue {
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
            runWithOperationQueue {
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
        set { runWithOperationQueue(false) { self.query.operationQueue = newValue } }
    }
    
    /**
     A Boolean value indicating whether the monitoring of changes to the results is enabled.
               
     If set to `true`, updates are triggered after gathering the initial results, when…
     - …an item starts or stops matching the ``predicate``
     - …an item changes of it's attributes specified in ``attributes``, ``groupingAttributes`` or ``sortedBy``.
          
     Items that begin to match the query are added to ``results``, while items that no longer match are removed.
     
     The ``resultsHandler`` gets called for any changes.
     
     The default value is `false`,
          
     In the following example the result handler is called whenever a screenshot is captured or deleted.
     
     ```swift
     query.predicate = { $0.isScreenCapture }
     query.monitorResults = true
     query.resultsHandler = { items, _ in
     // Is called whenever a new screenshot is taken.
     }
     query.start()
     ```
     */
    open var monitorResults = false {
        didSet {
            guard oldValue != monitorResults else { return }
            updateMonitoring()
        }
    }
    
    #if os(macOS)
    /**
     The maximum number of results.
     
     The property must be set before the query is started else the value is ignored.
     */
    open var maxResults: Int?
    
    static var maxResults: Int?

    /**
     The interval (in seconds) at which the results gets updated with accumulated changes.
     
     This value is advisory, in that the update will be triggered at some point after the specified seconds passed since the last update.
     */
    open var resultUpdateInterval: TimeInterval {
        get { resultUpdateOptions.gatheringInterval }
        set {
            resultUpdateOptions.gatheringInterval = newValue
            resultUpdateOptions.monitoringInterval = newValue
        }
    }
    
    /// The maximum number of changes that can accumulate before updating the results.
    open var resultUpdateThreshold: Int {
        get { resultUpdateOptions.gatheringThreshold }
        set {
            resultUpdateOptions.gatheringThreshold = newValue
            resultUpdateOptions.monitoringThreshold = newValue
        }
    }
    
    /**
     Options for when the metadata query updates it's results with accumulated changes.
     
     This provides more granular configuration options compared to ``resultUpdateInterval`` and ``resultUpdateThreshold``.
     */
    var resultUpdateOptions = ResultUpdateOptions() {
        didSet {
            guard oldValue != resultUpdateOptions, !query.isStopped else { return }
            Self.resultUpdateOptions = resultUpdateOptions
            query.notificationBatchingInterval = Double.random(max: 100.0)
        }
    }
    
    static var resultUpdateOptions: ResultUpdateOptions?
    
    /**
     A Boolean value indicating whether the query blocks during the initial gathering phase.
     
     It’s run loop will run in the default mode.
     
     The default value is `false`.
     */
    public var isSynchronous: Bool {
        get { options.contains(.synchronous) }
        set { options[.synchronous] = newValue }
    }
    
    /**
     Execution options for the query.
     
     The default value is `wantsUpdates`.
     */
    var options: Options = [.wantsUpdates]
    
    static var options: Options?
    #else
    /**
     The interval (in seconds) at which the results gets updated with accumulated changes.
     
     This value is advisory, in that the update will be triggered at some point after the specified seconds passed since the last update.
     */
    open var resultUpdateInterval: TimeInterval {
        get { query.notificationBatchingInterval }
        set { query.notificationBatchingInterval = newValue }
    }
    #endif
    
    /**
     A Boolean value indicating whether changes to the results are posted while gathering the initial results.
     
     The default value is `false`.
     
     - Note: Enabling gathering updates can have a significant performance impact. You should define an operation queue via ``operationQueue`` as otherwise any updates can cause lag on the main thread.
     */
    open var postsGatheringUpdates: Bool = false
    
    /// Starts the query, discarding any previous results, or resumes a paused query.
    open func start() {
        switch state {
        case .isStopped:
            runWithOperationQueue(true) {
                self.query.enableUpdates()
                self.query.start()
            }
        case .isPaused:
            state = didFinishGathering ? .isMonitoring : .isGathering
            query.enableUpdates()
        default: break
        }
    }
    
    /// Pauses a running query.
    open func pause() {
        guard state == .isGathering || state == .isMonitoring else { return }
        query.disableUpdates()
        state = .isPaused
    }
    
    /**
     Stops the query from gathering any further results.
     
     Once the query is stopped, the query can't monitor and update the results for changes. Calling ``start()`` will discard the current results and start a new query.
     */
    open func stop() {
        runWithOperationQueue(false) {
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
     The hierarchical query result.
     
     The items of the query’s results are mapped hierarchically to their file system path.
     */
    open var hierarchicalResult: HierarchicalResult {
        HierarchicalResult(results)
    }
    
    func updateResults(post: Bool = false) {
        resultsUpdateLock.lock()
        query.disableUpdates()
        let results = (0..<query.resultCount).compactMap({ query.result(at: $0) as? MetadataItem })
        resultCount = query.resultCount
        var pending = pendingResultsUpdate
        pendingResultsUpdate = .init()
        pending.added.forEach({ updateResult($0, isInital: true) })
        pending.changed.forEach({ updateResult($0) })
        if !pending.isEmpty {
          //  willChangeValue(for: \.results)
            _results.synchronized = results
          //  didChangeValue(for: \.results)
        }
        query.enableUpdates()
        resultsUpdateLock.unlock()
        if post, let resultsHandler = resultsHandler {
            pending.changes = .init(pending.changed)
            resultsHandler(results, pending)
        }
    }
    
    func updateResult(_ result: MetadataItem, isInital: Bool = false) {
        let index = query.index(ofResult: result)
        guard index < resultCount else { return }
        result.values = query.values(of: queryAttributes, forResultsAt: index)
        if !isInital {
            result.changes.update(with: result.values)
        }
        prefetchItemPath(for: result)
    }
    
    func prefetchItemPath(for item: MetadataItem) {
        item.filePath = nil
        item.filePathOperation?.cancel()
        guard prefetchesItemPathsInBackground else { return }
        let operation = ItemPathPrefetchOperation(item)
        item.filePathOperation = operation
        itemPathPrefetchOperationQueue.addOperation(operation)
    }
    
    @objc func gatheringStarted(_ notification: Notification) {
        debugPrint("MetadataQuery gatheringStarted")
      //  willChangeValue(for: \.results)
        _results.removeAll()
     //   didChangeValue(for: \.results)
        itemPathPrefetchOperationQueue.cancelAllOperations()
        pendingResultsUpdate = .init()
        queryAttributes = (query.valueListAttributes + sortedBy.compactMap(\.attribute.rawValue) + (query.groupingAttributes ?? []) + MetadataItem.Attribute.path.mdKeys).uniqued()
        state = .isGathering
        didFinishGathering = false
        didPostFinished = false
    }

    @objc func gatheringProgressed(_ notification: Notification) {
        let resultsUpdate = notification.resultsUpdate
        pendingResultsUpdate = pendingResultsUpdate + resultsUpdate
        debugPrint("MetadataQuery gatheringProgressed, results: \(_results.count) \(pendingResultsUpdate._description)")
        if postsGatheringUpdates || didFinishGathering {
            didPostFinished = didFinishGathering
            updateResults(post: true)
        } else {
            (resultsUpdate.added + resultsUpdate.changed).forEach({ item in
                prefetchItemPath(for: item)
            })
        }
    }
            
    @objc func gatheringFinished(_ notification: Notification) {
        debugPrint("MetadataQuery gatheringFinished, results: \(_results.count) \(pendingResultsUpdate._description)")
        didFinishGathering = true
        updateMonitoring()
        if !pendingResultsUpdate.isEmpty || query.resultCount == 0 || (query.resultCount == _results.count && !monitorResults) {
            updateResults(post: true)
        } else if !monitorResults {
            DispatchQueue.main.asyncAfter(0.1) {
                guard self.didFinishGathering, !self.didPostFinished else { return }
                self.debugPrint("MetadataQuery delayedPostFinishResults")
                self.resultsHandler?(self.results, .init())
            }
        }
    }
    
    @objc func queryUpdated(_ notification: Notification) {
        pendingResultsUpdate = pendingResultsUpdate + notification.resultsUpdate
        debugPrint("MetadataQuery updated, results: \(_results.count) \(pendingResultsUpdate._description)")
        updateResults(post: true)
    }
    
    func updateMonitoring() {
        guard didFinishGathering else { return }
        if monitorResults {
            query.enableUpdates()
            state = .isMonitoring
        } else {
            query.disableUpdates()
            state = .isPaused
        }
    }
    
    func runWithOperationQueue(_ intercept: Bool? = nil, _ block: @escaping () -> Void) {
        if let operationQueue = operationQueue {
            operationQueue.addOperation { [weak self] in
                self?.run(intercept, block)
            }
        } else {
            run(intercept, block)
        }
    }
    
    func run(_ intercept: Bool? = nil, _ block: @escaping () -> Void) {
        itemPathPrefetchOperationQueue.cancelAllOperations()
        #if os(macOS)
        if intercept ?? !query.isStopped {
            Self.maxResults = maxResults
            Self.options = options
            Self.resultUpdateOptions = resultUpdateOptions
        }
        #endif
        block()
    }
    func debugPrint(_ string: String) {
        guard debug else { return }
        Swift.print(string)
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
        predicate = { $0.contentType == .item }

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

#if os(macOS)
@_cdecl("swizzled_MDQueryExecute")
func swizzled_MDQueryExecute(_ query: MDQuery!,  _ optionFlags: CFOptionFlags
) -> Bool {
    let optionFlags = MetadataQuery.options?.rawValue ?? optionFlags
    MetadataQuery.options = nil
    if let maxResults = MetadataQuery.maxResults {
        MetadataQuery.maxResults = nil
        MDQuerySetMaxCount(query, CFIndex(maxResults))
    }
    return MDQueryExecute(query, optionFlags)
}

@_cdecl("swizzled_MDQuerySetBatchingParameters")
public func swizzled_MDQuerySetBatchingParameters( _ query: MDQuery, _ params: MDQueryBatchingParams) {
    let params = MetadataQuery.resultUpdateOptions?.batching ?? params
    MetadataQuery.resultUpdateOptions = nil
    MDQuerySetBatchingParameters(query, params)
}
#endif

/*
@_cdecl("swizzled_MDQueryCreate")
func swizzled_MDQueryCreate(_ allocator: CFAllocator!, _ queryString: CFString!, _ valueListAttrs: CFArray!, _ sortingAttrs: CFArray!) -> MDQuery! {
    Swift.print("MDQuery")
    return MDQueryCreate(allocator, queryString, valueListAttrs, sortingAttrs)
}
*/
