//
//  MetadataQuery.swift
//  
//
//  Created by Florian Zand on 23.08.22.
//

import Foundation

/**
 An object that can search files and fetch metadata attributes for large batches of files.
   
 With `MetadataQuery`, you can perform complex queries on the file system using various search parameters, such as search loction and metadata attributes like file name, type, creation date, modification date, and more.
 
 ```swift
 query.searchLocations = [.downloadsDirectory, .documentsDirectory]
 query.predicate = {
     $0.fileTypes(.image, .video) &&
     $0.dateAdded.isThisWeek &&
     $0.fileSize.megabytes >= 10
 } // Image & videos files, added this week, large than 10mb
 query.resultsHandler = { files, _ in
 // found files
 }
 query.start()
 ```
 
 It can also fetch metadata attributes for large batches of file URLs.
 ```swift
 query.urls = videoFileURLs  // URLs for querying of attributes
 query.attributes = [.pixelSize, .duration, .fileSize, .creationDate] // Attributes to query
 query.resultsHandler = { files in
     for file in files {
     // file.pixelSize, file.duration, file.fileSize, file.creationDate
     }
 }
 query.start()
 ```
 
 It can also monitor for changes via ``enableMonitoring()``.  The query calls your results handler, whenever new files match the query or file attributes change.
 
 ```swift
 query.predicate = { $0.isScreenCapture } // Screenshots files
 query.enableMonitoring()
 query.resultsHandler = { files, _ in
 // the results handler gets called whenever new screenshots are taken.
 }
 query.start()
 ```
 
 Using the query to search files and to fetch metadata attributes is much faster compared to manually search them e.g. via `FileMananger or `NSMetadataItem`.
 */
public class MetadataQuery: NSObject, NSMetadataQueryDelegate {
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
    
    /// The handler that gets called when the results changes.
    public var resultsHandler: ResultsHandler? = nil
    
    /// A handler that gets called when the results changes with the items of the results and the difference compared to the previous results.
    public typealias ResultsHandler = ((_ items: [MetadataItem], _ difference: ResultsDifference)->())
    
    /// The handler that gets called when the state changes.
    public var stateHandler: ((_ state: State)->())? = nil

    var isRunning: Bool { return self.query.isStarted }
    var isGathering: Bool { return self.query.isGathering }
    var isStopped: Bool { return self.query.isStopped }
   // var isMonitoring: Bool { return self.query.isStopped == false && self.query.isGathering == false  }
    
    /// The state of the query.
    public var state: State {
        guard self.isStopped == false else { return .isStopped }
        return (self.isGathering == true) ? .isGatheringFiles : .isMonitoring
    }
    /**
     An array of URLs whose metadata attributes are gathered by the query.
     
     Use this property to scope the metadata query to a collection of existing URLs. The query will gather metadata attributes for these urls.
     
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    public var urls: [URL] {
        get { (self.query.searchItems as? [URL]) ?? [] }
        set { query.searchItems = newValue.isEmpty ? nil : (newValue as [NSURL]) } }
    
    /**
     An array of metadata attributes whose values are fetched by the query.
          
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    public var attributes: [MetadataItem.Attribute] {
        get { return MetadataItem.Attribute.values(for: query.valueListAttributes) }
        set { let newValue:  [MetadataItem.Attribute] = [.path] + newValue
            query.valueListAttributes = newValue.flatMap({$0.mdKeys}).uniqued() }
    }
    
    /**
     An array of attributes for grouping the result.
     
     The grouped results can be accessed via ``groupedResults``.
          
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    public var groupingAttributes: [MetadataItem.Attribute] {
        get { query.groupingAttributes?.compactMap({MetadataItem.Attribute(rawValue: $0)}) ?? [] }
        set {
            let newValue = newValue.flatMap({$0.mdKeys}).uniqued()
            query.groupingAttributes = newValue.isEmpty ? nil : newValue
        }
    }
    
    /**
     The predicate used to filter query results.
               
     Predicates can be defined by comparing ``MetadataItem`` properties to values using operators and functions. For example:
     
     ```swift
     // fileName begins with "vid",fileSize is larger or equal 1gb and creationDate is before otherDate.
     query.predicate = {
        $0.fileName.begins(with: "vid") &&
        $0.fileSize.gigabytes >= 1 &&
        $0.creationDate.isBefore(otherDate)
     }
     ```
     
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.

     **For more details about how to construct a predicate and a list of all operators and functions, take a look at ``Predicate-swift.struct``.**
     */
    public var predicate: ((Predicate<MetadataItem>)->(Predicate<Bool>))? {
        didSet {
            self.query.predicate = predicate?(.root).predicate ?? NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey)
        }
    }
        
    /**
     An array of file-system directory URLs.
     
     The query searches for files at these search locations. An empty array indicates that there is no limitation on where the query searches.
     
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     
     The query can alternativly search globally or at specific scopes via ``searchScopes``.
     */
    public var searchLocations: [URL] {
        get { self.query.searchScopes.compactMap({$0 as? URL}) }
        set { self.query.searchScopes = newValue }
    }
                
    /**
     An array containing the seatch scopes.
     
     The query searches for files at the search scropes. An empty array indicates that the query searches globally.
     
     The query can alternativly also search at specific file-system directories via ``searchLocations``. In this case it will also return an empty array.

     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    public var searchScopes: [SearchScope] {
        get { self.query.searchScopes.compactMap({$0 as? String}).compactMap({SearchScope(rawValue: $0)}) }
        set {  self.query.searchScopes = newValue.compactMap({$0.rawValue}) }
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
    public var sortedBy: [SortDescriptor]  {
        set { self.query.sortDescriptors = newValue }
        get { self.query.sortDescriptors.compactMap({$0 as? SortDescriptor}) }
    }
    
    /// The interval (in seconds) at which notification of updated results occurs. The default value is 1.0 seconds.
    public var updateNotificationInterval: TimeInterval {
        get { self.query.notificationBatchingInterval }
        set { self.query.notificationBatchingInterval = newValue } }
    
    /**
     The queue on whicht results handler gets called.
     
     Use this property to decouple the processing of results from the thread used to execute the query. This makes it easier to synchronize query result processing with other related operations—such as updating the data model or user interface—which you might want to perform on the main queue.
     */
    public var operationQueue: OperationQueue? {
        get { self.query.operationQueue }
        set { self.query.operationQueue = newValue } }
    
    /// Starts the query, if it isn't running and resets the current result.
    public func start()  {
        func startQuery() {
            if self.query.start() == true {
                self.resetResults()
            }
        }
        
        if let operationQueue = self.operationQueue {
            operationQueue.addOperation{
                startQuery()
            }
        } else {
            startQuery()
        }
    }
    
    /// Stops the  current query from gathering any further results.
    public func stop() {
        if (self.isStopped == false) {
            self.stateHandler?(.isStopped)
        }
        query.stop()
    }
    
    func reset() {
        self.resultsHandler = nil
        self.searchScopes = []
        self.urls = []
        self.predicate = nil
        self.attributes = []
        self.groupingAttributes = []
        self.sortedBy = []
    }
    
    func runWithPausedMonitoring(_ block: ()->()) {
        let _isMonitoring = isMonitoring
        isMonitoring = false
        block()
        if (_isMonitoring == true) {
            isMonitoring = true
        }
    }
    
    /**
     An array containing the query’s results.
     
     The array contains ``MetadataItem`` objects. Accessing the result before a query is finished will momentarly pause the query and provide  a snapshot of the current query results.
     */
    public var results: [MetadataItem] {
        self.updateResults()
        return self._results
    }
    
    var resultsCount: Int {
        query.resultCount
    }
    
    var _results: [MetadataItem] = []
    func updateResults() {
        _results = self.results(at: Array(0..<self.query.resultCount))
    }
    
    func resetResults() {
        _results.removeAll()
    }
    
    func results(at indexes: [Int]) -> [MetadataItem] {
        return indexes.compactMap({self.result(at: $0)})
    }
    
    func result(at index: Int) -> MetadataItem? {
        let result = self.query.result(at: index) as? MetadataItem
    //    values["kMDItemPath"] = result?.path
        result?.values = resultAttributeValues(at: index)
        return result
    }
    
    func resultAttributeValues(at index: Int) -> [String: Any] {
        return self.query.values(of: allAttributeKeys, forResultsAt: index)
    }
    
    var allAttributeKeys: [String] {
        var attributes = self.query.valueListAttributes
        attributes = attributes + self.sortedBy.compactMap({$0.key})
        attributes = attributes + self.groupingAttributes.compactMap({$0.rawValue}) + ["kMDQueryResultContentRelevance"]
        return attributes.uniqued()
    }
    
    var predicateAttributes: [MetadataItem.Attribute] {
        predicate?(.root).attributes ?? []
    }
    
    var sortingAttributes: [MetadataItem.Attribute] {
        self.sortedBy.compactMap({MetadataItem.Attribute(rawValue: $0.key ?? "_")})
    }
    
    /**
     An array containing hierarchical groups of query results.
     
     These groups are based on the ``groupingAttributes``.
     */
    public var groupedResults: [ResultGroup] {
        return self.query.groupedResults.compactMap({ResultGroup(nsResultGroup: $0)})
    }
    
    /**
     Enables the monitoring of changes to the result.
     
     By default, notification of updated results occurs at 1.0 seconds. Use ``updateNotificationInterval`` to change the internval.
     */
    public func enableMonitoring() {
        self.query.enableUpdates()
        self.isMonitoring = true
    }
    
    /// Disables the monitoring of changes to the result.
    public func disableMonitoring() {
        self.query.disableUpdates()
        self.isMonitoring = false
    }
    
    /**
     A Boolean value indicating whether the monitoring of changes to the result is enabled.
     
     If `true` the ``resultsHandler-swift.property`` gets called whenever the results changes.
     
     By default, notification of updated results occurs at 1.0 seconds. Use ``updateNotificationInterval`` to change the internval.
     */
    var isMonitoring = false {
        didSet {
            guard oldValue != isMonitoring else { return }
            if isMonitoring {
                query.enableUpdates()
            } else {
                query.disableUpdates()
            }
        }
    }
    
    @objc func queryGatheringDidStart(_ notification: Notification) {
        Swift.debugPrint("MetadataQuery gatheringDidStart")
        self.resetResults()
        self.stateHandler?(.isGatheringFiles)
    }
    
    @objc func queryGatheringFinished(_ notification: Notification) {
        Swift.debugPrint("MetadataQuery gatheringFinished")
        self.runWithPausedMonitoring {
            let results = self.results
            let diff = ResultsDifference.added(_results)
            postResults(results, difference: diff)
        }
        
        if isMonitoring {
            self.stateHandler?(.isMonitoring)
        } else {
            stop()
        }
    }
    
    @objc func queryGatheringProgress(_ notification: Notification) {
        Swift.debugPrint("MetadataQuery gatheringProgress")
    }
    
    @objc func queryUpdated(_ notification: Notification) {
        Swift.debugPrint("MetadataQuery updated")
        self.runWithPausedMonitoring {
            let added: [MetadataItem] =  (notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [MetadataItem]) ?? []
            let removed: [MetadataItem] =  (notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [MetadataItem]) ?? []
            let changed: [MetadataItem] = (notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [MetadataItem]) ?? []
            
            guard !added.isEmpty || !removed.isEmpty || !changed.isEmpty else { return }
            
            _results.remove(removed)
            _results = _results + added
            if (changed.isEmpty == false) {
                (changed + added).forEach({ _results.move($0, to: self.query.index(ofResult: $0) + 1) })
            }
            let diff = ResultsDifference(added: added, removed: removed, changed: changed)
            postResults(_results, difference: diff)
        }
    }
    
    func postResults(_ items: [MetadataItem], difference: ResultsDifference) {
        if let operationQueue = operationQueue {
            operationQueue.addOperation{
                self.resultsHandler?(items, difference)
            }
        } else {
            self.resultsHandler?(items, difference)
        }
    }
     
    func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringDidStart(_:)), name: .NSMetadataQueryDidStartGathering , object: self.query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringFinished(_:)), name: .NSMetadataQueryDidFinishGathering , object: self.query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryUpdated(_:)), name: .NSMetadataQueryDidUpdate, object: self.query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringProgress(_:)), name: .NSMetadataQueryGatheringProgress, object: self.query)
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func metadataQuery(_ query: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> Any {
        return MetadataItem(item: result)
    }
        
    public override init() {
        super.init()
        self.reset()
        self.addObserver()
        self.query.delegate = self
    }
}

/*
public extension MetadataQuery {
    /// Returns a string for a case sensitive predicate.
    func c(_ input: String) -> String {
        return "$[c]\(input)"
    }
    
    /// Returns an array of strings for a case sensitive predicate.
    func c<S: Sequence<String>>(_ input: S) -> [String] {
        return input.compactMap({c($0)})
    }
    
    /// Returns a string for a diacritic sensitive predicate.
    func d(_ input: String) -> String {
        return "$[d]\(input)"
    }
    
    /// Returns an array of strings for a diacritic sensitive predicate.
    func d<S: Sequence<String>>(_ input: S) -> [String] {
        return input.compactMap({c($0)})
    }
    
    /// Returns a string for a word-based predicate.
    func w(_ input: String) -> String {
        return "$[w]\(input)"
    }
    
    /// Returns an array of strings for a word-based predicate.
    func w<S: Sequence<String>>(_ input: S) -> [String] {
        return input.compactMap({c($0)})
    }
    
    /// Returns a string for a case & diacritic sensitive predicate.
    func cd(_ input: String) -> String {
        return "$[cd]\(input)"
    }
    
    /// Returns an array of strings for a case & diacritic sensitive predicate.
    func cd<S: Sequence<String>>(_ input: S) -> [String] {
        return input.compactMap({c($0)})
    }
    
    /// Returns a string for a case sensitive & word-based predicate.
    func cw(_ input: String) -> String {
        return "$[cw]\(input)"
    }
    
    /// Returns an array of strings for a case sensitive & word-based predicate.
    func cw<S: Sequence<String>>(_ input: S) -> [String] {
        return input.compactMap({c($0)})
    }
    
    /// Returns a string for a diacritic sensitive & word-based predicate.
    func dw(_ input: String) -> String {
        return "$[dw]\(input)"
    }
    
    /// Returns an array of strings for a diacritic sensitive & word-based predicate.
    func dw<S: Sequence<String>>(_ input: S) -> [String] {
        return input.compactMap({c($0)})
    }
    
    /// Returns a string for a case & diacritic sensitive word-based predicate.
    func cdw(_ input: String) -> String {
        return "$[cdw]\(input)"
    }
    
    /// Returns an array of strings for a case & diacritic sensitive word-based predicate.
    func cdw<S: Sequence<String>>(_ input: S) -> [String] {
        return input.compactMap({c($0)})
    }
}
*/
