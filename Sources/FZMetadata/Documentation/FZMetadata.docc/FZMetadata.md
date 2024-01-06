# ``FZMetadata``

File Metadata and File Query similar to Spotlight.

## Overview

`FZMetadata` lets you access and change the metadata of files and query file metadata similar to Spotlight.

## MetadataItem

`MetadataItem` lets you access the metadata of a file.

```swift
let videoURL = URL(filePathWithString: pathToFile)
if let metadata = videoURL.metadata {
    let movieDuration = metadata.durationSeconds
    let lastUsedDate = metadata.lastUsedDate
    let videoResolution = metadata.pixelSize
}
```

## MetadataQuery

A file query that provides:
- Blazing fast search of files simliar to Spotlight by predicate and attributes like file name, file size, last used date, video duration, etc.
- Blazing fast query of attributes for large batches of files.
- Monitoring of files and directories for updates to the search results.

### Searching for files by location & predicate

The results handler gets called whenever new files meet the specified predicate at the search locations.

```swift
let query = MetadataQuery()
query.searchLocations = [.downloadsDirectory, .documentsDirectory]
query.predicate = { 
    $0.fileTypes(.image, .video) && 
    $0.dateAdded.isThisWeek && 
    $0.fileSize.megabytes >= 10 
}  // Image & videos files, added this week, large than 10mb
query.resultsHandler = { files, _ in
// found files
}
query.start()
```

### Query of file attributes

MetadataQuery provides blazing fast query of attributes for large batches of files. Fetching attributes for thousands of files often takes less than a second.

```swift
query.urls = videoFileURLs  // URLs for querying of attributes
query.attributes = [.pixelSize, .duration, .fileSize, .creationDate] // Attributes to query
query.resultsHandler = { files, _ in  
    for file in files {
    // file.pixelSize, file.duration, file.fileSize, file.creationDate
    }
}
query.start()
```

### Monitoring of files & directories

MetadataQuery can monitor for changes to search results & queried attributes. It calls the completionHandler whenever changes happen.

To enable monitoring use `enableMonitoring()`.

```swift
query.predicate = { $0.isScreenCapture }  // Files that are screenshots.
query.searchScopes = [.local] // Searches everywhere on the local file system.

// Enables monitoring. Whenever a new screenshot gets captures the completion handler gets called.
query.enableMonitoring()

query.resultsHandler = { files, _ in  
    for file in files {
    // screenshot files
    }
}
query.start()
```


## Topics

### File Metadata

- ``MetadataItem``

### File Query

- ``MetadataQuery``
- <doc:MetadataQuery+Predicate+Conformance>
