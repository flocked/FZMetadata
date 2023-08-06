# MetadataItem & MetadataQuery

File Metadata and File Query similar to Spotlight.

**For a full documentation take a look at the included documentation accessible via Xcode's documentation browser.**

## MetadataItem
An abstraction of NSMetadataItem for easy access of a file's attributes.
```
let videoURL = URL(filePathWithString: "videofile.mp4"
let movieDuration = videoURL.metadata.durationSeconds
let lastUsedDate = videoURL.metadata.lastUsedDate
let videoResolution = videoURL.metadata.pixelSize
```

## MetadataQuery
An abstraction of NSMetadataQuery for:
- Blazing fast search of files simliar to Spotlight by terms and attributes like file name, file size, last used date, movie duration, etc.
- Blazing fast query of attributes for large batches of files.
- Monitoring of files and directories for updates to the search query and attributes.

### Searching for files by location & file attributes
The results handler gets called whenever new files meet the specified predicate at the search locations.
```
let query = MetadataQuery()
query.searchLocations = [.downloadsDirectory, .documentsDirectory]
query.predicate = { 
    $0.fileTypes(.image, .video) && 
    $0.dateAdded.isThisWeek && 
    $0.fileSize.megabytes >= 10 
}  // Image & videos files, added this week, large than 10mb
query.resultsHandler = { files in
// found files
}
query.start()
```

### Query of file attributes
MetadataQuery provides blazing fast query of attributes for large batches of files. Fetching attributes for thousands of files often takes less than a second.
```
query.urls = videoFileURLs  // URLs for querying of attributes
query.attributes = [.pixelSize, .duration, .fileSize, .creationDate] // Attributes to query
query.resultsHandler = { files in  
    for file in files {
    // file.pixelSize, file.duration, file.fileSize, file.creationDate
    }
}
query.start()
```

### Monitoring of files & directories
MetadataQuery can monitor for changes to search results & queried attributes. It calls the completionHandler whenever changes happen.
```
query.predicate = { $0.isScreenCapture }  // Files that are screenshots
query.searchScopes = [.local] // Searches everywhere on the local file system
query.enableMonitoring() // Enables monitoring. Whenever a new screenshot gets captures the completion handler gets called
query.resultsHandler = { files in  
    for file in files {
    // screenshot files
    }
}
query.start()
```
