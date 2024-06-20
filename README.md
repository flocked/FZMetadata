# MetadataItem & MetadataQuery

File Metadata and File Query similar to Spotlight.

**Take a look at the included sample app.**

**For a full documentation take a look at the** [Online Documentation](https://swiftpackageindex.com/flocked/FZMetadata/documentation/).

## MetadataItem

`MetadataItem` lets you access the metadata of a file.

```swift
let videoFile = URL(filePathWithString: pathToFile)

if let metadata = videoFile.metadata {
    metadata.duration // video duration
    metadata.lastUsedDate // last usage date
    metadata.pixelSize // video pixel size
}
```

## MetadataQuery

A file query that provides:
- Blazing fast search of files simliar to Spotlight by predicate and attributes like file name, file size, last used date, video duration, etc.
- Blazing fast query of attributes for large batches of files.
- Monitoring of files and directories for updates to the search results.

### Searching for files by location & predicate

The results handler gets called whenever new files meet the specified predicate at the search locations.

The predicate is constructed by comparing `MetadataItem` properties to values using operators and functions.

```swift
let query = MetadataQuery()

// Searches for files at the downloads and documents directory
query.searchLocations = [.downloadsDirectory, .documentsDirectory]

// Image & videos files, added this week, large than 10mb
query.predicate = { 
    $0.fileTypes(.image, .video) && 
    $0.addedDate.isThisWeek && 
    $0.fileSize.megabytes >= 10 
}

query.resultsHandler = { files, _ in
// found files
}
query.start()
```

### Query of file attributes

MetadataQuery provides blazing fast query of attributes for large batches of files. Fetching attributes for thousands of files often takes less than a second.

```swift
// URLs for querying of attributes
query.urls = videoFileURLs

// Attributes to query
query.attributes = [.pixelSize, .duration, .fileSize, .creationDate]

query.resultsHandler = { files, _ in  
    for file in files {
    // file.pixelSize, file.duration, file.fileSize, file.creationDate
    }
}
query.start()
```

### Monitoring of files & directories

MetadataQuery can monitor for changes to search results & queried attributes. It calls the completionHandler whenever changes happen.

To enable monitoring use `monitorResults()`.

```swift
// Files that are screenshots
query.predicate = { $0.isScreenCapture }

// Searches everywhere on the local file system
query.searchScopes = [.local]

// Enables monitoring. Whenever a new screenshot gets captures the results handler gets called
query.monitorResults = true

query.resultsHandler = { files, _ in
    for file in files {
    // screenshot files
    }
}
query.start()
```
