//
//  ViewController.swift
//  Example
//
//  Created by Florian Zand on 11.01.24.
//

import Cocoa
import FZMetadata
import FZSwiftUtils

class ViewController: NSViewController {

    let query = MetadataQuery()
    let dateFormatter = DateFormatter("MM-dd-yyyy HH:mm")
    
    @IBOutlet weak var oldestTitleTextField: NSTextField!
    @IBOutlet weak var oldestFileTextField: NSTextField!
    @IBOutlet weak var newestTitleTextField: NSTextField!
    @IBOutlet weak var newestFileTextField: NSTextField!
    @IBOutlet weak var filesCountTextField: NSTextField!
    @IBOutlet weak var queryProgressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var queryDownloadsButton: NSButton!
    @IBOutlet weak var queryScreenshotsButton: NSButton!
    @IBOutlet weak var queryImagesButton: NSButton!
    @IBOutlet weak var queryVideosButton: NSButton!
    
    let dotView = NSView(frame: CGRect(0, 0, 8, 8))
    
    @IBAction func monitorScreenshots(_ sender: Any? = nil) {
        guard let desktopDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else { return }
        resetTextFields()
        dotView.frame.centerRight = queryScreenshotsButton.frame.centerLeft.offset(x: -3)

        query.searchLocations = [desktopDirectory]
        query.predicate = { $0.isScreenCapture == true }
        query.attributes = [.creationDate, .pixelSize, .fileSize]
        query.sortedBy = [.descending(.creationDate)]
        
        startQuery(fileType: "screenshot")
    }
    
    @IBAction func monitorImages(_ sender: Any? = nil) {
        guard let picturesDirectory = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else { return }
        resetTextFields()
        dotView.frame.centerRight = queryImagesButton.frame.centerLeft.offset(x: -3)

        query.searchLocations = [picturesDirectory]
        query.predicate = { $0.fileType == .image || $0.fileType == .gif }
        query.attributes = [.creationDate, .pixelSize, .fileSize]
        query.sortedBy = [.descending(.creationDate)]
        
        startQuery(fileType: "image")
    }
    
    @IBAction func monitorVideos(_ sender: Any? = nil) {
        guard let moviesDirectory = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first else { return }
        resetTextFields()
        dotView.frame.centerRight = queryVideosButton.frame.centerLeft.offset(x: -3)

        query.searchLocations = [moviesDirectory]
        query.predicate = { $0.fileType == .video }
        query.attributes = [.creationDate, .pixelSize, .fileSize, .duration]
        query.sortedBy = [.descending(.creationDate)]
        
        startQuery(fileType: "video")
    }
    
    @IBAction func monitorDownloads(_ sender: Any? = nil) {
        guard let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
        resetTextFields()
        dotView.frame.centerRight = queryDownloadsButton.frame.centerLeft.offset(x: -3)

        query.searchLocations = [downloadsDirectory]
        query.predicate = { $0.isFile }
        query.attributes = [.creationDate, .fileSize]
        query.sortedBy = [.descending(.creationDate)]
        
        startQuery(fileType: "file")
    }
    
    func startQuery(fileType: String) {
        queryProgressIndicator.startAnimation(nil)
        query.enableMonitoring()
        query.resultsHandler = { files, _ in
            DispatchQueue.main.async {
                self.displayResults(files, fileType: fileType)
            }
        }
        query.start()
    }
        
    func displayResults(_ files: [MetadataItem], fileType: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let totalSize = files.compactMap({ $0.fileSize }).sum().string
            
            DispatchQueue.main.async {
                if let file = files.first {
                    self.newestFileTextField.stringValue = self.infoString(for: file)
                    self.newestTitleTextField.isHidden = false
                }
                if let file = files.last, file != files.first {
                    self.oldestFileTextField.stringValue = self.infoString(for: file)
                    self.oldestTitleTextField.isHidden = false
                }
            
                if files.isEmpty {
                    self.filesCountTextField.stringValue = "No \(fileType)s"
                } else if files.count == 1 {
                    self.filesCountTextField.stringValue = "1 \(fileType), " + totalSize
                } else {
                    self.filesCountTextField.stringValue = "\(files.count) \(fileType)s, " + totalSize
                }
                self.queryProgressIndicator.stopAnimation(nil)
            }
        }
    }
    
    func infoString(for file: MetadataItem) -> String {
        guard let path = file.path else { return "" }
        var infoString = ""
        if let date = file.creationDate {
            infoString = dateFormatter.string(from: date)
        }
        if let fileSize = file.fileSize?.string {
            infoString += "\t\(fileSize)"
        }
        if let pixelSize = file.pixelSize {
            infoString += "\t\(Int(pixelSize.width))x\(Int(pixelSize.height))"
        }
        if let duration = file.duration?.string() {
            infoString += "\t\(duration)"
        }
        return infoString + "\n" + URL(fileURLWithPath: path).lastPathComponent
    }
    
    func resetTextFields() {
        filesCountTextField.stringValue = "Querying files…"
        oldestFileTextField.stringValue = ""
        newestFileTextField.stringValue = ""
        oldestTitleTextField.isHidden = true
        newestTitleTextField.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dotView.wantsLayer = true
        dotView.layer?.backgroundColor = NSColor.systemGreen.cgColor
        dotView.layer?.cornerRadius = dotView.bounds.height * 0.5
        view.addSubview(dotView)
        
        queryProgressIndicator.stopAnimation(nil)
        
        monitorScreenshots()
    }
}

