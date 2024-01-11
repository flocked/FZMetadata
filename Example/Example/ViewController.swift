//
//  ViewController.swift
//  Example
//
//  Created by Florian Zand on 11.01.24.
//

import Cocoa
import FZMetadata
import FZUIKit

class ViewController: NSViewController {

    let query = MetadataQuery()
    let dateFormatter = DateFormatter("MM-dd-yyyy HH:mm")
    @IBOutlet weak var filesCountTextField: NSTextField!
    @IBOutlet weak var oldestFileTextField: NSTextField!
    @IBOutlet weak var newestFileTextField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        monitorScreenshots()
    }
    
    func resetTextFields() {
        filesCountTextField.stringValue = "Fetching…"
        oldestFileTextField.stringValue = "-"
        newestFileTextField.stringValue = "-"
    }
    
    @IBAction func monitorScreenshots(_ sender: Any? = nil) {
        guard let desktopDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else { return }
        resetTextFields()
        
        query.searchLocations = [desktopDirectory]
        query.predicate = { $0.isScreenCapture == true }
        query.attributes = [.creationDate, .pixelSize, .fileSize]
        query.sortedBy = [.ascending(.creationDate)]
        query.enableMonitoring()
        query.resultsHandler = { files, _ in
            self.printItems(files, typeString: "screenshot")
        }
        query.start()
    }
    
    @IBAction func monitorImages(_ sender: Any? = nil) {
        guard let picturesDirectory = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else { return }
        resetTextFields()

        query.searchLocations = [picturesDirectory]
        query.predicate = { $0.fileType == .image || $0.fileType == .gif }
        query.attributes = [.creationDate, .pixelSize, .fileSize]
        query.sortedBy = [.ascending(.creationDate)]
        query.enableMonitoring()
        query.resultsHandler = { files, _ in
            self.printItems(files, typeString: "image")
        }
        query.start()
    }
    
    @IBAction func monitorVideos(_ sender: Any? = nil) {
        guard let moviesDirectory = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first else { return }
        resetTextFields()
        
        query.searchLocations = [moviesDirectory]
        query.predicate = { $0.fileType == .video }
        query.attributes = [.creationDate, .pixelSize, .fileSize, .duration]
        query.sortedBy = [.ascending(.creationDate)]
        query.enableMonitoring()
        query.resultsHandler = { files, _ in
            self.printItems(files, typeString: "video")
        }
        query.start()
    }
    
    @IBAction func monitorDownloads(_ sender: Any? = nil) {
        guard let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
        resetTextFields()
        
        query.searchLocations = [downloadsDirectory]
        query.predicate = { $0.fileType == .video || $0.fileType == .image || $0.fileType == .gif || $0.fileType == .audio  || $0.fileType == .document }
        query.attributes = [.creationDate, .fileSize]
        query.sortedBy = [.ascending(.creationDate)]
        query.enableMonitoring()
        query.resultsHandler = { files, _ in
            self.printItems(files, typeString: "file")
        }
        query.start()
    }
    
    func printItems(_ files: [MetadataItem], typeString: String) {
        let files = files.sorted(by: \.creationDate, .newestFirst)
        let totalSize = files.compactMap({$0.fileSize}).sum().string
        if let file = files.first, let path = file.path, let date = file.creationDate {
            self.newestFileTextField.stringValue = self.dateFormatter.string(from: date) + "\n" + URL(fileURLWithPath: path).lastPathComponent
        }
        if let file = files.last, let path = file.path, let date = file.creationDate {
            self.oldestFileTextField.stringValue = self.dateFormatter.string(from: date) + "\n" + URL(fileURLWithPath: path).lastPathComponent
        }
        if files.isEmpty {
            self.filesCountTextField.stringValue = "No \(typeString)s"
        } else if files.count == 1 {
            self.filesCountTextField.stringValue = "1 \(typeString), " + totalSize
        } else {
            self.filesCountTextField.stringValue = "\(files.count) \(typeString)s, " + totalSize
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        view.window?.visualEffect = .vibrantLight(blendingMode: .behindWindow, material: .hudWindow)
    }
}

