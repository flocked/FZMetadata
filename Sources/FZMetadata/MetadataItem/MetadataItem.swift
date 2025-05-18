//
//  MetadataItem.swift
//
//
//  Created by Florian Zand on 28.08.22.
//

import Foundation
import FZSwiftUtils

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import UniformTypeIdentifiers

#if os(macOS)
public extension URL {
    /**
     The metadata for the file at this url.

     - Returns: The metadata, or `nil` if the file isn't available or can't be accessed.
     */
    var metadata: MetadataItem? {
        MetadataItem(url: self)
    }
}
#endif

/**
 The metadata associated with a file.

 You either access the metadata by using the ``Foundation/URL/metadata`` property of a file URL or create it using ``init(url:)``.

 ```swift
 if let metadata = fileURL.metadata {
    metadata.creationDate // file creation date
    metadata.fileSize // file size
 }
 ```

 Some metadata values can be changed.

 ```swift
 metadata.contentModificationDate = Date.now
 ```
 */
open class MetadataItem: NSObject, Identifiable {
    /// The identifier of the item.
    public let id = UUID()
    
    let item: NSMetadataItem
    
    /// Attribute values fetched by a query.
    var values: [String: Any] = [:]
    
    var changes = Changes()
    
    /// Cached file path.
    var filePath: String?
    weak var filePathOperation: Operation?
        
    /**
     Initializes a metadata item with a given `NSMetadataItem`.

     - Parameter item: The `NSMetadataItem`.
     - Returns: A metadata item.
     */
    public init(item: NSMetadataItem) {
        self.item = item
        values = [:]
    }

    #if os(macOS)
    /**
     Initializes a metadata item with a given URL.

     Example usage:

     ```swift
     if let metadata = MetadataItem(url: fileURL) {
        metadata.creationDate // The creation date of the file
        metadata.contentModificationDate = Date()
     }
     ```

     - Parameter url: The URL for the metadata
     - Returns: A metadata item for the file at the url, or `nil` if the file isn't available or can't be accessed.
     */
    public init?(url: URL) {
        guard let item = NSMetadataItem(url: url) else { return nil }
        self.item = item
        self.filePath = url.path
    }
    #endif
    
    // MARK: - Attributes

    /**
     The available attributes for this metadata item.

     For a list of possible attributes, see ``Attribute``.
     */
    open var availableAttributes: [Attribute] {
        var attributes = (values.keys + item.attributes).uniqued().sorted().compactMap { Attribute(rawValue: $0) }
        if attributes.contains(all: [.pixelWidth, .pixelHeight]) {
            attributes.append(.pixelSize)
        }        
        if attributes.contains(all: [.dpiResolutionWidth, .dpiResolutionHeight]) {
            attributes.append(.dpiResolution)
        }
        return attributes
    }
    
    /**
     The attributes that have changed since the last metadata query results update.
     
     If the item is part of the query results, the property lists the attributes that have changed between each query results update.
     
     It lists changes for attributes specified by the query's ``MetadataQuery/attributes``, ``MetadataQuery/groupingAttributes``, and ``MetadataQuery/sortedBy`` properties.
     
     In the following example the query is gathering files and attributes. Because `monitorResults` is enabled, the handler is called subsequently whenever the available files or their attributes change. 
     
     `updatedAttributes` is  used to filter the files by the attributes that have changed:
          
     ```swift
     query,searchLocations = [folder]
     query.attributes = [.finderTags, .lastUsedDate]
     query.monitorResults = true
     query.resultsHandler = { items, _ in
        // Files with changed finder tags.
        let finderTagFiles = items.filter({$0.updatedAttributes.contains(.finderTags)})

        // Files with changed last usage date.
        let lastUsedFiles = items.filter({$0.updatedAttributes.contains(.lastUsedDate)})
     }
     query.start()
     ```
     */
    open var updatedAttributes: [Attribute] {
        changes.changedAttributes
    }
    
    /// A Boolean value indicating whether the specified attribute has changed between the current and previous item state.
    open func didUpdate(_ attribute: Attribute) -> Bool {
        changes.didChange(attribute)
    }
    
    // MARK: - File

    /// The url of the file.
    open var url: URL? {
        _url ?? value(for: .url)
    }
    
    var _url: URL? {
        guard let path = path else { return nil }
        return URL(fileURLWithPath: path)
    }

    /**
     The full path of the file.
     
     - Note: The attribute can't be used in a metadata query predicate or to sort query results.
     */
    open var path: String? { 
        filePathOperation?.cancel()
        filePath = filePath ?? value(for: .path)
        return filePath
    }

    /// The name of the file including the extension.
    open var fileName: String? {
        return _url?.lastPathComponent ?? (values[Attribute.url.rawValue] as? URL)?.lastPathComponent ?? value(for: .fileName)
    }

    /// The display name of the file, which may be different then the file system name.
    open var displayName: String? { value(for: .displayName) }

    /// The alternative names of the file.
    open var alternateNames: [String]? { value(for: .alternateNames) }

    /// The extension of the file.
    open var fileExtension: String? { url?.pathExtension }

    /// The size of the file.
    open var fileSize: DataSize? {
        guard let bytes: Int = value(for: .fileSize) else { return nil }
        return DataSize(bytes)
    }

    /// A Boolean value that indicates whether the file is invisible.
    open var fileIsInvisible: Bool? {
        get { value(for: .fileIsInvisible) }
        set {
            if let resources = url?.resources {
                resources.isHidden = newValue ?? resources.isHidden
            } else {
                setExplicity(.fileIsInvisible, to: newValue)
            }
        }
    }

    /// A Boolean value that indicates whether the file extension is hidden.
    open var fileExtensionIsHidden: Bool? { value(for: .fileExtensionIsHidden) }

    /// The file type. For example: `video`, `document` or `directory`
    open var fileType: FileType? {
        guard let identifiers = contentTypeIdentifierTree else { return nil }
        return FileType(contentTypeTree: identifiers)
    }
    
    /// The content type of the file.
    open var contentType: UTType? {
        guard let contentType: String = value(for: .contentType) else { return nil }
        return UTType(contentType)
    }
    
    /// The content type tree of the file.
    open var contentTypeTree: [UTType]? {
        guard let identifiers = contentTypeIdentifierTree else { return nil }
        return identifiers.compactMap { UTType($0) }
    }
    
    private var contentTypeIdentifierTree: [String]? {
        value(for: .contentTypeTree)
    }

    /// The date the file was created on the file system.
    open var creationDate: Date? {
        get { value(for: .creationDate) }
        set { setExplicity(.creationDate, urlResources: \.creationDate, to: newValue) }
    }
    
    /// The last date that the item's data on the file system was modified.
    open var modificationDate: Date? {
        get { value(for: .modificationDate) }
        set { setExplicity(.modificationDate, to: newValue) }
    }
    
    /// The date that the content of the file was created.
    open var contentCreationDate: Date? {
        get { value(for: .contentCreationDate) }
        set { setExplicity(.contentCreationDate, to: newValue) }
    }

    /// The last date that the content of the file was modified.
    open var contentModificationDate: Date? {
        get { value(for: .contentModificationDate) }
        set { setExplicity(.contentModificationDate, urlResources: \.contentModificationDate, to: newValue) }
    }
    
    /// The last date that the attributes of the file were changed.
    open var attributeModificationDate: Date? {
        get { value(for: .attributeModificationDate) }
        set { setExplicity(.attributeModificationDate, to: newValue) }
    }

    /// The last date that the file was used.
    open var lastUsedDate: Date? {
        get { value(for: .lastUsedDate) }
        set { setExplicity(.lastUsedDate, urlResources: \.contentAccessDate, to: newValue) }
    }

    /// The dates the file was last used.
    open var lastUsageDates: [Date]? {
        get { value(for: .lastUsageDates) }
        set { setExplicity(.lastUsageDates, to: newValue) }
    }

    /// The date the file was created, or renamed into or within its parent directory.
    open var addedDate: Date? {
        get { value(for: .addedDate) }
        set { setExplicity(.addedDate, to: newValue) }
    }

    /// The date that the file was downloaded.
    open var downloadedDate: Date? {
        get { value(for: .downloadedDate) }
        set { setExplicity(.downloadedDate, to: newValue) }
    }

    /// The date that the file was purchased.
    open var purchaseDate: Date? { value(for: .purchaseDate) }

    /// The date that this item is due (e.g. for a calendar event file).
    open var dueDate: Date? {
        get { value(for: .dueDate) }
        set { setExplicity(.dueDate, to: newValue) }
    }

    /// The number of files in a directory.
    open var directoryFilesCount: Int? { value(for: .directoryFilesCount) }

    ///  A description of the content of the item. The description may include an abstract, table of contents, reference to a graphical representation of content or a free-text account of the content.
    open var contentDescription: String? {
        get { value(for: .contentDescription) }
        set { setExplicity(.contentDescription, to: newValue) }
    }

    /// A description of the kind of item the file represents.
    open var kind: [String]? { value(for: .kind) }

    /// Information of this item.
    open var information: String? { 
        get { value(for: .information) }
        set { setExplicity(.information, to: newValue) }
    }

    /// The formal identifier used to reference the item within a given context.
    open var identifier: String? { value(for: .identifier) }

    /// The keywords associated with the file. For example: `Birthday` or `Important`.
    open var keywords: [String]? { 
        get { value(for: .keywords) }
        set { setExplicity(.keywords, to: newValue) }
    }

    /// The title of the file. For example, this could be the title of a document, the name of a song, or the subject of an email message.
    open var title: String? { 
        get { value(for: .title) }
        set { setExplicity(.title, to: newValue) }
    }

    /// The title for a collection of media. This is analagous to a record album, or photo album.
    open var album: String? {
        get { value(for: .album) }
        set { setExplicity(.album, to: newValue) }
    }

    /// The authors, artists, etc. of the contents of the file.
    open var authors: [String]? { value(for: .authors) }

    /// The version of the file.
    open var version: String? { value(for: .version) }

    /// A comment related to the file. This differs from ``finderComment``.
    open var comment: String? { 
        get { value(for: .comment) }
        set { setExplicity(.comment, to: newValue) }
    }

    /// The user rating of the file. For example, the stars rating of an iTunes track.
    open var starRating: Double? { 
        get { value(for: .starRating) }
        set { setExplicity(.starRating, to: newValue) }
    }

    /// A describes where the file was obtained from. For example download urls.
    open var whereFroms: [String]? {
        get { value(for: .whereFroms) }
        set { setExplicity(.whereFroms, to: newValue) }
    }

    /// The finder comment of the file. This differs from the ``comment``.
    open var finderComment: String? { value(for: .finderComment) }

    /// The finder tags of the file.
    open var finderTags: [String]? {
        get { 
            if let finderTags: [String] = value(for: .finderTags) {
                return finderTags
            }
            return url?.resources.finderTags
        }
        set { url?.resources.finderTags = newValue ?? [] }
    }
    
    /// The primary (first) finder tag color.
    open var finderTagPrimaryColor: FinderTagColor? {
        value(for: .finderTagPrimaryColor)
    }

    /// A Boolean value that indicates whether the file has a custom icon.
    open var hasCustomIcon: Bool? { value(for: .hasCustomIcon) }

    /// The number of usages of the file.
    open var usageCount: Int? { 
        if let useCount: Int = value(for: .usageCount) {
            return useCount - 2
        }
        return nil
    }

    /// The bundle identifier of this item. If this item is a bundle, then this is the `CFBundleIdentifier`.
    open var bundleIdentifier: String? { value(for: .bundleIdentifier) }

    /// The architectures this item requires to execute.
    open var executableArchitectures: [String]? { value(for: .executableArchitectures) }

    /// The platform this item requires to execute.
    open var executablePlatform: String? { value(for: .executablePlatform) }

    /// A Boolean value that indicates whether the file is owned and managed by an application.
    open var isApplicationManaged: Bool? { value(for: .isApplicationManaged) }

    /// The application used to convert the original content into it's current form. For example, a PDF file might have an encoding application set to "Distiller".
    open var encodingApplications: [String]? {
        get { value(for: .encodingApplications) }
        set { setExplicity(.encodingApplications, to: newValue) }
    }

    /// The categories the application is a member of.
    open var applicationCategories: [String]? { value(for: .applicationCategories) }

    /// The AppStore category of this item if it's an application from the AppStore.
    open var appstoreCategory: String? { value(for: .appstoreCategory) }

    /// The AppStore category type of this item if it's an application from the AppStore.
    open var appstoreCategoryType: String? { value(for: .appstoreCategoryType) }

    // MARK: - Person / Contact

    // MARK: - Document

    /// A text representation of the content of the document.
    open var textContent: String? { value(for: .textContent) }

    /// The subject of the this item
    open var subject: String? { value(for: .subject) }

    /// The theme of the this item.
    open var theme: String? { value(for: .theme) }

    /// A publishable summary of the contents of the item.
    open var headline: String? {
        get { value(for: .headline) }
        set { setExplicity(.headline, to: newValue) }
    }

    /// the application or operation system used to create the document content. For example: `Word`,  `Pages` or `16.2`.
    open var creator: String? { value(for: .creator) }

    /// Other information concerning this item, such as handling instructions.
    open var instructions: String? { value(for: .instructions) }

    /// The editors of the contents of the file.
    open var editors: [String]? { value(for: .editors) }

    /// The audience for which the file is intended. The audience may be determined by the creator or the publisher or by a third party.
    open var audiences: [String]? { value(for: .audiences) }

    /// The extent or scope of the content of the document.
    open var coverage: [String]? { value(for: .coverage) }

    /// The list of projects that the file is part of. For example, if you were working on a movie all of the files could be marked as belonging to the project `My Movie`.
    open var projects: [String]? { value(for: .projects) }

    /// The number of pages in the document.
    open var numberOfPages: Double? { value(for: .numberOfPages) }

    /// The width of the document page, in points (72 points per inch). For PDF files this indicates the width of the first page only.
    open var pageWidth: Double? { value(for: .pageWidth) }

    /// The height of the document page, in points (72 points per inch). For PDF files this indicates the height of the first page only.
    open var pageHeight: Double? { value(for: .pageHeight) }

    /// The copyright owner of the file contents.
    open var copyright: String? {
        get { value(for: .copyright) }
        set { setExplicity(.copyright, to: newValue) }
    }

    /// The names of the fonts used in his document.
    open var fonts: [String]? { value(for: .fonts) }

    /// The family name of the font used in this document.
    open var fontFamilyName: String? { value(for: .fontFamilyName) }

    /// A list of contacts that are associated with this document, not including the authors.
    open var contactKeywords: [String]? { value(for: .contactKeywords) }

    /// The languages of the intellectual content of the resource.
    open var languages: [String]? { value(for: .languages) }

    /// A link to information about rights held in and over the resource.
    open var rights: String? { value(for: .rights) }

    /// The company or organization that created the document.
    open var organizations: [String]? { value(for: .organizations) }

    /// The entity responsible for making this item available. For example, a person, an organization, or a service. Typically, the name of a publisher should be used to indicate the entity.
    open var publishers: [String]? { value(for: .publishers) }

    /// The email Addresses related to this document.
    open var emailAddresses: [String]? { value(for: .emailAddresses) }

    /// The phone numbers related to this document.
    open var phoneNumbers: [String]? { value(for: .phoneNumbers) }

    /// The people or organizations contributing to the content of the document.
    open var contributors: [String]? { value(for: .contributors) }

    /// The security or encryption method used for the document.
    open var securityMethod: Double? { value(for: .securityMethod) }

    // MARK: - Places

    /// The full, publishable name of the country or region where the intellectual property of this item was created, according to guidelines of the provider.
    open var country: String? {
        get { value(for: .country) }
        set { setExplicity(.country, to: newValue) }
    }

    /// The city.of this document.
    open var city: String? {
        get { value(for: .city) }
        set { setExplicity(.city, to: newValue) }
    }

    /// The province or state of origin according to guidelines established by the provider. For example: `CA`, `Ontario` or `Sussex`.
    open var stateOrProvince: String? {
        get { value(for: .stateOrProvince) }
        set { setExplicity(.stateOrProvince, to: newValue) }
    }

    /// The area information of the file.
    open var areaInformation: String? { value(for: .areaInformation) }

    /// The name of the location or point of interest associated with the
    open var namedLocation: String? { value(for: .namedLocation) }

    /// The altitude of this item in meters above sea level, expressed using the WGS84 datum. Negative values lie below sea level.
    open var altitude: Double? { value(for: .altitude) }

    /// The latitude of this item in degrees north of the equator, expressed using the WGS84 datum. Negative values lie south of the equator.
    open var latitude: Double? { value(for: .latitude) }

    /// The longitude of this item in degrees east of the prime meridian, expressed using the WGS84 datum. Negative values lie west of the prime meridian.
    open var longitude: Double? { value(for: .longitude) }

    /// The speed of this item, in kilometers per hour.
    open var speed: Double? { value(for: .speed) }

    /// The timestamp on the item  This generally is used to indicate the time at which the event captured by this item took place.
    open var timestamp: Date? { value(for: .timestamp) }

    /// The direction of travel of this item, in degrees from true north.
    open var gpsTrack: Double? { value(for: .gpsTrack) }

    /// The gps status of this item.
    open var gpsStatus: String? { value(for: .gpsStatus) }

    /// The gps measure mode of this item.
    open var gpsMeasureMode: String? { value(for: .gpsMeasureMode) }

    /// The gps dop of this item.
    open var gpsDop: Double? { value(for: .gpsDop) }

    /// The gps map datum of this item.
    open var gpsMapDatum: String? { value(for: .gpsMapDatum) }

    /// The gps destination latitude of this item.
    open var gpsDestLatitude: Double? { value(for: .gpsDestLatitude) }

    /// The gps destination longitude of this item.
    open var gpsDestLongitude: Double? { value(for: .gpsDestLongitude) }

    /// The gps destination bearing of this item.
    open var gpsDestBearing: Double? { value(for: .gpsDestBearing) }

    /// The gps destination distance of this item.
    open var gpsDestDistance: Double? { value(for: .gpsDestDistance) }

    /// The gps processing method of this item.
    open var gpsProcessingMethod: String? { value(for: .gpsProcessingMethod) }

    /// The gps date stamp of this item.
    open var gpsDateStamp: Date? { value(for: .gpsDateStamp) }

    /// The gps differental of this item.
    open var gpsDifferental: Double? { value(for: .gpsDifferental) }

    // MARK: - Audio

    /// The sample rate of the audio data contained in the file. The sample rate representing `audio_frames/second`. For example: `44100.0`, `22254.54`.
    open var audioSampleRate: Double? { value(for: .audioSampleRate) }

    /// The number of channels in the audio data contained in the file.
    open var audioChannelCount: Int? { value(for: .audioChannelCount) }

    /// The name of the application that encoded the data of a audio file.
    open var audioEncodingApplication: String? { value(for: .audioEncodingApplication) }

    /// The tempo that specifies the beats per minute of the music contained in the audio file.
    open var tempo: Double? { value(for: .tempo) }

    /// The key of the music contained in the audio file. For example: `C`, `Dm`, `F#, `Bb`.
    open var keySignature: String? { value(for: .keySignature) }

    /// The time signature of the musical composition contained in the audio/MIDI file. For example: `4/4`, `7/8`.
    open var timeSignature: String? {
        get { value(for: .timeSignature) }
        set { setExplicity(.timeSignature, to: newValue) }
    }

    /// The track number of a song or composition when it is part of an album.
    open var trackNumber: Int? {
        get { value(for: .trackNumber) }
        set { setExplicity(.trackNumber, to: newValue) }
    }

    /// The composer of the music contained in the audio file.
    open var composer: String? {
        get { value(for: .composer) }
        set { setExplicity(.composer, to: newValue) }
    }

    /// The lyricist, or text writer, of the music contained in the audio file.
    open var lyricist: String? {
        get { value(for: .lyricist) }
        set { setExplicity(.lyricist, to: newValue) }
    }

    /// The recording date of the song or composition.
    open var recordingDate: Date? {
        get { value(for: .recordingDate) }
        set { setExplicity(.recordingDate, to: newValue) }
    }

    /// Indicates the year this item was recorded. For example: `1964`, `2003`.
    open var recordingYear: Double? {
        get { value(for: .recordingYear) }
        set { setExplicity(.recordingYear, to: newValue) }
    }

    /// The musical genre of the song or composition contained in the audio file. For example: `Jazz`, `Pop`, `Rock`, `Classical`.
    open var musicalGenre: String? {
        get { value(for: .musicalGenre) }
        set { setExplicity(.musicalGenre, to: newValue) }
    }

    /// A Boolean value that indicates whether the MIDI sequence contained in the file is setup for use with a General MIDI device.
    open var isGeneralMidiSequence: Bool? { value(for: .isGeneralMidiSequence) }

    /// The original key of an Apple loop. The key is the root note or tonic for the loop, and does not include the scale type.
    open var appleLoopsRootKey: String? { value(for: .appleLoopsRootKey) }

    /// The key filtering information of an Apple loop. Loops are matched against projects that often in a major or minor key.
    open var appleLoopsKeyFilterType: String? { value(for: .appleLoopsKeyFilterType) }

    /// The looping mode of an Apple loop.
    open var appleLoopsLoopMode: String? { value(for: .appleLoopsLoopMode) }

    /// The escriptive information of an Apple loop.
    open var appleLoopDescriptors: [String]? { value(for: .appleLoopDescriptors) }

    /// The category of the instrument.
    open var musicalInstrumentCategory: String? { value(for: .musicalInstrumentCategory) }

    /// The name of the instrument relative to the instrument category.
    open var musicalInstrumentName: String? { value(for: .musicalInstrumentName) }

    // MARK: - Media

    /// The duration of the content of file. Usually for videos and audio.
    open var duration: TimeDuration? {
        if let durationSeconds: Double = value(for: .duration) {
            return TimeDuration(durationSeconds)
        }
        return nil
    }

    /// The media content types (video and sound) present in the file.
    open var mediaTypes: [String]? {
        value(for: .mediaTypes)
    }
    
    /// The codecs used to encode/decode the media.
    open var codecs: [MediaCodec]? {
        guard let codecs: [String] = value(for: .codecs) else { return nil }
        return codecs.map({ MediaCodec($0) })
    }

    /// The total bit rate, audio and video combined, of the media.
    open var totalBitRate: Double? { value(for: .totalBitRate) }

    /// The video bit rate of the media.
    open var videoBitRate: Double? { value(for: .videoBitRate) }

    /// The audio bit rate of the media.
    open var audioBitRate: Double? { value(for: .audioBitRate) }

    /// A Boolean value that indicates whether the media is prepared for streaming.
    open var streamable: Bool? { value(for: .streamable) }

    /// The delivery type of the media. Either `Fast start` or `RTSP`.
    open var mediaDeliveryType: String? { value(for: .mediaDeliveryType) }

    /// Original format of the media.
    open var originalFormat: String? {
        get { value(for: .originalFormat) }
        set { setExplicity(.originalFormat, to: newValue) }
    }

    /// Original source of the media.
    open var originalSource: String? {
        get { value(for: .originalSource) }
        set { setExplicity(.originalSource, to: newValue) }
    }

    /// The genre of the content.
    open var genre: String? {
        get { value(for: .genre) }
        set { setExplicity(.genre, to: newValue) }
    }

    /// The director of the content.
    open var director: String? {
        get { value(for: .director) }
        set { setExplicity(.director, to: newValue) }
    }

    /// The producer of the content.
    open var producer: String? {
        get { value(for: .producer) }
        set { setExplicity(.producer, to: newValue) }
    }

    /// The performers of the content.
    open var performers: [String]? {
        get { value(for: .performers) }
        set { setExplicity(.performers, to: newValue) }
    }

    /// The people that are visible in an image or movie or are written about in a document.
    open var participants: [String]? { value(for: .participants) }

    // MARK: - Image

    /// The pixel height of the contents. For example, the height of a image or video.
    open var pixelHeight: Double? { value(for: .pixelHeight) }

    /// The pixel width of the contents. For example, the width of a image or video.
    open var pixelWidth: Double? { value(for: .pixelWidth) }

    /// The pixel size of the contents. For example, the image size or the video frame size.
    open var pixelSize: CGSize? {
        guard let width = pixelWidth, let height = pixelHeight else { return nil }
        return CGSize(width: width, height: height)
    }

    /// The total number of pixels in the contents. Same as `pixelHeight x pixelWidth`.
    open var pixelCount: Double? { value(for: .pixelCount) }

    /// The color space model used by the contents. For example: `RGB`, `CMYK`, `YUV`, or `YCbCr`.
    open var colorSpace: String? { value(for: .colorSpace) }

    /// The number of bits per sample. For example, the bit depth of an image (8-bit, 16-bit etc...) or the bit depth per audio sample of uncompressed audio data (8, 16, 24, 32, 64, etc..).
    open var bitsPerSample: Double? { value(for: .bitsPerSample) }

    /// A Boolean value that indicates whether a camera flash was used.
    open var isFlashOn: Bool? { value(for: .isFlashOn) }

    /// The actual focal length of the lens, in millimeters.
    open var focalLength: Double? { value(for: .focalLength) }

    /// The manufacturer of the device used for the contents. For example: `Apple`, `Canon`.
    open var deviceManufacturer: String? { value(for: .deviceManufacturer) }

    /// The model of the device used for the contents. For example: `iPhone 13`.
    open var deviceModel: String? { value(for: .deviceModel) }

    /// The ISO speed used to acquire the contents.
    open var isoSpeed: Double? { value(for: .isoSpeed) }

    /// The orientation of the contents.
    open var orientation: Orientation? { value(for: .orientation) }

    /// The names of the layers in the file.
    open var layerNames: [String]? {
        get { value(for: .layerNames) }
        set { setExplicity(.layerNames, to: newValue) }
    }

    /// The white balance setting of the camera when the picture was taken.
    open var whiteBalance: WhiteBalance? { value(for: .whiteBalance) }

    /// The aperture setting used to acquire the document contents. This unit is the APEX value.
    open var aperture: Double? { value(for: .aperture) }

    /// The name of the color profile used by the document contents.
    open var colorProfile: String? { value(for: .colorProfile) }

    /// The resolution width, in DPI, of the contents.
    open var dpiResolutionWidth: Double? { value(for: .dpiResolutionWidth) }

    /// The resolution height, in DPI, of the contents.
    open var dpiResolutionHeight: Double? { value(for: .dpiResolutionHeight) }

    /// The resolution size, in DPI, of the contents.
    open var dpiResolution: CGSize? {
        guard let width = dpiResolutionWidth, let height = dpiResolutionHeight else { return nil }
        return CGSize(width: width, height: height)
    }

    /// The exposure mode used to acquire the contents.
    open var exposureMode: ExposureMode? {
        ExposureMode(rawValue: value(for: .exposureMode) ?? -1)
    }

    /// The exposure time, in seconds, used to acquire the contents.
    open var exposureTimeSeconds: Double? { value(for: .exposureTimeSeconds) }

    /// The version of the EXIF header used to generate the metadata.
    open var exifVersion: String? { value(for: .exifVersion) }

    /// The name of the camera company.
    open var cameraOwner: String? { value(for: .cameraOwner) }

    /// The actual focal length of the lens, in 35 millimeters.
    open var focalLength35Mm: Double? { value(for: .focalLength35Mm) }

    /// The name of the camera lens model.
    open var lensModel: String? { value(for: .lensModel) }

    /// The direction of the item's image, in degrees from true north.
    open var imageDirection: Double? { value(for: .imageDirection) }

    /// A Boolean value that indicates whether the image has an alpha channel.
    open var hasAlphaChannel: Bool? { value(for: .hasAlphaChannel) }

    /// A Boolean value that indicates whether a red-eye reduction was used to take the picture.
    open var redEyeOnOff: Bool? { value(for: .redEyeOnOff) }

    /// The metering mode used to take the image.
    open var meteringMode: MeteringMode? { value(for: .meteringMode) }

    /// The smallest f-number of the lens. Ordinarily it is given in the range of 00.00 to 99.99.
    open var maxAperture: Double? { value(for: .maxAperture) }

    /// The diameter of the diaphragm aperture in terms of the effective focal length of the lens.
    open var fNumber: Double? { value(for: .fNumber) }

    /// The class of the exposure program used by the camera to set exposure when the image is taken. Possible values include: Manual, Normal, and Aperture priority.
    open var exposureProgram: String? { value(for: .exposureProgram) }

    /// The time of the exposure of the imge.
    open var exposureTimeString: String? { value(for: .exposureTimeString) }

    /// A Boolean value that indicates whether the file is a screen capture.
    open var isScreenCapture: Bool? { value(for: .isScreenCapture) }

    /// The screen capture type of the file.
    open var screenCaptureType: ScreenCaptureType? { value(for: .screenCaptureType) }

    /// The screen capture rect of the file.
    open var screenCaptureRect: CGRect? {
        guard let values: [Double] = value(for: .screenCaptureRect), values.count == 4 else { return nil }
        return CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
    }

    // MARK: - Messages / Mail

    /// The email addresses for the authors of this item.
    open var authorEmailAddresses: [String]? { value(for: .authorEmailAddresses) }

    /// The addresses for the authors of this item.
    open var authorAddresses: [String]? { value(for: .authorAddresses) }

    /// The recipients of this item.
    open var recipients: [String]? { value(for: .recipients) }

    /// The rmail addresses for the recipients of this item.
    open var recipientEmailAddresses: [String]? { value(for: .recipientEmailAddresses) }

    /// The addresses for the recipients of this item.
    open var recipientAddresses: [String]? { value(for: .recipientAddresses) }

    /// The instant message addresses related to this item.
    open var instantMessageAddresses: [String]? { value(for: .instantMessageAddresses) }

    /// The received dates for this item.
    open var receivedDates: [Date]? { value(for: .receivedDates) }

    /// The received recipients for this item.
    open var receivedRecipients: [String]? { value(for: .receivedRecipients) }

    /// Received recipient handles for this item.
    open var receivedRecipientHandles: [String]? { value(for: .receivedRecipientHandles) }

    /// The received sendesr for this item.
    open var receivedSenders: [String]? { value(for: .receivedSenders) }

    /// The received sender handles for this item.
    open var receivedSenderHandles: [String]? { value(for: .receivedSenderHandles) }

    /// The received types for this item.
    open var receivedTypes: [String]? { value(for: .receivedTypes) }

    /// A Boolean value that indicates whether the file is likely to be considered a junk file.
    open var isLikelyJunk: Bool? { value(for: .isLikelyJunk) }
    
    // MARK: - iCloud
    
    /// A Boolean indicating whether the item is stored in the cloud.
    open var isUbiquitousItem: Bool? {
        value(for: .isUbiquitousItem)
    }

    /// The name of the item’s container as the system displays it to users.
    open var ubiquitousItemContainerDisplayName: String? {
        value(for: .ubiquitousItemContainerDisplayName)
    }

    /// A Boolean value that indicates whether the user or the system requests a download of the item.
    open var ubiquitousItemDownloadRequested: Bool? {
        value(for: .ubiquitousItemDownloadRequested)
    }

    open var ubiquitousItemIsExternalDocument: Bool? {
        value(for: .ubiquitousItemIsExternalDocument)
    }

    open var ubiquitousItemURLInLocalContainer: URL? {
        value(for: .ubiquitousItemURLInLocalContainer)
    }

    /// A Boolean value that indicates whether the item has outstanding conflicts.
    open var ubiquitousItemHasUnresolvedConflicts: Bool? {
        value(for: .ubiquitousItemHasUnresolvedConflicts)
    }

    /// A Boolean value that indicates whether the item is present in the system.
    open var ubiquitousItemIsDownloaded: Bool? {
        value(for: .ubiquitousItemIsDownloaded)
    }

    /// A Boolean value that indicates whether the system is downloading the item.
    open var ubiquitousItemIsDownloading: Bool? {
        value(for: .ubiquitousItemIsDownloading)
    }

    /// A Boolean value that indicates whether data is present in the cloud for the item.
    open var ubiquitousItemIsUploaded: Bool? {
        value(for: .ubiquitousItemIsUploaded)
    }

    /// A Boolean value that indicates whether the system is uploading the item.
    open var ubiquitousItemIsUploading: Bool? {
        value(for: .ubiquitousItemIsUploading)
    }

    /// The percentage of the file that has already been downloaded from the cloud.
    open var ubiquitousItemPercentDownloaded: Double? {
        value(for: .ubiquitousItemPercentDownloaded)
    }

    /// The percentage of the file that has already been downloaded from the cloud.
    open var ubiquitousItemPercentUploaded: Double? {
        value(for: .ubiquitousItemPercentUploaded)
    }

    /// The download status of the item.
    open var ubiquitousItemDownloadingStatus: URLUbiquitousItemDownloadingStatus? {
        value(for: .ubiquitousItemDownloadingStatus)
    }

    /// The error when downloading the item from iCloud fails.
    open var ubiquitousItemDownloadingError: NSError? {
        value(for: .ubiquitousItemDownloadingError)
    }

    /// The error when uploading the item to iCloud fails.
    open var ubiquitousItemUploadingError: NSError? {
        value(for: .ubiquitousItemUploadingError)
    }

    /// A Boolean value that indicates a shared item.
    open var ubiquitousItemIsShared: Bool? {
        value(for: .ubiquitousItemIsShared)
    }

    /// The current user’s permissions for the shared item.
    open var ubiquitousSharedItemCurrentUserPermissions: URLUbiquitousSharedItemPermissions? {
        value(for: .ubiquitousSharedItemCurrentUserPermissions)
    }

    /// The current user’s role for the shared item.
    open var ubiquitousSharedItemCurrentUserRole: URLUbiquitousSharedItemRole? {
        value(for: .ubiquitousSharedItemCurrentUserRole)
    }

    /// The name components of the most recent editor of the shared item.
    open var ubiquitousSharedItemMostRecentEditorNameComponents: PersonNameComponents? {
        value(for: .ubiquitousSharedItemMostRecentEditorNameComponents)
    }

    /// The name components of the owner of the shared item.
    open var ubiquitousSharedItemOwnerNameComponents: PersonNameComponents? {
        value(for: .ubiquitousSharedItemOwnerNameComponents)
    }
    
    // MARK: - Query Content Relevance
    
    /**
     The relevance of the item's content, if it's part of a metadata query results that is sorted by this attribute.
     
     The relevance value is a value between `0.0` and `1.0`.
     
     It may not be computed if the item matches the query through evaluation of other attributes
     */
    open var queryContentRelevance: Double? { value(for: .queryContentRelevance) }
}

extension MetadataItem {
    /// A media type.
    public struct MediaType: ExpressibleByStringLiteral, RawRepresentable, CustomStringConvertible, Hashable {
        /// Sound.
        public static let sound = Self("Sound")
        /// Video.
        public static let video = Self("Video")
        /// Timecode.
        public static let timecode = Self("Timecode")
        /// MIDI.
        public static let midi = Self("MIDI")
        /// Text.
        public static let text = Self("Text")
        /**
         Indicates that Spotlight inferred the media type heuristically,
         such as from the file extension or other metadata, rather than
         from a definitive file content analysis.

         This value acts as a confidence hint, not a specific media type.
         */
        public static let hint = Self("hint")

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(stringLiteral value: String) {
            rawValue = value
        }
        
        public let rawValue: String
        
        public var description: String {
            rawValue
        }
    }
    
    /// The exposure mode of an image.
    public enum ExposureMode: Int, CustomStringConvertible, Hashable, QueryRawRepresentable {
        /// Automatic.
        case auto
        /// Manual.
        case manual
        /// Automatic bracket.
        case autoBracket
        
        public var description: String {
            switch self {
            case .auto: return "automatic"
            case .manual: return "manual"
            case .autoBracket: return "automaticBracket"
            }
        }
    }
    
    /// A media codec.
    public struct MediaCodec: ExpressibleByStringLiteral, RawRepresentable, CustomStringConvertible, Hashable {
        /// H.264 video codec.
        public static let h264 = Self("H.264")
        /// HEVC video codec.
        public static let hevc = Self("HEVC")
        /// AAC audio codec.
        public static let aac = Self("MPEG-4 AAC")
        /// AAC audio codec variant optimized for low-bitrate streaming.
        public static let aacHe = Self("MPEG-4 HE AAC")
        /// Subtitle track.
        public static let subtitle = Self("Subtitle")
        /// Track containing time information for syncing or reference.
        public static let timecode = Self("Timecode")
        /// Text based subtitle track.
        public static let quickTimeText = Self("QuickTime Text")
        /// Metadata track used for streaming optimization in QuickTime/MP4.
        public static let quickTimeHint = Self("Hint")

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(stringLiteral value: String) {
            rawValue = value
        }
        
        public let rawValue: String
        
        public var description: String {
            rawValue
        }
    }
    
    /// The orientation of a contents.
    public enum Orientation: Int, CustomStringConvertible, Hashable, QueryRawRepresentable {
        /// Horizontal orientation.
        case horizontal = 0
        /// Vertical orientation.
        case vertical = 1
        
        public var description: String {
            switch self {
            case .horizontal: return "Horizontal"
            case .vertical: return "Vertical"
            }
        }
    }
    
    /// The white balance setting of a camera.
    public enum WhiteBalance: Int, CustomStringConvertible, Hashable, QueryRawRepresentable {
        /// Automatic white balance.
        case auto = 0
        /// White balance is off.
        case off = 1
        
        public var description: String {
            switch self {
            case .auto: return "Auto"
            case .off: return "Off"
            }
        }
    }
    
    /// The metering mode used to take an image.
    public struct MeteringMode: RawRepresentable, ExpressibleByStringLiteral, Hashable, CustomStringConvertible {
        /// Average.
        public static let average = Self("Average")
        /// Center weighted average.
        public static let centerWeightedAverage = Self("CenterWeightedAverage")
        /// Spot.
        public static let spot = Self("Spot")
        /// Multi spot..
        public static let multiSpot = Self("MultiSpot")
        /// Pattern..
        public static let pattern = Self("Pattern")
        /// Partial..
        public static let partial = Self("Partial")
        /// Unknown.
        public static let unknown = Self("Unknown")
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(stringLiteral value: String) {
            self.rawValue = value
        }
        
        public let rawValue: String
        
        public var description: String {
            rawValue
        }
    }
    
    /// The screen capture type of a file.
    public enum ScreenCaptureType: String, CustomStringConvertible, QueryRawRepresentable {
        /// A screen capture of a display.
        case display
        /// a screen capture of a window.
        case window
        /// A screen capture of a selection.
        case selection
        
        public var description: String {
            switch self {
            case .display: return "display"
            case .window: return "window"
            case .selection: return "selection"
            }
        }
    }
}

extension MetadataItem {
    func value<T>(for attribute: String, save: Bool = false) -> T? {
        let value = values[attribute] as? T ?? item.value(forAttribute: attribute) as? T
        if save && values[attribute] == nil {
            values[attribute] = value
        }
        return value
    }
    
    func value<T>(for attribute: Attribute, save: Bool = false) -> T? {
        return value(for: attribute.rawValue)
    }
    
    func value<T: RawRepresentable>(for attribute: Attribute) -> T? {
        if let rawValue: T.RawValue = value(for: attribute.rawValue) {
            return T(rawValue: rawValue)
        }
        return nil
    }
    
    func getExplicity<T: RawRepresentable>(for attribute: Attribute) -> T? {
        url?.extendedAttributes["com.apple.metadata:\(attribute.rawValue)"]
    }
    
    func setExplicity<V, U: WritableKeyPath<URLResources, V?>>(_ attribute: Attribute, urlResources: U? = nil, to value: V?) {
        if let keyPath = urlResources, var resources = url?.resources {
            resources[keyPath: keyPath] = value
        } else {
            url?.extendedAttributes["com.apple.metadata:\(attribute.rawValue)"] = value
        }
    }
}
