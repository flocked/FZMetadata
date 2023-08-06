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
 query.searchLocations = [userDocumentURL]
 query.predicate = { $0.fileExtension = "doc" && $0.modificatonDate.today }
 query.resultsHandler = { items, _ in
 // the result
 }
 query.start()
 ```
 
 It can also fetch metadata attributes for large batches of file URLs.
 ```swift
 query.urls = [myMovieURLs]
 query.attributes = [.duration, .pixelSize, .fileSize, .lastUsageDate]
 query.resultsHandler = { items, _ in
 // the result
 }
 query.start()
 ```
 
 It can also montiro for changes via ``enableMonitoring()``.  The query calls your results handler, whenever new files match the query or file attributes change.
 
 ```swift
 query.predicate = { $0.modificationDate.today && $0.isFile }
 query.enableMonitoring()
 query.resultsHandler = { items, diff in
 // the result handler gets called whenever new files get modified
 }
 query.start()
 ```
 
 Using the query to search files and to fetch metadata attributes is much faster compared to manually search them e.g. via FileMananger or NSMetadataItem.
 */
public class MetadataQuery: NSObject, NSMetadataQueryDelegate {
    public typealias ResultsHandler = ((_ items: [MetadataItem], _ difference: ResultDifference)->())
    public typealias StateHandler = ((_ state: State)->())
    public typealias Item = MetadataItem
    public typealias Attribute = MetadataItem.Attribute
    
    /// The state of the query.
    public enum State {
        /// The query is in it's initial phase of gathering matching items.
        case isGatheringFiles
        /// The query is monitoring for updates to the result.
        case isMonitoring
        /// The query is stopped.
        case isStopped
    }
    
    public let query = NSMetadataQuery()
    
    public var resultsHandler: ResultsHandler? = nil
    public var stateHandler: StateHandler? = nil

    internal var isRunning: Bool { return self.query.isStarted }
    internal var isGathering: Bool { return self.query.isGathering }
    internal var isStopped: Bool { return self.query.isStopped }
    internal var isMonitoring: Bool { return self.query.isStopped == false && self.query.isGathering == false  }
    
    /// The state of the query.
    public var state: State {
        guard self.isStopped == false else { return .isStopped }
        return (self.isGathering == true) ? .isGatheringFiles : .isMonitoring
    }
    /**
     An array of URLs whose metadata attributes  are gathered by the query.
     
     Use this property to scope the metadata query to a collection of existing URLs. The query will gather metadata attributes for these urls.
     
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    public var urls: [URL] {
        get { (self.query.searchItems as? [URL]) ?? [] }
        set { query.searchItems = newValue.isEmpty ? nil : (newValue as [NSURL]) } }
    
    /**
     An array of metadata attributes whose values are fetched by the query.
     
    The attributes are
     
     The query collects the values of these attributes. Note that query many attributes will increase CPU usage and memory usage of an NSMetadataQuery object.
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    public var attributes: [Attribute] {
        get { return Attribute.values(for: query.valueListAttributes) }
        set { let newValue:  [Attribute] = [.path] + newValue
            query.valueListAttributes = newValue.flatMap({$0.mdKeys}).uniqued() }
    }
    
    /**
     An array of attributes  the query result with be grouped .
     
     The  query result will be sorted by the sort descriptors.
     
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     */
    public var groupingAttributes: [Attribute] {
        get { return query.groupingAttributes?.compactMap({Attribute(rawValue: $0)}) ?? [] }
        set {
            let newValue = newValue.flatMap({$0.mdKeys}).uniqued()
            query.groupingAttributes = newValue.isEmpty ? nil : newValue
        }
    }
    
    /**
     The predicate used to filter query results.
     
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     
     ### Operators
     Searchpredicate's can be defined by comparing MetadataItem keyPaths to a value or collection of values:
     - `==` equal
     - `!=` not equal
     - `>` greater than
     - `>=` greater than or equal
     - `<` less than
     - `<= Value` less than or equal
     - `== ClosedRange<Value>` between the values
     - `== Array<Value>` equales any of the values
     - `!= Array<Value>` equales none of the values
     ```swift
     query.predicate = { $0.fileName == "MyFile.doc" } // fileName is "MyFile.doc"
     query.predicate = { $0.fileExtension == ["mp4", "mov", "ts"] } // fileExtension is either "mp4", "mov" or "ts"
     query.predicate = { $0.fileSize.bytes >= 5000 } // fileSize is greater than or equal 5000 bytes
     query.predicate = { $0.creationDate < someDate } // creationDate is before someDate
     query.predicate = { $0.fileSize.megaBytes.between(500...1000) } // fileSize is between 5000 and 1000 megabytes
     
     Equatable
     - ==
     - !=
     - `func in([Value])` equales any
     - `== Array<Value>` equales any
     - `!= Array<Value>` equales none
     
     Comparable (Int, Double, Date, etc.)
     - >
     - >=
     - <
     - <=
     - `between(Range)` OR == Range
     
     String
     - `starts(with:)` OR *==
     - `ends(with:)` OR ==*
     - `contains(:)` OR *=*
     
     Date
     - now
     - today
     - yesterday
     - this(DateComponent)
        - this(.day), this(.week), this(.month), …
     - last(Int, DateComponent)
        -  last(30,.minute),  last(3, .month), last(2, .year), …
     - sameDay(as: Date)
     
     Collection
     - contains()
     - contains(any:)
     
     // Using a collection of values creates a predicate that checks if the attribute value appears in the collection:
     query.predicate = { $0.creationDate == [date1, date2, date3] } // creationDate is either date1, date2 or date3
     ```
     
     ### String Operators
     KeyPaths with string values have additional functions:
     - func `begins(with value: String)`
     - func `ends(with value: String)`
     - func `contains(_ value: String)`
     ```swift
     query.predicate = { $0.textContent.contains("important") } // textContent contains "important"
     query.predicate = { $0.fileName.begins(with: "img_") } // fileName begins with "img_"
     ```
     By default string value predicates are case and diacritic insensitive. To predicate case sensitive use c(_ ), diacritic sensitve d(_ ) or cd(_ ) for both case & diacritic sensitive:
     ```swift
     query.predicate = \.fsName *= c("Ant") // fsName begins with "Ant" case sensitive.
     query.predicate = \.fsName *= cd("Ömp") // fsName begins with "Ömp" case sensitive and diacritic sensitive.

     ```
     
     ### Date operators
     KeyPaths with date values can additionally equally checked against tjese properties:
     - `now`
     - `today
     - `yesterday`
     - sameDay(as: Date)
     -
     - `this(Calendar.Component)` this component (e.g. this week, this year)
     - `previous(Calendar.Component)` next component (e.g. previous week, previous year)
     - `next(Calendar.Component)` next component (e.g. next minute, next day)
     ```swift
     query.predicate = { $0.creationDate.yesterday } // creationDate was yesterday
     query.predicate = { $0.lastUsedDate.this(.week) } // lastUsedDate was this week
     query.predicate = \.fsContentChangeDate.last(.month) // fsContentChangeDate was last month
     ```
     
     Operators && (AND), || (OR) and ! (isNot) can be used:
     ```swift
     query.predicate = { $0.fileExtension == "mp4" && $0.fileSize.bytes > 5000 }
     query.predicate = { !($0.isDirectory && $0.directoryFilesCount > 100) }
     ```
     */
    public var predicate: ((Predicate<Item>)->(Predicate<Bool>))? {
        didSet {
            self.query.predicate = predicate?(.root).predicate ?? NSPredicate(format: "%K == 'public.item'", NSMetadataItemContentTypeTreeKey)
        }
    }
        
    /**
     An array of file-system directory URLs.
     
     The query searches for files at these search locations. An empty array indicates that there is no limitation on where the query searches.
     
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     
     The query can alternativly search globally at specific scropes via searchScopes.
     */
    public var searchLocations: [URL] {
        get { self.query.searchScopes.compactMap({$0 as? URL}) }
        set { self.query.searchScopes = newValue }
    }
                
    /**
     An array of seatch scopes.
     
     The query searches globally for files at these search scopes. An empty array indicates that there is no limitation on where the query searches.
     
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     
     The query can alternativly search at specific file-system directories via searchLocations.
     */
    public var searchScopes: [SearchScope] {
        get { self.query.searchScopes.compactMap({$0 as? String}).compactMap({SearchScope(rawValue: $0)}) }
        set {  self.query.searchScopes = newValue.compactMap({$0.rawValue}) }
    }
    
    /**
     An array of sort descriptor objects for sorting the query result.
     
     The sorted query result can be accessed via groupedResults.
          
     Setting this property while a query is running stops the query and discards the current results. The receiver immediately starts a new query.
     
     The result can be sorted by the relevance of the item's content via Attribute.queryContentRelevance.
          
     SortDescriptor can also be defined by using asc(_: Attribute) and dsc(_: Attribute) for ascending/descending order.
     ```swift
     query.sortedBy = [.asc(.fsCreationDate), <<.fsSize] // Sorted by ascending fsCreationDate & descending fsSize
     ```
     */
    public var sortedBy: [SortDescriptor]  {
        set { self.query.sortDescriptors = newValue }
        get { self.query.sortDescriptors.compactMap({$0 as? SortDescriptor}) }
    }
    
    /** The interval at which notification of updated results occurs.
     
        The default value is 1.0 seconds.
     */
    public var updateNotificationInterval: TimeInterval {
        get { self.query.notificationBatchingInterval }
        set { self.query.notificationBatchingInterval = newValue } }
    
    /**
     The queue on which query result notifications are posted.
     
     Use this property to decouple the processing of results from the thread used to execute the query. This makes it easier to synchronize query result processing with other related operations—such as updating the data model or user interface—which you might want to perform on the main queue.
     */
    public var operationQueue: OperationQueue? {
        get { self.query.operationQueue }
        set { self.query.operationQueue = newValue } }
    
    /**
     Starts the query.
     
     It starts the query if it isn't running and resets the current result.
     */
    public func start()  {
        if let operationQueue = self.operationQueue {
            operationQueue.addOperation{
                self.startQuery()
            }
        } else {
            self.startQuery()
        }
    }
    /**
     Stops the  current query from gathering any further results.
     */
    public func stop() {
        if (self.isStopped == false) {
            self.stateHandler?(.isStopped)
        }
        query.stop()
    }
    
    internal func startQuery() {
        if self.query.start() == true {
            self._results = []
        }
    }
    
    internal func reset() {
        self.resultsHandler = nil
        self.searchScopes = []
        self.urls = []
        self.predicate = nil
        self.attributes = []
        self.groupingAttributes = []
        self.sortedBy = []
    }
    
    internal func runWithPausedMonitoring(_ block: ()->()) {
        let _isMonitoringEnabled = self.isMonitoringEnabled
        self.disableMonitoring()
        block()
        if (_isMonitoringEnabled == true) {
            self.enableMonitoring()
        }
    }
    
    /**
     An array containing the query’s results.
     
     The array contains MetadataItems. Accessing the result before a query is finished will momentarly pause the query and provide  a snapshot of the current query results.
     */
    public var results: [MetadataItem] {
        self.updateResults()
        return self._results
    }
    
    internal var _results: [MetadataItem] = []
    internal func updateResults() {
        _results = self.results(at: Array(0..<self.query.resultCount))
    }
    
    internal func updateResultAddition() {
        self.runWithPausedMonitoring {
            let changeCount = (query.resultCount - _results.count)
            if (changeCount != 0) {
                let added =  results(at: Array(_results.count..<changeCount))
                _results = _results + added
                self.resultsHandler?(self.results, .added(added))
            }
        }
    }
    
    internal func resetResults() {
        _results.removeAll()
    }
    
    internal func results(at indexes: [Int]) -> [MetadataItem] {
        return indexes.compactMap({self.result(at: $0)})
    }
    
    internal func result(at index: Int) -> MetadataItem? {
        let result = self.query.result(at: index) as? MetadataItem
        result?.values = resultAttributeValues(at: index)
        return result
    }
    
    internal func resultAttributeValues(at index: Int) -> [String: Any] {
        return self.query.values(of: allAttributeKeys, forResultsAt: index)
    }
    
    internal func resultAttributeValues(for item: MetadataItem) -> [String: Any] {
        let index = self.query.index(ofResult: item)
        return self.resultAttributeValues(at: index)
    }
    
    internal var allAttributeKeys: [String] {
        var attributes = self.query.valueListAttributes
        attributes = attributes + self.sortedBy.compactMap({$0.key})
        attributes = attributes + self.groupingAttributes.compactMap({$0.rawValue}) + ["kMDQueryResultContentRelevance"]
        return attributes.uniqued()
    }
    
    internal var predicateAttributes: [Attribute] {
        predicate?(.root).attributes ?? []
    }
    
    internal var sortingAttributes: [Attribute] {
        self.sortedBy.compactMap({Attribute(rawValue: $0.key ?? "_")})
    }
    
    /**
     An array containing hierarchical groups of query results.
     
     These groups are based on the groupingAttributes property.
     */
    public var groupedResults: [ResultGroup] {
        return self.query.groupedResults.compactMap({ResultGroup(nsResultGroup: $0)})
    }
    
    /**
     Enables the monitoring of changes to the result.
     
     By default, notification of updated results occurs at 1.0 seconds. Use the updateNotificationInterval property to customize.
     */
    public func enableMonitoring() {
        self.query.enableUpdates()
        self.isMonitoringEnabled = true
    }
    
    /// Disables the monitoring of changes to the result.
    public func disableMonitoring() {
        self.query.disableUpdates()
        self.isMonitoringEnabled = false
    }
    
    internal var isMonitoringEnabled = false
    
    @objc internal func queryGatheringDidStart(_ notification: Notification) {
        Swift.debugPrint("MetadataQuery GatheringDidStart")
        self.resetResults()
        self.stateHandler?(.isGatheringFiles)
    }
    
    @objc internal func queryGatheringFinished(_ notification: Notification) {
        Swift.debugPrint("MetadataQuery GatheringFinished")
        self.runWithPausedMonitoring {
            self.stateHandler?(.isMonitoring)
            self.resultsHandler?(self.results, .added(_results))
            // updateResultAdditions()
        }
    }
    
    @objc internal func queryGatheringProgress(_ notification: Notification) {
        Swift.debugPrint("MetadataQuery GatheringProgress")
      //  updateResultAdditions()
    }
    
    @objc internal func queryUpdated(_ notification: Notification) {
        Swift.debugPrint("MetadataQuery Updated")
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
            resultsHandler?(_results, ResultDifference(added: added, removed: removed, changed: changed))
        }
    }
     
    internal func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringDidStart(_:)), name: .NSMetadataQueryDidStartGathering , object: self.query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringFinished(_:)), name: .NSMetadataQueryDidFinishGathering , object: self.query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryUpdated(_:)), name: .NSMetadataQueryDidUpdate, object: self.query)
        NotificationCenter.default.addObserver(self, selector: #selector(queryGatheringProgress(_:)), name: .NSMetadataQueryGatheringProgress, object: self.query)
    }
    
    internal func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func metadataQuery(_ query: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> Any {
        let item = MetadataItem(item: result)
        return item
    }
        
    public override init() {
        super.init()
        self.reset()
        self.addObserver()
        self.query.delegate = self
    }
}

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
