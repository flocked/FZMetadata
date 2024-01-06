//
//  MetadataItem.swift
//
//
//  Created by Florian Zand on 28.08.22.
//

import Foundation
import FZSwiftUtils

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

#if os(macOS)
public extension URL {
    /// Metadata for the url. Some of the metadata can also be changed.
    var metadata: MetadataItem? {
        return MetadataItem(url: self)  }
}
#endif

/**
 The metadata associated with a file.

 Some of the metadata can also be changed.
 ```swift
 if let metadata = MetadataItem(url: fileURL) {
    metadata.creationDate // The creation date of the file
    metadata.contentModificationDate = Date()
 }
 ```
 */
public class MetadataItem {
    let item: NSMetadataItem
    var values: [String:Any] = [:]
    
    /**
     Initializes a metadata item with a given NSMetadataItem.
     
     - Parameters:
        - item: The NSMetadataItem.

     - Returns: A metadata 
     */
    public init(item: NSMetadataItem) {
        self.item = item
        values = [:]
    }
    
#if os(macOS)
    /**
     Initializes a metadata item with a given URL.
     
     - Parameters:
        - url: The URL for the metadata 

     - Returns: A metadata item for the file identified by url.
     */
    public init?(url: URL) {
        if let item = NSMetadataItem(url: url) {
            self.item = item
            var values: [String:Any] = [:]
            values[NSMetadataItemURLKey] = url
            self.values = values
        } else {
            return nil
        }
    }
    
    init?(url: URL, values: [String:Any]? = nil) {
        if let item = NSMetadataItem(url: url) {
            self.item = item
            var values = values ?? [:]
            values[NSMetadataItemURLKey] = url
            self.values = values
        } else {
            return nil
        }
    }
#endif
    
    /**
     An array containing the attributes for the metadata item’s values.

     - Returns: This property contains an array of attributes, representing the values available from this metadata  For a list of possible keys, see Attributes.
     */
    public var availableAttributes: [Attribute] {
        let attributes = (values.keys + item.attributes).uniqued().sorted()
        return attributes.compactMap({Attribute(rawValue: $0)})
    }
    
    func value<T>(for attribute: String) -> T? {
        if let value = values[attribute] as? T {
            return value
        } else if let value: T = item.value(for: attribute) {
            return value
        }
        return nil
    }
    
    func value<T: RawRepresentable, K: KeyPath<MetadataItem, T?>>(_ keyPath: K) -> T? {
        if let rawValue: T.RawValue = value(for: keyPath.mdItemKey) {
           return T(rawValue: rawValue)
        }
        return getExplicity(keyPath)
    }
    
    func value<T, K: KeyPath<MetadataItem, T?>>(for keyPath: K) -> T? {
        if let value: T = value(for: keyPath.mdItemKey) {
           return value
        }
        return getExplicity(keyPath)
    }
    
    // MARK: - File
    
    /// The url of the 
    public var url: URL? {
        if let path = values["kMDItemPath"] as? String {
            return URL(fileURLWithPath: path)
        }
        return value(for: \.url)
    }
    
    /// The full path to the file.
    public var path: String? {
        get { value(for: \.path) } }
    
    /// The file name of the item including extension.
    public var fileName: String? {
        get { 
            if let path = values["kMDItemPath"] as? String {
                return URL(fileURLWithPath: path).lastPathComponent
            }
            return value(for: \.fileName) ?? url?.lastPathComponent } }
    
    /// The display name of the item, which may be different then the file system name.
    public var displayName: String? {
        get { value(for: \.displayName) } }
    
    /// Alternative names of the 
    public var alternateNames: [String]? {
        get { value(for: \.alternateNames) } }
    
    /// The extension of the file.
    public var fileExtension: String? {
        get { url?.pathExtension } }
    
    /// The size of of the file in bytes.
    var fileSizeBytes: Int? {
        get { value(for: \.fileSizeBytes) } }
    
    /// The size of of the file as `DataSize`.
    public var fileSize: DataSize? {
        if let bytes = fileSizeBytes {
            return DataSize(bytes)
        }
        return nil
    }
    
    /// Indicates whether the file is invisible.
    public var fileIsInvisible: Bool? {
        get { value(for: \.fileIsInvisible) } }
    
    /// Indicates whether the file is invisible.
    public var fileExtensionIsHidden: Bool? {
        get { value(for: \.fileExtensionIsHidden) } }
    
    /// The type of the file.
    public var fileType: FileType? {
        get {  if let contentTypeTree: [String] = value(for: \.contentTypeTree) {
            return FileType(contentTypeTree: contentTypeTree)
        }
            return nil
        }
    }
          
    /// The content type of the file as UTI identifier.
    public var contentType: String? {
        get { value(for: \.contentType) } }
    
    /// An array of UTI identifiers representing the content type tree of the file.
    public var contentTypeTree: [String]? {
        get { value(for: \.contentTypeTree) } }
    
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)
    /// The content type of the file as UTType.
    public var contentUTType: UTType? {
        get { if let type = contentType { return UTType(type) }
                return nil } }
    
    /// The date and time that the file was created.
    public var creationDate: Date? {
        get { value(for: \.creationDate) }
        set { setExplicity(\.creationDate, to: newValue) } }
        
    /// The date and time that the file was last used.
    public var lastUsedDate: Date? {
        get { value(for: \.lastUsedDate) }
        set { setExplicity(\.lastUsedDate, to: newValue) } }
        
    /// An array of dates and times the file was last used.
    public var lastUsageDates: [Date]? {
        get { value(for: \.lastUsageDates) }
        set { setExplicity(\.lastUsageDates, to: newValue) } }
    
    /// The date when the metadata last changed.
    public var metadataModificationDate: Date? {
        get { value(for: \.metadataModificationDate) }
        set { setExplicity(\.metadataModificationDate, to: newValue) } }
    
    /// The date and time that the content of the file was created.
    public var contentCreationDate: Date? {
        get { value(for: \.contentCreationDate) }
        set { setExplicity(\.contentCreationDate, to: newValue) } }
    
    /// The date the file contents last changed.
    public var contentChangeDate: Date? {
        get { value(for: \.contentChangeDate) }
        set { setExplicity(\.contentChangeDate, to: newValue) } }
    
    /// The date and time that the contents of the file were last modified.
    public var contentModificationDate: Date? {
        get { value(for: \.contentModificationDate) }
        set { setExplicity(\.contentModificationDate, to: newValue) } }
    
    /// The date when the file got added of the file.
    public var dateAdded: Date? {
        get { value(for: \.dateAdded) }
        set { setExplicity(\.dateAdded, to: newValue) } }
    
    /// The download date of the file.
    public var downloadedDate: Date? {
        get { value(for: \.downloadedDate) }
        set { setExplicity(\.downloadedDate, to: newValue) }
    }
    
    /// The purchase date of the file.
    public var purchaseDate: Date? {
        get { value(for: \.purchaseDate) }
    }
    
    /// Date this item is due (e.g. for a calendar event file).
    public var dueDate: Date? {
        get { value(for: \.dueDate) }
        set { setExplicity(\.dueDate, to: newValue) } }
    
    /// Number of files in a directory.
    public var directoryFilesCount: Int? {
        get { value(for: \.directoryFilesCount) } }
    
    ///  A description of the content of the resource. The description may include an abstract, table of contents, reference to a graphical representation of content or a free-text account of the content.
    public var description: String? {
        get { value(for: \.description) } }
    
    // A description of the kind of item this file represents.
    public var kind: [String]? {
        get { value(for: \.kind) } }
    
    /// Information about the 
    public var information: String? {
        get { value(for: \.information) } }
    
    /// A formal identifier used to reference the resource within a given context.
    public var identifier: String? {
        get { value(for: \.identifier) } }
    
    /// Keywords associated with this file. For example, “Birthday”, “Important”, etc.
    public var keywords: [String]? {
        get { value(for: \.keywords) } }
    
    /// The title of the file. For example, this could be the title of a document, the name of a song, or the subject of an email message.
    public var title: String? {
        get { value(for: \.title) } }
    
    /// The title for a collection of media. This is analagous to a record album, or photo album.
    public var album: String? {
        get { value(for: \.album) } }
    
    /// Authors, Artists, etc. of the contents of the file.
    public var authors: [String]? {
        get { value(for: \.authors) } }
    
    /// The version number of this file.
    public var version: String? {
        get { value(for: \.version) } }
    
    /// A comment related to the file. This differs from the Finder comment, finderComment.
    public var comment: String? {
        get { value(for: \.comment) } }
    
    /// User rating of this  For example, the stars rating of an iTunes track.
    public var starRating: Double? {
        get { value(for: \.starRating) } }
    
    /// Describes where the file was obtained from. For example download urls.
    public var whereFroms: [String]? {
        get { value(for: \.whereFroms) }
        set { setExplicity(\.whereFroms, to: newValue) }
    }
    
    /// Finder comments for this file. This differs from the file comment, comment.
    public var finderComment: String? {
        get { value(for: \.finderComment) } }
    
    /// Finder tags for this file.
    public var finderTags: [String]? {
        get { value(for: \.finderTags)?.compactMap({$0.replacingOccurrences(of: "\n6", with:"")}) }
        set { 
            #if os(macOS)
            if let url = url {
                url.resources.tags = newValue ?? []
            } else {
                setExplicity(\.finderTags, to: newValue?.compactMap({$0 + "\n6"}))
            }
            #else
            setExplicity(\.finderTags, to: newValue?.compactMap({$0 + "\n6"}))
            #endif
        }
    }
    
    var finderPrimaryTagColorIndex: Int? {
        get { value(for: \.finderPrimaryTagColorIndex) } }
    
    /// First finder tag color of the item.
    public var finderPrimaryTagColor: FinderTag.Color? {
        get {
            if let rawValue: Int = finderPrimaryTagColorIndex {
            return FinderTag.Color(rawValue: rawValue)
        }
            return nil
        }
    }
    
    /// Indicates whether the file is invisible.
    public var hasCustomIcon: Bool? {
        get { value(for: \.hasCustomIcon) } }
    
    /// The usage count of the file.
    public var usageCount: Int? {
        get { if let useCount = value(for: \.usageCount) {
            return useCount - 2
        }
            return nil
        } }
    
    /// If this item is a bundle, then this is the CFBundleIdentifier.
    public var bundleIdentifier: String? {
        get { value(for: \.bundleIdentifier) } }
    
    // Architectures the item requires to execute;architectures
    public var executableArchitectures: [String]? {
        get { value(for: \.executableArchitectures) } }
    
    // Platform the item requires to execute;platform
    public var executablePlatform: String? {
        get { value(for: \.executablePlatform) } }
    
    // Indicates whether the file is owned and managed by an application.
    public var isApplicationManaged: Bool? {
        get { value(for: \.isApplicationManaged) } }
    
    /// Application used to convert the original content into it's current form. For example, a PDF file might have an encoding application set to "Distiller".
    public var encodingApplications: [String]? {
        get { value(for: \.encodingApplications) } }
    
    // Categories application is a member of.
    public var applicationCategories: [String]? {
        get { value(for: \.applicationCategories) } }
        
    /// The AppStore category of the item if it's an application from the AppStore.
    public var appstoreCategory: String? {
        get { value(for: \.appstoreCategory) } }
    
    /// The AppStore category type of the item if it's an application from the AppStore.
    public var appstoreCategoryType: String? {
        get { value(for: \.appstoreCategoryType) } }
    
    // MARK: - Person / Contact

    
    // MARK: - Document
    
    /// Contains a text representation of the content of the document. Data in multiple fields should be combined using a whitespace character as a separator.
    public var textContent: String? {
        get { value(for: \.textContent) } }
    
    /// Subject of the this 
    public var subject: String? {
        get { value(for: \.subject) } }
    
    /// Theme of the this 
    public var theme: String? {
        get { value(for: \.theme) } }
    
    /// Publishable summary of the contents of the 
    public var headline: String? {
        get { value(for: \.headline) } }
    
    /// Application or operation system used to create the document content (e.g.  "Word",  "Pages", 16.2, and so on).
    public var creator: String? {
        get { value(for: \.creator) } }
    
    /// Other information concerning the item, such as handling instructions.
    public var instructions: String? {
        get { value(for: \.instructions) } }
    
    /// Editors of the contents of the file.
    public var editors: [String]? {
        get { value(for: \.editors) } }
    
    /// The audience for which the file is intended. The audience may be determined by the creator or the publisher or by a third party.
    public var audiences: [String]? {
        get { value(for: \.audiences) } }
    
    /// Extent or scope of the content of the document.
    public var coverage: [String]? {
        get { value(for: \.coverage) } }
            
    /// The list of projects that this file is part of. For example, if you were working on a movie all of the files could be marked as belonging to the project “My Movie”.
    public var projects: [String]? {
        get { value(for: \.projects) } }
    
    /// Number of pages in the document.
    public var numberOfPages: Double? {
        get { value(for: \.numberOfPages) } }
    
    /// Width of the document page, in points (72 points per inch). For PDF files this indicates the width of the first page only.
    public var pageWidth: Double? {
        get { value(for: \.pageWidth) } }
    
    /// Height of the document page, in points (72 points per inch). For PDF files this indicates the height of the first page only.
    public var pageHeight: Double? {
        get { value(for: \.pageHeight) } }
    
    /// The copyright owner of the file contents.
    public var copyright: String? {
        get { value(for: \.copyright) } }
    
    /// An array of font names used in this 
    public var fonts: [String]? {
        get { value(for: \.fonts) } }
    
    /// The family name of the font used in this 
    public var fontFamilyName: String? {
        get { value(for: \.fontFamilyName) } }
    
    /// A list of contacts that are associated with this document, not including the authors.
    public var contactKeywords: [String]? {
        get { value(for: \.contactKeywords) } }
    
    /// Indicates the languages of the intellectual content of the resource.
    public var languages: [String]? {
        get { value(for: \.languages) } }
    
    /// Provides a link to information about rights held in and over the resource.
    public var rights: String? {
        get { value(for: \.rights) } }
    
    /// The company or organization that created the document.
    public var organizations: [String]? {
        get { value(for: \.organizations) } }
    
    /// The entity responsible for making the item available. For example, a person, an organization, or a service. Typically, the name of a publisher should be used to indicate the entity.
    public var publishers: [String]? {
        get { value(for: \.publishers) } }
    
    /// Email Addresses related to this 
    public var emailAddresses: [String]? {
        get { value(for: \.emailAddresses) } }
    
    /// Phone numbers related to this 
    public var phoneNumbers: [String]? {
        get { value(for: \.phoneNumbers) } }
    
    /// People or organizations contributing to the content of the document.
    public var contributors: [String]? {
        get { value(for: \.contributors) } }
    
    /// The security or encryption method used for the document.
    public var securityMethod: Double? {
        get { value(for: \.securityMethod) } }
            
    
    // MARK: - Places

    /// The full, publishable name of the country or region where the intellectual property of the item was created, according to guidelines of the provider.
    public var country: String? {
        get { value(for: \.country) }
        set { setExplicity(\.country, to: newValue) } }
        
    /// City of the 
    public var city: String? {
        get { value(for: \.city) }
        set { setExplicity(\.city, to: newValue) } }
            
    /// Identifies the province or state of origin according to guidelines established by the provider. For example, "CA", "Ontario", or "Sussex".
    public var stateOrProvince: String? {
        get { value(for: \.stateOrProvince) }
        set { setExplicity(\.stateOrProvince, to: newValue) } }
     
    public var areaInformation: String? {
        get { value(for: \.areaInformation) } }
    
    /// The name of the location or point of interest associated with the 
    public var namedLocation: String? {
        get { value(for: \.namedLocation) } }
    
    /// The altitude of the item in meters above sea level, expressed using the WGS84 datum. Negative values lie below sea level.
    public var altitude: Double? {
        get { value(for: \.altitude) } }
    
    /// The latitude of the item in degrees north of the equator, expressed using the WGS84 datum. Negative values lie south of the equator.
    public var latitude: Double? {
        get { value(for: \.latitude) } }
    
    /// The longitude of the item in degrees east of the prime meridian, expressed using the WGS84 datum. Negative values lie west of the prime meridian.
    public var longitude: Double? {
        get { value(for: \.longitude) } }
    
    /// The speed of the item, in kilometers per hour.
    public var speed: Double? {
        get { value(for: \.speed) } }
    
    /// The timestamp on the  This generally is used to indicate the time at which the event captured by the item took place.
    public var timestamp: Date? {
        get { value(for: \.timestamp) } }

    /// The direction of travel of the item, in degrees from true north.
    public var gpsTrack: Double? {
        get { value(for: \.gpsTrack) } }
    
    public var gpsStatus: String? {
        get { value(for: \.gpsStatus) } }
    
    public var gpsMeasureMode: String? {
        get { value(for: \.gpsMeasureMode) } }
    
    public var gpsDop: Double? {
        get { value(for: \.gpsDop) } }
    
    public var gpsMapDatum: String? {
        get { value(for: \.gpsMapDatum) } }
    
    public var gpsDestLatitude: Double? {
        get { value(for: \.gpsDestLatitude) } }
    
    public var gpsDestLongitude: Double? {
        get { value(for: \.gpsDestLongitude) } }
    
    public var gpsDestBearing: Double? {
        get { value(for: \.gpsDestBearing) } }
    
    public var gpsDestDistance: Double? {
        get { value(for: \.gpsDestDistance) } }
    
    public var gpsProcessingMethod: String? {
        get { value(for: \.gpsProcessingMethod) } }
    
    public var gpsDateStamp: Date? {
        get { value(for: \.gpsDateStamp) } }
    
    public var gpsDifferental: Double? {
        get { value(for: \.gpsDifferental) } }
    
    
    // MARK: - Audio
    
    /// Sample rate of the audio data contained in the file. The sample rate is a float value representing hz (audio_frames/second). For example: 44100.0, 22254.54.
    public var audioSampleRate: Double? {
        get { value(for: \.audioSampleRate) } }
    
    /// Number of channels in the audio data contained in the file.
    public var audioChannelCount: Double? {
        get { value(for: \.audioChannelCount) } }
    
    /// The name of the application that encoded the data contained in the audio file.
    public var audioEncodingApplication: String? {
        get { value(for: \.audioEncodingApplication) } }
    
    /// A float value that specifies the beats per minute of the music contained in the audio file.
    public var tempo: Double? {
        get { value(for: \.tempo) } }
    
    /// The key of the music contained in the audio file. For example: C, Dm, F#m, Bb.
    public var keySignature: String? {
        get { value(for: \.keySignature) } }
    
    /// The time signature of the musical composition contained in the audio/MIDI file. For example: "4/4", "7/8".
    public var timeSignature: String? {
        get { value(for: \.timeSignature) } }

    /// The track number of a song or composition when it is part of an album.
    public var trackNumber: Int? {
        get { value(for: \.trackNumber) } }
    
    /// The composer of the music contained in the audio file.
    public var composer: String? {
        get { value(for: \.composer) } }
    
    /// The lyricist, or text writer, of the music contained in the audio file.
    public var lyricist: String? {
        get { value(for: \.lyricist) } }
    
    /// The recording date of the song or composition.
    public var recordingDate: Date? {
        get { value(for: \.recordingDate) } }
    
    /// Indicates the year the item was recorded. For example, 1964, 2003, etc.
    public var recordingYear: Double? {
        get { value(for: \.recordingYear) } }
    
    /// The musical genre of the song or composition contained in the audio file. For example: Jazz, Pop, Rock, Classical.
    public var musicalGenre: String? {
        get { value(for: \.musicalGenre) } }
    
    /// Indicates whether the MIDI sequence contained in the file is setup for use with a General MIDI device.
    public var isGeneralMidiSequence: Bool? {
        get { value(for: \.isGeneralMidiSequence) } }
    
    /// Specifies the loop's original key. The key is the root note or tonic for the loop, and does not include the scale type.
    public var appleLoopsRootKey: String? {
        get { value(for: \.appleLoopsRootKey) } }
    
    /// Specifies key filtering information about a loop. Loops are matched against projects that often in a major or minor key.
    public var appleLoopsKeyFilterType: String? {
        get { value(for: \.appleLoopsKeyFilterType) } }
    
    /// Specifies how a file should be played.
    public var appleLoopsLoopMode: String? {
        get { value(for: \.appleLoopsLoopMode) } }
    
    /// Specifies multiple pieces of descriptive information about a loop.
    public var appleLoopDescriptors: [String]? {
        get { value(for: \.appleLoopDescriptors) } }
    
    /// Specifies the category of an instrument.
    public var musicalInstrumentCategory: String? {
        get { value(for: \.musicalInstrumentCategory) } }
    
    /// Specifies the name of instrument relative to the instrument category.
    public var musicalInstrumentName: String? {
        get { value(for: \.musicalInstrumentName) } }
    
    
    // MARK: - Media
    
    /// The duration of the content of file. Usually for videos and audio.
    public var duration: TimeDuration? {
        get { if let durationSeconds = durationSeconds {
            return TimeDuration(durationSeconds)}
            return nil
        } }
    
    /// The duration, in seconds, of the content of file. Usually for videos and audio.
    var durationSeconds: Double? {
        get { value(for: \.durationSeconds) } }
    
    /// The media types (video, sound) present in the content.
    public var mediaTypes: [String]? {
        get { value(for: \.mediaTypes) } }
    
    /// The codecs used to encode/decode the media.
    public var codecs: [String]? {
        get { value(for: \.codecs) } }
    
    /// The total bit rate, audio and video combined, of the media.
    public var totalBitRate: Double? {
        get { value(for: \.totalBitRate) } }
    
    /// The video bit rate.
    public var videoBitRate: Double? {
        get { value(for: \.videoBitRate) } }
    
    /// The audio bit rate.
    public var audioBitRate: Double? {
        get { value(for: \.audioBitRate) } }
    
    /// Idicates whether the content is prepared for streaming.
    public var streamable: Bool? {
        get { value(for: \.streamable) } }
    
    /// The delivery type. Values are “Fast start” or “RTSP”.
    public var mediaDeliveryType: String? {
        get { value(for: \.mediaDeliveryType) } }
    
    /// Original format of the video.
    public var originalFormat: String? {
        get { value(for: \.originalFormat) } }
    
    /// Original source of the video.
    public var originalSource: String? {
        get { value(for: \.originalSource) } }
    
    /// Genre of the content.
    public var genre: String? {
        get { value(for: \.genre) } }
    
    /// Directory of the content.
    public var director: String? {
        get { value(for: \.director) } }
    
    /// Producer of the content.
    public var producer: String? {
        get { value(for: \.producer) } }
    
    /// Performers of the content.
    public var performers: [String]? {
        get { value(for: \.performers) } }
    
    /// The list of people who are visible in an image or movie or written about in a document.
    public var participants: [String]? {
        get { value(for: \.participants) } }

    
    // MARK: - Image

    /// The pixel height of the contents. For example, the image height or the video frame height.
    public var pixelHeight: Double? {
        get { value(for: \.pixelHeight) } }
    
    /// The pixel width of the contents. For example, the image width or the video frame width.
    public var pixelWidth: Double? {
        get { value(for: \.pixelWidth) } }
    
    /// The pixel size of the contents. For example, the image size or the video frame size.
    public var pixelSize: CGSize? {
        get {
            if let height = pixelHeight, let width = pixelWidth {
                return CGSize(width: width, height: height) }
            return nil } }
    
    /// The total number of pixels in the contents. Same as pixelHeight x pixelWidth.
    public var pixelCount: Double? {
        get { value(for: \.pixelCount) } }
    
    /// The color space model used by the document contents. For example, “RGB”, “CMYK”, “YUV”, or “YCbCr”.
    public var colorSpace: String? {
        get { value(for: \.colorSpace) } }
    
    /// The number of bits per sample. For example, the bit depth of an image (8-bit, 16-bit etc...) or the bit depth per audio sample of uncompressed audio data (8, 16, 24, 32, 64, etc..).
    public var bitsPerSample: Double? {
        get { value(for: \.bitsPerSample) } }
            
    /// Indicates if a camera flash was used.
    public var flashOnOff: Bool? {
        get { value(for: \.flashOnOff) } }
    
    /// The actual focal length of the lens, in millimeters.
    public var focalLength: Double? {
        get { value(for: \.focalLength) } }
    
    /// The manufacturer of the device used for this   For example, Apple, Canon, etc.
    public var deviceManufacturer: String? {
        get { value(for: \.deviceManufacturer) } }
    
    /// The model of the device used for this  For example, iPhone 13, etc.
    public var deviceModel: String? {
        get { value(for: \.deviceModel) } }
    
    /// The ISO speed used to acquire the document contents.
    public var isoSpeed: Double? {
        get { value(for: \.isoSpeed) } }
        
    /// The orientation of the document contents.
    public var orientation: Orientation? {
        get {  return value(for: \.orientation) }
    }
    
    /// The orientation of a document.
    public enum Orientation: Int, QueryRawRepresentable {
        /// Horizontal orientation.
        case horizontal = 0
        
        /// Vertical orientation.
        case vertical = 1
    }
    
    /// The names of the layers in the file.
    public var layerNames: [String]? {
        get { value(for: \.layerNames) } }
    
    /// White balance setting of the camera when the picture was taken.
    public var whiteBalance: WhiteBalance? {
        get {  return value(for: \.whiteBalance) }
    }
    
    /// White balance setting of a camera.
    public enum WhiteBalance: Int, QueryRawRepresentable {
        /// Automatic white balance.
        case auto = 0
        
        /// White balance is off.
        case off = 1
    }
    
    /// The aperture setting used to acquire the document contents. This unit is the APEX value.
    public var aperture: Double? {
        get { value(for: \.aperture) } }
    
    /// The name of the color profile used by the document contents.
    public var colorProfile: String? {
        get { value(for: \.colorProfile) } }
    
    /// Resolution width, in DPI, of this image.
    public var dpiResolutionWidth: Double? {
        get { value(for: \.dpiResolutionWidth) } }
    
    /// Resolution height, in DPI, of this image.
    public var dpiResolutionHeight: Double? {
        get { value(for: \.dpiResolutionHeight) } }
    
    /// The resolution size, in DPI, of the contents.
    public var dpiResolution: CGSize? {
        get {
            if let height = dpiResolutionHeight, let width = dpiResolutionWidth {
                return CGSize(width: width, height: height) }
            return nil } }
    
    /// The exposure mode used to acquire the document contents.
    public var exposureMode: Double? {
        get { value(for: \.exposureMode) } }
    
    /// The exposure time, in seconds, used to acquire the document contents.
    public var exposureTimeSeconds: Double? {
        get { value(for: \.exposureTimeSeconds) } }
    
    /// The version of the EXIF header used to generate the metadata.
    public var exifVersion: String? {
        get { value(for: \.exifVersion) } }
    
    /// The name of the camera company.
    public var cameraOwner: String? {
        get { value(for: \.cameraOwner) } }
    
    /// The actual focal length of the lens, in 35 millimeters.
    public var focalLength35Mm: Double? {
        get { value(for: \.focalLength35Mm) } }
    
    /// The name of the camera lens model.
    public var lensModel: String? {
        get { value(for: \.lensModel) } }

    /// The direction of the item's image, in degrees from true north.
    public var imageDirection: Double? {
        get { value(for: \.imageDirection) } }
    
    /// Indicates if this image file has an alpha channel.
    public var hasAlphaChannel: Bool? {
        get { value(for: \.hasAlphaChannel) } }
    
    /// Indicates if red-eye reduction was used to take the picture.
    public var redEyeOnOff: Bool? {
        get { value(for: \.redEyeOnOff) } }
    
    /// The metering mode used to take the image.
    public var meteringMode: String? {
        get { value(for: \.meteringMode) } }
    
    /// The smallest f-number of the lens. Ordinarily it is given in the range of 00.00 to 99.99.
    public var maxAperture: Double? {
        get { value(for: \.maxAperture) } }
    
    /// The diameter of the diaphragm aperture in terms of the effective focal length of the lens.
    public var fNumber: Double? {
        get { value(for: \.fNumber) } }
    
    /// The class of the exposure program used by the camera to set exposure when the image is taken. Possible values include: Manual, Normal, and Aperture priority.
    public var exposureProgram: String? {
        get { value(for: \.exposureProgram) } }
    
    /// The time of the exposure.
    public var exposureTimeString: String? {
        get { value(for: \.exposureTimeString) } }
    
    /// A bool determining if the file is a screen capture.
    public var isScreenCapture: Bool? {
        get { value(for: \.isScreenCapture) }  }
        
    /// The screen capture type of the file.
    public var screenCaptureType: ScreenCaptureType? {
        get {  return value(for: \.screenCaptureType) }
    }
    
    /// The screen capture type.
     public enum ScreenCaptureType: String, QueryRawRepresentable {
         /// Screen capture of a display.
         case display
         
         /// Screen capture of a window.
         case window
         
         /// Screen capture of a selection.
         case selection
     }
    
    /// The screen capture rect of the file.
    public var screenCaptureRect: CGRect? {
        get {
            let kp: PartialKeyPath<MetadataItem> = \.screenCaptureRect
            if let values: [Double] = value(for: kp.mdItemKey), values.count == 4 {
                return CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
        }
            return nil
        } }
    
    
    // MARK: - Messages / Mail
    
    /// This attribute indicates the author of the emails message addresses.
    public var authorEmailAddresses: [String]? {
        get { value(for: \.authorEmailAddresses) } }
    
    // Addresses for authors of this 
    public var authorAddresses: [String]? {
        get { value(for: \.authorAddresses) } }
    
    /// Recipients of this 
    public var recipients: [String]? {
        get { value(for: \.recipients) } }
    
    /// This attribute indicates the recipients email addresses. (This is always the email address, and not the human readable version).
    public var recipientEmailAddresses: [String]? {
        get { value(for: \.recipientEmailAddresses) } }
    
    /// This attribute indicates the recipient addresses of the document.
    public var recipientAddresses: [String]? {
        get { value(for: \.recipientAddresses) } }
    
    /// Instant message addresses related to this 
    public var instantMessageAddresses: [String]? {
        get { value(for: \.instantMessageAddresses) } }
    
    /// Received dates for this file.
    public var receivedDates: [Date]? {
        get { value(for: \.receivedDates) } }
    
    /// Received recipients for this file.
    public var receivedRecipients : [String]? {
        get { value(for: \.receivedRecipients) } }
    
    /// Received recipient handles for this file.
    public var receivedRecipientHandles : [String]? {
        get { value(for: \.receivedRecipientHandles) } }
    
    /// Received sender for this file.
    public var receivedSenders : [String]? {
        get { value(for: \.receivedSenders) } }
    
    /// Received sender handles for this file.
    public var receivedSenderHandles : [String]? {
        get { value(for: \.receivedSenderHandles) } }
    
    /// Received types for this file.
    public var receivedTypes : [String]? {
        get { value(for: \.receivedTypes) } }
    
    // Whether the file is likely to be considered a junk file.
    public var isLikelyJunk: Bool? {
        get { value(for: \.isLikelyJunk) } }
    
    /**
     The value indicates the relevance of the item's content if it's part of a metadata query result.
     
     The value is a floating point value between 0.0 and 1.0
     */
    public var queryContentRelevance: Double? {
        get { value(for: \.queryContentRelevance) } }
}

public extension MetadataItem {
    func setExplicity<V, K: KeyPath<MetadataItem, V?>>(_ keyPath: K, to value: V?) {
        if keyPath == \.pixelSize, let value = value as? CGSize {
            setExplicity(\.pixelWidth, to: Double(value.width))
            setExplicity(\.pixelHeight, to: Double(value.height))
        } else {
            let key = "com.apple.metadata:" + keyPath.mdItemKey
            url?.extendedAttributes[key] = value
        }
    }
    
    func getExplicity<V: Any, K: KeyPath<MetadataItem, V?>>(_ keyPath: K) -> V? {
        let key = "com.apple.metadata:" + keyPath.mdItemKey
        return url?.extendedAttributes[key]
    }
    
    
    subscript<T>(key: String, initalValue: T? = nil) -> T?  {
        get {
            guard let _url = url ?? url  else { return nil }
            return _url.extendedAttributes[key]
        }
        set {
            guard let _url = url ?? url  else { return }
            _url.extendedAttributes[key] = newValue
        }
    }
    
     func availableExtendedAttributes() throws -> [String] {
        guard let _url = url ?? url  else { return [] }
       return try _url.extendedAttributes.listExtendedAttributes()
    }
}

extension MetadataItem: Hashable {
    public static func == (lhs: MetadataItem, rhs: MetadataItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(item)
    }
}
