//
//  FileMonitor.swift
//
//
//  Created by Florian Zand on 29.03.25.
//

import Foundation

/// Monitors a specific file for changes in location, name, or deletion.
open class FileMonitor: NSObject {
    private let query = MetadataQuery()
    private var isUpdatingURL: Bool = false

    /**
     The current URL of the observed file, or `nil` if the file isn't existing (e.g. after deleting it).
     
     Updating the value monitors the file at the new URL if it exists; otherwise, monitoring stops.
     
     The property is key-value observable (KVO).
     */
    @objc dynamic public var fileURL: URL? {
        didSet {
            guard oldValue != fileURL else { return }
            if isUpdatingURL {
                history.prepend((Date(), fileURL))
                handler?(fileURL)
            } else if let fileURL = fileURL, NSMetadataItem(url: fileURL) != nil {
                history = isMonitoring ? [(Date(), fileURL)] : []
                query.urls = [fileURL]
            } else {
                history = []
                query.stop()
            }
        }
    }
    
    /**
     The handler that gets called when the observed file moves to a new location, renames or gets deleted.
     
     If the observed file if it moves to a new location or renames, the handler returns the new file URL. If it gets deleted, `nil` is returned.
     */
    public var handler: ((_ newURL: URL?)->())?
    
    /// The history of changes to the file URL from newest to oldest.
    public private(set) var history: [(date: Date, fileURL: URL?)] = []
    
    /// The queue on which the file is monitored and the handler gets called.
    public var operationQueue: OperationQueue? {
        get { query.operationQueue }
        set { query.operationQueue = newValue }
    }
    
    /// The interval (in seconds) at which the handler gets called for changes to the observed file. The default value is `0.5` seconds.
    public var notificationInterval: TimeInterval {
        get { query.updateNotificationInterval }
        set { query.updateNotificationInterval = newValue }
    }
    
    /**
     Starts monitoring the file.
     
     Monitoring only starts, if the file exists at ``fileURL``. You can check the monitoring state via ``isMonitoring``.
     */
    open func start() {
        guard !isMonitoring, let fileURL = fileURL, NSMetadataItem(url: fileURL) != nil else { return }
        if history.isEmpty {
            history = [(Date(), fileURL)]
        }
        query.start()
    }
    
    /// Stops monitoring the file.
    open func stop() {
        guard isMonitoring else { return }
        query.stop()
    }
    
    /// A Boolean value indicating whether file is monitored.
    public var isMonitoring: Bool {
        get { query.state != .isStopped }
        set {
            if newValue {
                start()
            } else {
                stop()
            }
        }
    }
    
    /**
     Creates a file monitor that monitors the file at the specific URL for changes in location, name, or deletion.
     
     - Parameters:
        - fileURL: The file URL.
        - operationQueue: The queue on which the file is monitored and the handler gets called.
        - handler: The handler that gets called when the file moves to a new location, renames or gets deleted.
     */
    public init(for fileURL: URL, operationQueue: OperationQueue? = nil, handler: @escaping (_ newURL: URL?) -> Void) {
        self.handler = handler
        self.fileURL = fileURL
        super.init()
        
        query.urls = [fileURL]
        query.operationQueue = operationQueue
        query.attributes = [.fileName]
        query.updateNotificationInterval = 0.5
        query.monitorResults = true
        query.resultsHandler = { [weak self] items, _ in
            guard let self = self else { return }
            self.isUpdatingURL = true
            if let path = items.compactMap({$0.path}).first {
                self.fileURL = URL(fileURLWithPath: path)
            } else {
                self.fileURL = nil
            }
            self.isUpdatingURL = false
        }
    }
    
    deinit {
        query.resultsHandler = nil
        query.stop()
    }
}
