//
//  MetadataQuery.swift
//
//
//  Created by Florian Zand on 23.08.22.
//

import Foundation
import FZSwiftUtils

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
    public enum State: Int {
        /// The query is in it's initial phase of gathering all matching items.
        case isGatheringItems
        /// The query is monitoring for updates to the results.
        case isMonitoring
        /// The query is stopped.
        case isStopped
    }

    public let query = NSMetadataQuery()
    let delegate = Delegate()
    var _results: SynchronizedArray<MetadataItem> = []
    var pendingResultsUpdate = ResultsUpdate()
    var queryAttributes: [String] = []
    var isFinished: Bool = false
    var didPostFinishResults: Bool = false
    var delayedFinishResults: DispatchWorkItem?
    var debug = true

    struct ResultsUpdate: Hashable, CustomStringConvertible {
        var added: [MetadataItem] = []
        var removed: [MetadataItem] = []
        var changed: [MetadataItem] = []
        var isEmpty: Bool { self == ResultsUpdate() }
        static func += (lhs: inout Self, rhs: Self) {
            lhs.added += rhs.added
            lhs.removed += rhs.removed
            lhs.changed += rhs.changed
        }
        
        var description: String {
            var strings: [String] = []
            if !added.isEmpty { strings.append("added: \(added.count)")}
            if !removed.isEmpty { strings.append("removed: \(removed.count)")}
            if !changed.isEmpty { strings.append("changed: \(changed.count)")}
            return strings.joined(separator: ", ")
        }
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
     
     If ``monitorResults`` is enabled, any changes to conforming items updates the results and calls the results handler.
     
     - Note: Setting this property while a query is running stops the query, discards the current results and immediately starts a new query.
     */
    open var predicate: ((Predicate<MetadataItem>) -> (Predicate<Bool>))? {
        didSet {
            query.predicate = predicate?(.init()).predicate ?? NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey)
        }
    }
    
    /// The predicate format string.
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
     Note that ``MetadataItem/Attribute/path`` can't be used for sorting.
     
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
     The queue on which the results gets gathered and the results handler gets called.

     Use this property to decouple the processing of results from the thread used to execute the query. This makes it easier to synchronize query result processing with other related operations—such as updating the data model or user interface—which you might want to perform on the main queue.
     */
    open var operationQueue: OperationQueue? {
        get { query.operationQueue }
        set { query.operationQueue = newValue }
    }
    
    /**
     A Boolean value indicating whether the monitoring of changes to the results is enabled.

     The default value is `true`, which specifies that the ``resultsHandler`` gets called whenever the results changes. The query also monitors for changes to the given ``attributes``.
     
     ``updateNotificationInterval`` specifies the interval at which results changes are posted.

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
    
    
    /// The interval (in seconds) at which notifications of updated results occur. The default value is `1.0` seconds.
    open var updateNotificationInterval: TimeInterval {
        get { query.notificationBatchingInterval }
        set { query.notificationBatchingInterval = newValue }
    }
    
    /**
     A Boolean value indicating whether changes to the results are posted while gathering the inital results. The default value is `false`.
          
     - Note: Enabling gathering updates can have a significant performance impact. You should define a operation queue via ``operationQueue`` as otherwise any updates can cause a log on the main thread.
     */
    open var postGatheringUpdates: Bool = false

    /// Starts the query and discards the previous results.
    open func start() {
        guard state == .isStopped else { return }
        runWithOperationQueue {
            self.query.enableUpdates()
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
    
    let fetchPathOperationQueue = OperationQueue(maxConcurrentOperationCount: 40)
    public var fetchCount = 0
    func updateResults(postUpdate: Bool = false) {
        MeasureTime.printTimeElapsed(title: "_updateResults") {
            runWithPausedMonitoring {
                let results = (0..<query.resultCount).compactMap({ query.result(at: $0) as? MetadataItem })
                var added = pendingResultsUpdate.added, changed = pendingResultsUpdate.changed, removed = pendingResultsUpdate.removed
                pendingResultsUpdate = .init()
                added.forEach({ 
                    updateResult($0, inital: true)
                    let operation = FetchPathOperation($0).completion { [weak self] in
                        guard let self = self else { return }
                        self.fetchCount += 1
                    }
                    fetchPathOperationQueue.addOperation(FetchPathOperation($0))
                })
                changed.forEach({ updateResult($0, inital: false) })
                /*
                MeasureTime.printTimeElapsed(title: "Update Paths") {
                    added.forEach({ updatePath($0) })
                    changed.forEach({ updatePath($0) })
                }
                 */
                
                _results.synchronized = results
                guard postUpdate else { return }
                resultsHandler?(results, ResultsDifference(added: added, removed: removed, changed: changed))
            }
        }
    }
        
    func updateResult(_ result: MetadataItem, inital: Bool) {
        result.previousValues = inital ? nil : result.values
        result.values = query.values(of: queryAttributes, forResultsAt: query.index(ofResult: result))
        // guard result.values[MetadataItem.Attribute.path.rawValue] == nil else { return }
        // result.values[MetadataItem.Attribute.path.rawValue] = result.path
    }
    
    func updatePath(_ result: MetadataItem) {
        guard result.values[MetadataItem.Attribute.path.rawValue] == nil else { return }
        result.values[MetadataItem.Attribute.path.rawValue] = result.path
    }
        
    @objc func gatheringStarted(_ notification: Notification) {
        debugPrint("MetadataQuery gatheringStarted")
        _results.removeAll()
        fetchCount = 0
        fetchPathOperationQueue.cancelAllOperations()
        pendingResultsUpdate = .init()
        queryAttributes = (query.valueListAttributes + sortedBy.compactMap(\.key) + (query.groupingAttributes ?? []) + MetadataItem.Attribute.path.mdKeys).uniqued()
        state = .isGatheringItems
        isFinished = false
        didPostFinishResults = false
        delayedFinishResults?.cancel()
    }

    @objc func gatheringProgressed(_ notification: Notification) {
        debugPrint("MetadataQuery gatheringProgressed, added: \(notification.added.count), removed: \(notification.removed.count), changed: \(notification.changed.count), _results: \(_results.count), postGathering: \(postGatheringUpdates), isFinished: \(isFinished), didPostFinish: \(didPostFinishResults)")
        pendingResultsUpdate += notification.resultsUpdate
        
        if isFinished && !didPostFinishResults {
            delayedFinishResults?.cancel()
            didPostFinishResults = true
            updateResults(postUpdate: true)
        } else if postGatheringUpdates {
            updateResults(postUpdate: true)
        }
    }
            
    @objc func gatheringFinished(_ notification: Notification) {
        Swift.debugPrint("MetadataQuery gatheringFinished, results: \(query.resultCount), monitors: \(monitorResults)", "current", _results.count, "pending", !pendingResultsUpdate.isEmpty)
        isFinished = true
        updateMonitoring()
        if !pendingResultsUpdate.isEmpty {
            self.updateResults(postUpdate: true)
        } else if results.count != query.resultCount {
            delayedFinishResults = .init { [weak self] in
                guard let self = self else { return }
                if !self.didPostFinishResults {
                    self.didPostFinishResults = true
                    if self.query.resultCount > self._results.count {
                        self.pendingResultsUpdate.added += (self._results.count..<self.query.resultCount).compactMap({ self.query.result(at: $0) as? MetadataItem })
                    }
                    self.updateResults(postUpdate: true)
                }
            }.perform(after: 0.2)
        }
    }

    @objc func queryUpdated(_ notification: Notification) {
        debugPrint("MetadataQuery updated, added: \(notification.added.count), removed: \(notification.removed.count), changed: \(notification.changed.count), _results: \(_results.count)")
        pendingResultsUpdate += notification.resultsUpdate
        updateResults(postUpdate: true)
    }
    
    func runWithPausedMonitoring(_ block: () -> Void) {
        query.disableUpdates()
        block()
        query.enableUpdates()
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
        query.predicate = NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey)
        query.enableUpdates()

        NotificationCenter.default.addObserver(self, selector: #selector(gatheringStarted(_:)), name: .NSMetadataQueryDidStartGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(gatheringProgressed(_:)), name: .NSMetadataQueryGatheringProgress, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(gatheringFinished(_:)), name: .NSMetadataQueryDidFinishGathering, object: query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryUpdated(_:)), name: .NSMetadataQueryDidUpdate, object: query)
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
    var added: [MetadataItem] { userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [MetadataItem] ?? [] }
    var removed: [MetadataItem] { userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [MetadataItem] ?? [] }
    var changed: [MetadataItem] { userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [MetadataItem] ?? [] }
    var resultsUpdate: MetadataQuery.ResultsUpdate {
        MetadataQuery.ResultsUpdate(added: added, removed: removed, changed: changed)
    }
}

#if os(macOS)
import AppKit
/// Not working
extension MetadataQuery {
    /// Displays a Spotlight search results window in Finder for the ``predicate-swift.property``.
    func showSearchResultsInFinder() {
        if let format = query.predicate?.predicateFormat {
            NSWorkspace.shared.showSearchResults(forQueryString: format)
        }
    }
}
#endif

class FetchPathOperation: AsyncOperation {
    let item: MetadataItem
    
    init(_ item: MetadataItem) {
        self.item = item
    }
    
    override func start() {
        guard self.isCancelled == false || self.isExecuting == false else { return }
        state = .executing
        if item.values[MetadataItem.Attribute.path.rawValue] == nil {
            item.values[MetadataItem.Attribute.path.rawValue] = item.path
        }
        finish()
    }
}

extension NSMetadataItem {
    var path: String? {
        guard let string = (value(forKey: "_item") as? NSObject)?.debugDescription else { return nil }
        let value = string.components(separatedBy: "path = '").last?.components(separatedBy: "']").first
        return value
    }
}
