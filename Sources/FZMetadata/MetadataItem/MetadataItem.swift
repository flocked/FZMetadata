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

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

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

 You either access the metadata by using a file url's ``Foundation/URL/metadata`` property or create it using ``init(url:)``.

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
open class MetadataItem {
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
    public var availableAttributes: [Attribute] {
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
     
     In the following example the query is gathering files and attributes. Because ``MetadataQuery/monitorResults`` is enabled, the handler is called subsequently whenever the available files or their attributes change.
               
     ```swift
     query,searchLocations = [folder]
     query.attributes = [.finderTags, .lastUsedDate]
     query.monitorResults = true
     query.resultsHandler = { items, _ in
        // Files with changed last usage date.
        let lastUsedFiles = items.filter({$0.updatedAttributes.contains(.lastUsedDate)})
     }
     query.start()
     ```
     */
    public var updatedAttributes: Set<Attribute> {
        Set(changes.changedAttributes)
    }
    
    /// A Boolean value indicating whether the specified attribute has changed between the current and previous item state.
    open func didUpdate(_ attribute: Attribute) -> Bool {
        changes.didChange(attribute)
    }
    
    /// Returns the current and previous value for the attribute at the specified key path, if it has changed.
    open func change<Value>(for keyPath: KeyPath<MetadataItem, Value>) -> (value: Value, previous: Value)? {
        changes.change(for: keyPath)
    }
    
    // MARK: - File

    /**
     The url of the file.
     
     - Note: The attribute can't be used in a metadata query predicate or to sort query results.
     */
    public var url: URL? {
        _url ?? self[.url]
    }
    
    private var _url: URL? {
        path.map({ .file($0) })
    }

    /**
     The full path of the file.
     
     - Note: The attribute can't be used in a metadata query predicate or to sort query results.
     */
    public var path: String? {
        filePathOperation?.cancel()
        if let filePath { return filePath }
        filePath = filePath ?? self[.path]
        return filePath
    }

    /// The name of the file including the extension.
    public var fileName: String? {
        _url?.lastPathComponent ?? self[.fileName]
    }

    /// The display name of the file, which may be different then the file system name.
    public var displayName: String? { self[.displayName] }

    /// The alternative names of the file.
    public var alternateNames: [String]? { self[.alternateNames] }

    /// The extension of the file.
    public var fileExtension: String? { url?.pathExtension }

    /// The size of the file.
    public var fileSize: DataSize? {
        guard let bytes: Int = self[.fileSize] else { return nil }
        return DataSize(bytes)
    }

    /// A Boolean value that indicates whether the file is invisible.
    public var fileIsInvisible: Bool? {
        get { self[.fileIsInvisible] }
        set {
            guard let newValue = newValue else { return }
            url?.resources.isHidden = newValue
        }
    }

    /// A Boolean value that indicates whether the file extension is hidden.
    public var fileExtensionIsHidden: Bool? {
        get { self[.fileExtensionIsHidden] }
        set {
            guard let newValue = newValue else { return }
            url?.resources.hasHiddenExtension = newValue
        }
    }

    /// The file type. For example: `video`, `document` or `directory`
    public var fileType: FileType? {
        guard let contentType = contentType else { return nil }
        return FileType(contentType: contentType)
    }
    
    public var contentType: UTType? {
        guard let type: String = self[.contentType] else { return nil }
        return UTType(type)
    }
    
    /// The content type tree of the file.
    public var contentTypeTree: [UTType]? {
        guard let contentTypeTree: [String] = self[.contentTypeTree] else { return nil }
        return contentTypeTree.compactMap { UTType($0) }
    }

    /// The content type identifier (`UTI`) of the file.
    var contentTypeIdentifier: String? { self[.contentType] }
    
    /// The content type tree identifiers (`UTI`) of the file.
    var contentTypeTreeIdentifiers: [String]? { self[.contentTypeTree] }

    /// The date the file was created on the file system.
    public var creationDate: Date? {
        get { self[.creationDate] }
        set { self[.creationDate, \.creationDate] = newValue }
    }
    
    /// The last date that the item's data on the file system was modified.
    public var modificationDate: Date? {
        get { self[.modificationDate] }
        set { self[.modificationDate] = newValue }
    }
    
    /// The date that the content of the file was created.
    public var contentCreationDate: Date? {
        get { self[.contentCreationDate] }
        set { self[.contentCreationDate] = newValue }
    }

    /// The last date that the content of the file was modified.
    public var contentModificationDate: Date? {
        get { self[.contentModificationDate] }
        set { self[.contentModificationDate, \.contentModificationDate] = newValue }
    }
    
    /// The last date that the attributes of the file were changed.
    public var attributeModificationDate: Date? {
        get { self[.attributeModificationDate] }
        set { self[.attributeModificationDate] = newValue }
    }

    /// The last date that the file was used.
    public var lastUsedDate: Date? {
        get { self[.lastUsedDate] }
        set { self[.lastUsedDate, \.contentAccessDate] = newValue }
    }

    /// The dates the file was last used.
    public var lastUsageDates: [Date]? {
        get { self[.lastUsageDates] }
        set { self[.lastUsageDates] = newValue }
    }

    /// The date the file was created, or renamed into or within its parent directory.
    public var addedDate: Date? {
        get { self[.addedDate] }
        set { self[.addedDate] = newValue }
    }

    /// The dates that the file was downloaded.
    public var downloadDates: [Date]? {
        get { self[.downloadDates] }
        set { self[.downloadDates] = newValue }
    }

    /// The date that the file was purchased.
    public var purchaseDate: Date? {
        get { self[.purchaseDate] }
        set { self[.purchaseDate] = newValue }
    }

    /// The date that this item is due (e.g. for a calendar event file).
    public var dueDate: Date? {
        get { self[.dueDate] }
        set { self[.dueDate] = newValue }
    }

    /// The number of files in a directory.
    public var directoryFilesCount: Int? { self[.directoryFilesCount] }

    ///  A description of the content of the item. The description may include an abstract, table of contents, reference to a graphical representation of content or a free-text account of the content.
    public var description: String? {
        get { self[.description] }
        set { self[.description] = newValue }
    }

    /// A description of the kind of item the file represents.
    public var kind: [String]? { self[.kind] }

    /// Information of this item.
    public var information: String? { 
        get { self[.information] }
        set { self[.information] = newValue }
    }

    /// The formal identifier used to reference the item within a given context.
    public var identifier: String? {
        get { self[.identifier] }
        set { self[.identifier] = newValue }
    }

    /// The keywords associated with the file. For example: `Birthday` or `Important`.
    public var keywords: [String]? { 
        get { self[.keywords] }
        set { self[.keywords] = newValue }
    }

    /// The title of the file. For example, this could be the title of a document, the name of a song, or the subject of an email message.
    public var title: String? { 
        get { self[.title] }
        set { self[.title] = newValue }
    }

    /// The title for a collection of media. This is analagous to a record album, or photo album.
    public var album: String? {
        get { self[.album] }
        set { self[.album] = newValue }
    }

    /// The authors, artists, etc. of the contents of the file.
    public var authors: [String]? {
        get { self[.authors] }
        set { self[.authors] = newValue }
    }

    /// The version of the file.
    public var version: String? {
        get { self[.version] }
        set { self[.version] = newValue }
    }

    /// A comment related to the file. This differs from ``finderComment``.
    public var comment: String? { 
        get { self[.comment] }
        set { self[.comment] = newValue }
    }

    /// The user rating of the file. For example, the stars rating of an iTunes track.
    public var starRating: Double? { 
        get { self[.starRating] }
        set { self[.starRating] = newValue }
    }

    /// A describes where the file was obtained from. For example download urls.
    public var whereFroms: [String]? {
        get { self[.whereFroms] }
        set { self[.whereFroms] = newValue }
    }

    /// The finder comment of the file. This differs from the ``comment``.
    public var finderComment: String? {
        get { self[.finderComment] }
        set { self[.finderComment] = newValue }
    }

    /// The finder tags of the file.
    public var finderTags: [String]? {
        get { self[.finderTags] ?? url?.resources.finderTagNames }
        set { url?.resources.finderTagNames = newValue ?? [] }
    }
    
    /// The primary (first) finder tag color.
    public var finderTagPrimaryColor: FinderTagColor? {
        self[.finderTagPrimaryColor]
    }

    /// A Boolean value that indicates whether the file has a custom icon.
    public var hasCustomIcon: Bool? { self[.hasCustomIcon] }

    /// The number of usages of the file.
    public var usageCount: Int? {
        guard let useCount: Int = self[.usageCount] else { return nil }
        return useCount - 2
    }

    /// The bundle identifier of this item. If this item is a bundle, then this is the `CFBundleIdentifier`.
    public var bundleIdentifier: String? { self[.bundleIdentifier] }

    /// The architectures this item requires to execute.
    public var executableArchitectures: [String]? { self[.executableArchitectures] }

    /// The platform this item requires to execute.
    public var executablePlatform: String? { self[.executablePlatform] }

    /// A Boolean value that indicates whether the file is owned and managed by an application.
    public var isApplicationManaged: Bool? { self[.isApplicationManaged] }

    /// The application used to convert the original content into it's current form. For example, a PDF file might have an encoding application set to "Distiller".
    public var encodingApplications: [String]? { self[.encodingApplications] }

    /// The categories the application is a member of.
    public var applicationCategories: [String]? { self[.applicationCategories] }

    /// The AppStore category of this item if it's an application from the AppStore.
    public var appstoreCategory: String? { self[.appstoreCategory] }

    /// The AppStore category type of this item if it's an application from the AppStore.
    public var appstoreCategoryType: String? { self[.appstoreCategoryType] }

    // MARK: - Document

    /// A text representation of the content of the document.
    public var textContent: String? { self[.textContent] }

    /// The subject of the this item
    public var subject: String? {
        get { self[.subject] }
        set { self[.subject] = newValue }
    }

    /// The theme of the this item.
    public var theme: String? {
        get { self[.theme] }
        set { self[.theme] = newValue }
    }

    /// A publishable summary of the contents of the item.
    public var headline: String? {
        get { self[.headline] }
        set { self[.headline] = newValue }
    }

    /// the application or operation system used to create the document content. For example: `Word`,  `Pages` or `16.2`.
    public var creator: String? {
        get { self[.creator] }
        set { self[.creator] = newValue }
    }

    /// Other information concerning this item, such as handling instructions.
    public var instructions: String? {
        get { self[.instructions] }
        set { self[.instructions] = newValue }
    }

    /// The editors of the contents of the file.
    public var editors: [String]? {
        get { self[.editors] }
        set { self[.editors] = newValue }
    }

    /// The audience for which the file is intended. The audience may be determined by the creator or the publisher or by a third party.
    public var audiences: [String]? {
        get { self[.audiences] }
        set { self[.audiences] = newValue }
    }

    /// The extent or scope of the content of the document.
    public var coverage: [String]? {
        get { self[.coverage] }
        set { self[.coverage] = newValue }
    }

    /// The list of projects that the file is part of. For example, if you were working on a movie all of the files could be marked as belonging to the project `My Movie`.
    public var projects: [String]? {
        get { self[.projects] }
        set { self[.projects] = newValue }
    }

    /// The number of pages in the document.
    public var numberOfPages: Int? {
        get { self[.numberOfPages] }
        set { self[.numberOfPages] = newValue }
    }

    /// The width of the document page, in points (72 points per inch). For PDF files this indicates the width of the first page only.
    public var pageWidth: Double? {
        get { self[.pageWidth] }
        set { self[.pageWidth] = newValue }
    }

    /// The height of the document page, in points (72 points per inch). For PDF files this indicates the height of the first page only.
    public var pageHeight: Double? {
        get { self[.pageHeight] }
        set { self[.pageHeight] = newValue }
    }

    /// The copyright owner of the file contents.
    public var copyright: String? {
        get { self[.copyright] }
        set { self[.copyright] = newValue }
    }

    /// The names of the fonts used in his document.
    public var fonts: [String]? {
        get { self[.fonts] }
        set { self[.fonts] = newValue }
    }

    /// The family name of the font used in this document.
    public var fontFamilyName: String? {
        get { self[.fontFamilyName] }
        set { self[.fontFamilyName] = newValue }
    }

    /// A list of contacts that are associated with this document, not including the authors.
    public var contactKeywords: [String]? {
        get { self[.contactKeywords] }
        set { self[.contactKeywords] = newValue }
    }

    /// The languages of the intellectual content of the resource.
    public var languages: [String]? {
        get { self[.languages] }
        set { self[.languages] = newValue }
    }

    /// A link to information about rights held in and over the resource.
    public var rights: String? {
        get { self[.rights] }
        set { self[.rights] = newValue }
    }

    /// The company or organization that created the document.
    public var organizations: [String]? {
        get { self[.organizations] }
        set { self[.organizations] = newValue }
    }

    /// The entity responsible for making this item available. For example, a person, an organization, or a service. Typically, the name of a publisher should be used to indicate the entity.
    public var publishers: [String]? {
        get { self[.publishers] }
        set { self[.publishers] = newValue }
    }

    /// The email Addresses related to this document.
    public var emailAddresses: [String]? {
        get { self[.emailAddresses] }
        set { self[.emailAddresses] = newValue }
    }

    /// The phone numbers related to this document.
    public var phoneNumbers: [String]? {
        get { self[.phoneNumbers] }
        set { self[.phoneNumbers] = newValue }
    }

    /// The people or organizations contributing to the content of the document.
    public var contributors: [String]? {
        get { self[.contributors] }
        set { self[.contributors] = newValue }
    }

    /// The security or encryption method used for the document.
    public var securityMethod: Double? { self[.securityMethod] }

    // MARK: - Places

    /// The full, publishable name of the country or region where the intellectual property of this item was created, according to guidelines of the provider.
    public var country: String? {
        get { self[.country] }
        set { self[.country] = newValue }
    }

    /// The city.of this document.
    public var city: String? {
        get { self[.city] }
        set { self[.city] = newValue }
    }

    /// The province or state of origin according to guidelines established by the provider. For example: `CA`, `Ontario` or `Sussex`.
    public var stateOrProvince: String? {
        get { self[.stateOrProvince] }
        set { self[.stateOrProvince] = newValue }
    }

    /// The area information of the file.
    public var areaInformation: String? {
        get { self[.areaInformation] }
        set { self[.areaInformation] = newValue }
    }

    /// The name of the location or point of interest associated with the
    public var namedLocation: String? {
        get { self[.namedLocation] }
        set { self[.namedLocation] = newValue }
    }

    /// The altitude of this item in meters above sea level, expressed using the WGS84 datum. Negative values lie below sea level.
    public var altitude: Double? {
        get { self[.altitude] }
        set { self[.altitude] = newValue }
    }

    /// The latitude of this item in degrees north of the equator, expressed using the WGS84 datum. Negative values lie south of the equator.
    public var latitude: Double? {
        get { self[.latitude] }
        set { self[.latitude] = newValue }
    }

    /// The longitude of this item in degrees east of the prime meridian, expressed using the WGS84 datum. Negative values lie west of the prime meridian.
    public var longitude: Double? {
        get { self[.longitude] }
        set { self[.longitude] = newValue }
    }

    /// The speed of this item, in kilometers per hour.
    public var speed: Double? {
        get { self[.speed] }
        set { self[.speed] = newValue }
    }

    /// The timestamp on the item  This generally is used to indicate the time at which the event captured by this item took place.
    public var timestamp: Date? {
        get { self[.timestamp] }
        set { self[.timestamp] = newValue }
    }

    /// The direction of travel of this item, in degrees from true north.
    public var gpsTrack: Double? {
        get { self[.gpsTrack] }
        set { self[.gpsTrack] = newValue }
    }

    /// The gps status of this item.
    public var gpsStatus: String? {
        get { self[.gpsStatus] }
        set { self[.gpsStatus] = newValue }
    }

    /// The gps measure mode of this item.
    public var gpsMeasureMode: String? {
        get { self[.gpsMeasureMode] }
        set { self[.gpsMeasureMode] = newValue }
    }

    /// The gps dop of this item.
    public var gpsDop: Double? {
        get { self[.gpsDop] }
        set { self[.gpsDop] = newValue }
    }

    /// The gps map datum of this item.
    public var gpsMapDatum: String? {
        get { self[.gpsMapDatum] }
        set { self[.gpsMapDatum] = newValue }
    }

    /// The gps destination latitude of this item.
    public var gpsDestLatitude: Double? {
        get { self[.gpsDestLatitude] }
        set { self[.gpsDestLatitude] = newValue }
    }

    /// The gps destination longitude of this item.
    public var gpsDestLongitude: Double? {
        get { self[.gpsDestLongitude] }
        set { self[.gpsDestLongitude] = newValue }
    }

    /// The gps destination bearing of this item.
    public var gpsDestBearing: Double? {
        get { self[.gpsDestBearing] }
        set { self[.gpsDestBearing] = newValue }
    }

    /// The gps destination distance of this item.
    public var gpsDestDistance: Double? {
        get { self[.gpsDestDistance] }
        set { self[.gpsDestDistance] = newValue }
    }

    /// The gps processing method of this item.
    public var gpsProcessingMethod: String? {
        get { self[.gpsProcessingMethod] }
        set { self[.gpsProcessingMethod] = newValue }
    }

    /// The gps date stamp of this item.
    public var gpsDateStamp: Date? {
        get { self[.gpsDateStamp] }
        set { self[.gpsDateStamp] = newValue }
    }

    /// The gps differental of this item.
    public var gpsDifferental: Double? {
        get { self[.gpsDifferental] }
        set { self[.gpsDifferental] = newValue }
    }

    // MARK: - Audio

    /// The sample rate of the audio data contained in the file. The sample rate representing `audio_frames/second`. For example: `44100.0`, `22254.54`.
    public var audioSampleRate: Double? { self[.audioSampleRate] }

    /// The number of channels in the audio data contained in the file.
    public var audioChannelCount: Int? { self[.audioChannelCount] }

    /// The name of the application that encoded the data of a audio file.
    public var audioEncodingApplication: String? {
        get { self[.audioEncodingApplication] }
        set { self[.audioEncodingApplication] = newValue }
    }

    /// The tempo that specifies the beats per minute of the music contained in the audio file.
    public var tempo: Double? {
        get { self[.tempo] }
        set { self[.tempo] = newValue }
    }

    /// The key of the music contained in the audio file. For example: `C`, `Dm`, `F#, `Bb`.
    public var keySignature: String? {
        get { self[.keySignature] }
        set { self[.keySignature] = newValue }
    }

    /// The time signature of the musical composition contained in the audio/MIDI file. For example: `4/4`, `7/8`.
    public var timeSignature: String? {
        get { self[.timeSignature] }
        set { self[.timeSignature] = newValue }
    }

    /// The track number of a song or composition when it is part of an album.
    public var trackNumber: Int? {
        get { self[.trackNumber] }
        set { self[.trackNumber] = newValue }
    }

    /// The composer of the music contained in the audio file.
    public var composer: String? {
        get { self[.composer] }
        set { self[.composer] = newValue }
    }

    /// The lyricist, or text writer, of the music contained in the audio file.
    public var lyricist: String? {
        get { self[.lyricist] }
        set { self[.lyricist] = newValue }
    }

    /// The recording date of the song or composition.
    public var recordingDate: Date? {
        get { self[.recordingDate] }
        set { self[.recordingDate] = newValue }
    }

    /// Indicates the year this item was recorded. For example: `1964`, `2003`.
    public var recordingYear: Double? {
        get { self[.recordingYear] }
        set { self[.recordingYear] = newValue }
    }

    /// The musical genre of the song or composition contained in the audio file. For example: `Jazz`, `Pop`, `Rock`, `Classical`.
    public var musicalGenre: String? {
        get { self[.musicalGenre] }
        set { self[.musicalGenre] = newValue }
    }

    /// A Boolean value that indicates whether the MIDI sequence contained in the file is setup for use with a General MIDI device.
    public var isGeneralMidiSequence: Bool? { self[.isGeneralMidiSequence] }

    /// The original key of an Apple loop. The key is the root note or tonic for the loop, and does not include the scale type.
    public var appleLoopsRootKey: String? { self[.appleLoopsRootKey] }

    /// The key filtering information of an Apple loop. Loops are matched against projects that often in a major or minor key.
    public var appleLoopsKeyFilterType: String? { self[.appleLoopsKeyFilterType] }

    /// The looping mode of an Apple loop.
    public var appleLoopsLoopMode: String? { self[.appleLoopsLoopMode] }

    /// The escriptive information of an Apple loop.
    public var appleLoopDescriptors: [String]? { self[.appleLoopDescriptors] }

    /// The category of the instrument.
    public var musicalInstrumentCategory: String? { self[.musicalInstrumentCategory] }

    /// The name of the instrument relative to the instrument category.
    public var musicalInstrumentName: String? { self[.musicalInstrumentName] }

    // MARK: - Media

    /// The duration of the content of file. Usually for videos and audio.
    public var duration: TimeDuration? {
        if let durationSeconds: Double = self[.duration] {
            return TimeDuration(durationSeconds)
        }
        return nil
    }

    /// The media types (video, sound) present in the content.
    public var mediaTypes: [String]? { self[.mediaTypes] }

    /// The codecs used to encode/decode the media.
    public var codecs: [String]? { self[.codecs] }

    /// The total bit rate, audio and video combined, of the media.
    public var totalBitRate: Double? { self[.totalBitRate] }

    /// The video bit rate of the media.
    public var videoBitRate: Double? { self[.videoBitRate] }

    /// The audio bit rate of the media.
    public var audioBitRate: Double? { self[.audioBitRate] }

    /// A Boolean value that indicates whether the media is prepared for streaming.
    public var streamable: Bool? { self[.streamable] }

    /// The delivery type of the media. Either `Fast start` or `RTSP`.
    public var mediaDeliveryType: String? { self[.mediaDeliveryType] }

    /// Original format of the media.
    public var originalFormat: String? { self[.originalFormat] }

    /// Original source of the media.
    public var originalSource: String? {
        get { self[.originalSource] }
        set { self[.originalSource] = newValue }
    }

    /// The genre of the content.
    public var genre: String? {
        get { self[.genre] }
        set { self[.genre] = newValue }
    }

    /// The director of the content.
    public var director: String? {
        get { self[.director] }
        set { self[.director] = newValue }
    }

    /// The producer of the content.
    public var producer: String? {
        get { self[.producer] }
        set { self[.producer] = newValue }
    }

    /// The performers of the content.
    public var performers: [String]? {
        get { self[.performers] }
        set { self[.performers] = newValue }
    }

    /// The people that are visible in an image or movie or are written about in a document.
    public var participants: [String]? {
        get { self[.participants] }
        set { self[.participants] = newValue }
    }

    // MARK: - Image

    /// The pixel height of the contents. For example, the height of a image or video.
    public var pixelHeight: Double? { self[.pixelHeight] }

    /// The pixel width of the contents. For example, the width of a image or video.
    public var pixelWidth: Double? { self[.pixelWidth] }

    /// The pixel size of the contents. For example, the image size or the video frame size.
    public var pixelSize: CGSize? {
        guard let width = pixelWidth, let height = pixelHeight else { return nil }
        return CGSize(width: width, height: height)
    }

    /// The total number of pixels in the contents. Same as `pixelHeight x pixelWidth`.
    public var pixelCount: Double? { self[.pixelCount] }

    /// The color space model used by the contents. For example: `RGB`, `CMYK`, `YUV`, or `YCbCr`.
    public var colorSpace: String? { self[.colorSpace] }

    /// The number of bits per sample. For example, the bit depth of an image (8-bit, 16-bit etc...) or the bit depth per audio sample of uncompressed audio data (8, 16, 24, 32, 64, etc..).
    public var bitsPerSample: Double? { self[.bitsPerSample] }

    /// A Boolean value that indicates whether a camera flash was used.
    public var isFlashOn: Bool?  {
        get { self[.isFlashOn] }
        set { self[.isFlashOn] = newValue }
    }

    /// The actual focal length of the lens, in millimeters.
    public var focalLength: Double?  {
        get { self[.focalLength] }
        set { self[.focalLength] = newValue }
    }

    /// The manufacturer of the device used for the contents. For example: `Apple`, `Canon`.
    public var deviceManufacturer: String?  {
        get { self[.deviceManufacturer] }
        set { self[.deviceManufacturer] = newValue }
    }

    /// The model of the device used for the contents. For example: `iPhone 13`.
    public var deviceModel: String?  {
        get { self[.deviceModel] }
        set { self[.deviceModel] = newValue }
    }

    /// The ISO speed used to acquire the contents.
    public var isoSpeed: Double?  {
        get { self[.isoSpeed] }
        set { self[.isoSpeed] = newValue }
    }

    /// The orientation of the contents.
    public var orientation: Orientation? { self[.orientation] }

    /// The orientation of a contents.
    public enum Orientation: Int, QueryRawRepresentable, CustomStringConvertible {
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

    /// The names of the layers in the file.
    public var layerNames: [String]? { self[.layerNames] }

    /// The white balance setting of the camera when the picture was taken.
    public var whiteBalance: WhiteBalance? { self[.whiteBalance] }

    /// The white balance setting of a camera.
    public enum WhiteBalance: Int, QueryRawRepresentable, CustomStringConvertible {
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

    /// The aperture setting used to acquire the document contents. This unit is the APEX value.
    public var aperture: Double? { self[.aperture] }

    /// The name of the color profile used by the document contents.
    public var colorProfile: String? { self[.colorProfile] }

    /// The resolution width, in DPI, of the contents.
    public var dpiResolutionWidth: Double? { self[.dpiResolutionWidth] }

    /// The resolution height, in DPI, of the contents.
    public var dpiResolutionHeight: Double? { self[.dpiResolutionHeight] }

    /// The resolution size, in DPI, of the contents.
    public var dpiResolution: CGSize? {
        guard let width = dpiResolutionWidth, let height = dpiResolutionHeight else { return nil }
        return CGSize(width: width, height: height)
    }

    /// The exposure mode used to acquire the contents.
    public var exposureMode: Double? {
        get { self[.exposureMode] }
        set { self[.exposureMode] = newValue }
    }

    /// The exposure time, in seconds, used to acquire the contents.
    public var exposureTimeSeconds: Double? {
        get { self[.exposureTimeSeconds] }
        set { self[.exposureTimeSeconds] = newValue }
    }

    /// The version of the EXIF header used to generate the metadata.
    public var exifVersion: String? {
        get { self[.exifVersion] }
        set { self[.exifVersion] = newValue }
    }

    /// The name of the camera company.
    public var cameraOwner: String? {
        get { self[.cameraOwner] }
        set { self[.cameraOwner] = newValue }
    }

    /// The actual focal length of the lens, in 35 millimeters.
    public var focalLength35Mm: Double? {
        get { self[.focalLength35Mm] }
        set { self[.focalLength35Mm] = newValue }
    }

    /// The name of the camera lens model.
    public var lensModel: String? {
        get { self[.lensModel] }
        set { self[.lensModel] = newValue }
    }

    /// The direction of the item's image, in degrees from true north.
    public var imageDirection: Double? { self[.imageDirection] }

    /// A Boolean value that indicates whether the image has an alpha channel.
    public var hasAlphaChannel: Bool? { self[.hasAlphaChannel] }

    /// A Boolean value that indicates whether a red-eye reduction was used to take the picture.
    public var redEyeOnOff: Bool? {
        get { self[.redEyeOnOff] }
        set { self[.redEyeOnOff] = newValue }
    }

    /// The metering mode used to take the image.
    public var meteringMode: String? {
        get { self[.meteringMode] }
        set { self[.meteringMode] = newValue }
    }

    /// The smallest f-number of the lens. Ordinarily it is given in the range of 00.00 to 99.99.
    public var maxAperture: Double? {
        get { self[.maxAperture] }
        set { self[.maxAperture] = newValue }
    }

    /// The diameter of the diaphragm aperture in terms of the effective focal length of the lens.
    public var fNumber: Double? {
        get { self[.fNumber] }
        set { self[.fNumber] = newValue }
    }

    /// The class of the exposure program used by the camera to set exposure when the image is taken. Possible values include: Manual, Normal, and Aperture priority.
    public var exposureProgram: String? {
        get { self[.exposureProgram] }
        set { self[.exposureProgram] = newValue }
    }

    /// The time of the exposure of the imge.
    public var exposureTimeString: String? {
        get { self[.exposureTimeString] }
        set { self[.exposureTimeString] = newValue }
    }

    /// A Boolean value that indicates whether the file is a screen capture.
    public var isScreenCapture: Bool? { self[.isScreenCapture] }

    /// The screen capture type of the file.
    public var screenCaptureType: ScreenCaptureType? { self[.screenCaptureType] }

    /// The screen capture type of a file.
    public enum ScreenCaptureType: String, QueryRawRepresentable, CustomStringConvertible {
        /// A screen capture of a display.
        case display

        /// a screen capture of a window.
        case window

        /// A screen capture of a selection.
        case selection
        
        public var description: String {
            switch self {
            case .display: return "Display"
            case .window: return "Window"
            case .selection: return "Selection"
            }
        }
    }

    /// The screen capture rect of the file.
    public var screenCaptureRect: CGRect? {
        guard let values: [Double] = self[.screenCaptureRect] else { return nil }
        return CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
    }

    // MARK: - Messages / Mail

    /// The email addresses for the authors of this item.
    public var authorEmailAddresses: [String]? { self[.authorEmailAddresses] }

    /// The addresses for the authors of this item.
    public var authorAddresses: [String]? { self[.authorAddresses] }

    /// The recipients of this item.
    public var recipients: [String]? { self[.recipients] }

    /// The rmail addresses for the recipients of this item.
    public var recipientEmailAddresses: [String]? { self[.recipientEmailAddresses] }

    /// The addresses for the recipients of this item.
    public var recipientAddresses: [String]? { self[.recipientAddresses] }

    /// The instant message addresses related to this item.
    public var instantMessageAddresses: [String]? { self[.instantMessageAddresses] }

    /// The received dates for this item.
    public var receivedDates: [Date]? { self[.receivedDates] }

    /// The received recipients for this item.
    public var receivedRecipients: [String]? { self[.receivedRecipients] }

    /// Received recipient handles for this item.
    public var receivedRecipientHandles: [String]? { self[.receivedRecipientHandles] }

    /// The received sendesr for this item.
    public var receivedSenders: [String]? { self[.receivedSenders] }

    /// The received sender handles for this item.
    public var receivedSenderHandles: [String]? { self[.receivedSenderHandles] }

    /// The received types for this item.
    public var receivedTypes: [String]? { self[.receivedTypes] }

    /// A Boolean value that indicates whether the file is likely to be considered a junk file.
    public var isLikelyJunk: Bool? { self[.isLikelyJunk] }
    
    // MARK: - iCloud
    
    /// A Boolean indicating whether the item is stored in the cloud.
    public var isUbiquitousItem: Bool? {
        self[.isUbiquitousItem]
    }

    /// The name of the item’s container as the system displays it to users.
    public var ubiquitousItemContainerDisplayName: String? {
        self[.ubiquitousItemContainerDisplayName]
    }

    /// A Boolean value that indicates whether the user or the system requests a download of the item.
    public var ubiquitousItemDownloadRequested: Bool? {
        self[.ubiquitousItemDownloadRequested]
    }

    public var ubiquitousItemIsExternalDocument: Bool? {
        self[.ubiquitousItemIsExternalDocument]
    }

    public var ubiquitousItemURLInLocalContainer: URL? {
        self[.ubiquitousItemURLInLocalContainer]
    }

    /// A Boolean value that indicates whether the item has outstanding conflicts.
    public var ubiquitousItemHasUnresolvedConflicts: Bool? {
        self[.ubiquitousItemHasUnresolvedConflicts]
    }

    /// A Boolean value that indicates whether the item is present in the system.
    public var ubiquitousItemIsDownloaded: Bool? {
        self[.ubiquitousItemIsDownloaded]
    }

    /// A Boolean value that indicates whether the system is downloading the item.
    public var ubiquitousItemIsDownloading: Bool? {
        self[.ubiquitousItemIsDownloading]
    }

    /// A Boolean value that indicates whether data is present in the cloud for the item.
    public var ubiquitousItemIsUploaded: Bool? {
        self[.ubiquitousItemIsUploaded]
    }

    /// A Boolean value that indicates whether the system is uploading the item.
    public var ubiquitousItemIsUploading: Bool? {
        self[.ubiquitousItemIsUploading]
    }

    /// The percentage of the file that has already been downloaded from the cloud.
    public var ubiquitousItemPercentDownloaded: Double? {
        self[.ubiquitousItemPercentDownloaded]
    }

    /// The percentage of the file that has already been downloaded from the cloud.
    public var ubiquitousItemPercentUploaded: Double? {
        self[.ubiquitousItemPercentUploaded]
    }

    /// The download status of the item.
    public var ubiquitousItemDownloadingStatus: URLUbiquitousItemDownloadingStatus? {
        self[.ubiquitousItemDownloadingStatus]
    }

    /// The error when downloading the item from iCloud fails.
    public var ubiquitousItemDownloadingError: NSError? {
        self[.ubiquitousItemDownloadingError]
    }

    /// The error when uploading the item to iCloud fails.
    public var ubiquitousItemUploadingError: NSError? {
        self[.ubiquitousItemUploadingError]
    }

    /// A Boolean value that indicates a shared item.
    public var ubiquitousItemIsShared: Bool? {
        self[.ubiquitousItemIsShared]
    }

    /// The current user’s permissions for the shared item.
    public var ubiquitousSharedItemCurrentUserPermissions: URLUbiquitousSharedItemPermissions? {
        self[.ubiquitousSharedItemCurrentUserPermissions]
    }

    /// The current user’s role for the shared item.
    public var ubiquitousSharedItemCurrentUserRole: URLUbiquitousSharedItemRole? {
        self[.ubiquitousSharedItemCurrentUserRole]
    }

    /// The name components of the most recent editor of the shared item.
    public var ubiquitousSharedItemMostRecentEditorNameComponents: PersonNameComponents? {
        self[.ubiquitousSharedItemMostRecentEditorNameComponents]
    }

    /// The name components of the owner of the shared item.
    public var ubiquitousSharedItemOwnerNameComponents: PersonNameComponents? {
        self[.ubiquitousSharedItemOwnerNameComponents]
    }
    
    // MARK: - Query Content Relevance
    
    /**
     The relevance of the item's content, if it's part of a metadata query results that is sorted by this attribute.
     
     The relevance value is a value between `0.0` and `1.0`.
     
     It may not be computed if the item matches the query through evaluation of other attributes
     */
    public var queryContentRelevance: Double? { self[.queryContentRelevance] }
}

extension MetadataItem {
    private func value<T>(for attribute: String) -> T? {
        values[attribute] as? T ?? item.value(forAttribute: attribute) as? T
    }
    
    subscript<T>(attribute: Attribute) -> T? {
        value(for: attribute.rawValue)
    }
    
    subscript<T: RawRepresentable>(attribute: Attribute) -> T? {
        guard let rawValue: T.RawValue = value(for: attribute.rawValue) else { return nil }
        return T(rawValue: rawValue)
    }
    
    subscript<V, U: WritableKeyPath<URLResources, V?>>(attribute: Attribute, urlResources: U? = nil) -> V? where V: Codable {
        get { value(for: attribute.rawValue) }
        set {
            if let keyPath = urlResources, var resources = url?.resources {
                resources[keyPath: keyPath] = newValue
            } else {
                url?.extendedAttributes["com.apple.metadata:\(attribute.rawValue)", .propertyList, flags: [.syncable, .noExport]] = newValue
            }
        }
    }
}

extension MetadataItem: Hashable {
    public static func == (lhs: MetadataItem, rhs: MetadataItem) -> Bool {
        lhs.item === rhs.item
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(item.objectID)
    }
}
