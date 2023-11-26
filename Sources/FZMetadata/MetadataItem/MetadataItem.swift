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
 ```
 if let metadata = MetadataItem(url: fileURL) {
    metadata.creationDate // The creation date of the file
    metadata.contentModificationDate = Date()
 }
 ```
 */
public class MetadataItem {
    internal let item: NSMetadataItem
    internal var values: [String:Any] = [:]
    
    /**
     Initializes a metadata item with a given NSMetadataItem.
     
     - Parameters:
        - item: The NSMetadataItem.

     - Returns: A metadata self.
     */
    public init(item: NSMetadataItem) {
        self.item = item
        self.values = [:]
    }
    
#if os(macOS)
    /**
     Initializes a metadata item with a given URL.
     
     - Parameters:
        - url: The URL for the metadata self.

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
    
    internal init?(url: URL, values: [String:Any]? = nil) {
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
    
    internal var queryAttributes: [String] {
        return Array(values.keys)
    }
    
    internal var _availableAttributes: [String] {
        return (item.attributes + queryAttributes).uniqued()
    }
    /**
     An array containing the attributes for the metadata item’s values.

     - Returns: This property contains an array of attributes, representing the values available from this metadata self. For a list of possible keys, see Attributes.
     */
    public var availableAttributes: [Attribute] {
        let attributes = self._availableAttributes
        return attributes.compactMap({Attribute(rawValue: $0)})
    }
    
    internal func value<T>(for attribute: String) -> T? {
        if let value = self.values[attribute] as? T {
            return value } else {
                if attribute != "kMDItemPath" {
                    Swift.print("missing", attribute, "values", self.values.keys)
                }
                if let value: T = item.value(for: attribute) {
                    return value
                }
            }
        return nil
    }
        
    internal func value<T: RawRepresentable, K: KeyPath<MetadataItem, T?>>(_ keyPath: K) -> T? {
        if let rawValue: T.RawValue = self.value(for: keyPath.mdItemKey) {
           return T(rawValue: rawValue)
        }
        return getExplicity(keyPath)
    }
    
    internal func value<T, K: KeyPath<MetadataItem, T?>>(_ keyPath: K) -> T? {
        if let value: T = self.value(for: keyPath.mdItemKey) {
           return value
        }
        return getExplicity(keyPath)
    }
    
    // MARK: - File
    
    /// The url of the self.
    public var url: URL? {
        if let url = self.value(\.url) {
            return url
        } else if let path = self.value(\.path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    /// The full path to the file.
    public var path: String? {
        get { self.value(\.path) } }
    
    /// The file name of the item including extension.
    public var fileName: String? {
        get { self.value(\.fileName) ?? self.url?.lastPathComponent } }
    
    /// The display name of the item, which may be different then the file system name.
    public var displayName: String? {
        get { self.value(\.displayName) } }
    
    /// Alternative names of the self.
    public var alternateNames: [String]? {
        get { self.value(\.alternateNames) } }
    
    /// The extension of the file.
    public var fileExtension: String? {
        get { self.url?.pathExtension } }
    
    /// The size of of the file in bytes.
    public var fileSizeBytes: Int? {
        get { self.value(\.fileSizeBytes) } }
    
    /// The size of of the file as DataSize.
    public var fileSize: DataSize? {
        if let bytes = fileSizeBytes {
            return DataSize(bytes)
        }
        return nil
    }
    
    /// Indicates whether the file is invisible.
    public var fileIsInvisible: Bool? {
        get { self.value(\.fileIsInvisible) } }
    
    /// Indicates whether the file is invisible.
    public var fileExtensionIsHidden: Bool? {
        get { self.value(\.fileExtensionIsHidden) } }
    
    /// The type of the file.
    public var fileType: FileType? {
        get {  if let contentTypeTree: [String] = self.value(\.contentTypeTree) {
            return FileType(contentTypeTree: contentTypeTree)
        }
            return nil
        }
    }
          
    /// The content type of the file as UTI identifier.
    public var contentType: String? {
        get { self.value(\.contentType) } }
    
    /// An array of UTI identifiers representing the content type tree of the file.
    public var contentTypeTree: [String]? {
        get { self.value(\.contentTypeTree) } }
    
    @available(macOS 11.0, iOS 14.0, *)
    /// The content type of the file as UTType.
    public var contentUTType: UTType? {
        get { if let type = self.contentType { return UTType(type) }
                return nil } }
    
    /// The date and time that the file was created.
    public var creationDate: Date? {
        get { self.value(\.creationDate) }
        set { self.setExplicity(\.creationDate, to: newValue) } }
        
    /// The date and time that the file was last used.
    public var lastUsedDate: Date? {
        get { self.value(\.lastUsedDate) }
        set { self.setExplicity(\.lastUsedDate, to: newValue) } }
        
    /// An array of dates and times the file was last used.
    public var lastUsageDates: [Date]? {
        get { self.value(\.lastUsageDates) }
        set { self.setExplicity(\.lastUsageDates, to: newValue) } }
    
    /// The date when the metadata last changed.
    public var metadataModificationDate: Date? {
        get { self.value(\.metadataModificationDate) }
        set { self.setExplicity(\.metadataModificationDate, to: newValue) } }
    
    /// The date and time that the content of the file was created.
    public var contentCreationDate: Date? {
        get { self.value(\.contentCreationDate) }
        set { self.setExplicity(\.contentCreationDate, to: newValue) } }
    
    /// The date the file contents last changed.
    public var contentChangeDate: Date? {
        get { self.value(\.contentChangeDate) }
        set { self.setExplicity(\.contentChangeDate, to: newValue) } }
    
    /// The date and time that the contents of the file were last modified.
    public var contentModificationDate: Date? {
        get { self.value(\.contentModificationDate) }
        set { self.setExplicity(\.contentModificationDate, to: newValue) } }
    
    /// The date when the file got added of the file.
    public var dateAdded: Date? {
        get { self.value(\.dateAdded) }
        set { self.setExplicity(\.dateAdded, to: newValue) } }
    
    /// The download date of the file.
    public var downloadedDate: Date? {
        get { self.value(\.downloadedDate) }
        set { self.setExplicity(\.downloadedDate, to: newValue) }
    }
    
    /// The purchase date of the file.
    public var purchaseDate: Date? {
        get { self.value(\.purchaseDate) }
    }
    
    /// Date this item is due (e.g. for a calendar event file).
    public var dueDate: Date? {
        get { self.value(\.dueDate) }
        set { self.setExplicity(\.dueDate, to: newValue) } }
    
    /// Number of files in a directory.
    public var directoryFilesCount: Int? {
        get { self.value(\.directoryFilesCount) } }
    
    ///  A description of the content of the resource. The description may include an abstract, table of contents, reference to a graphical representation of content or a free-text account of the content.
    public var description: String? {
        get { self.value(\.description) } }
    
    // A description of the kind of item this file represents.
    public var kind: [String]? {
        get { self.value(\.kind) } }
    
    /// Information about the self.
    public var information: String? {
        get { self.value(\.information) } }
    
    /// A formal identifier used to reference the resource within a given context.
    public var identifier: String? {
        get { self.value(\.identifier) } }
    
    /// Keywords associated with this file. For example, “Birthday”, “Important”, etc.
    public var keywords: [String]? {
        get { self.value(\.keywords) } }
    
    /// The title of the file. For example, this could be the title of a document, the name of a song, or the subject of an email message.
    public var title: String? {
        get { self.value(\.title) } }
    
    /// The title for a collection of media. This is analagous to a record album, or photo album.
    public var album: String? {
        get { self.value(\.album) } }
    
    /// Authors, Artists, etc. of the contents of the file.
    public var authors: [String]? {
        get { self.value(\.authors) } }
    
    /// The version number of this file.
    public var version: String? {
        get { self.value(\.version) } }
    
    /// A comment related to the file. This differs from the Finder comment, finderComment.
    public var comment: String? {
        get { self.value(\.comment) } }
    
    /// User rating of this self. For example, the stars rating of an iTunes track.
    public var starRating: Double? {
        get { self.value(\.starRating) } }
    
    /// Describes where the file was obtained from. For example download urls.
    public var whereFroms: [String]? {
        get { self.value(\.whereFroms) }
        set { self.setExplicity(\.whereFroms, to: newValue) }
    }
    
    /// Finder comments for this file. This differs from the file comment, comment.
    public var finderComment: String? {
        get { self.value(\.finderComment) } }
    
    /// Finder tags for this file.
    public var finderTags: [String]? {
        get { self.value(\.finderTags)?.compactMap({$0.replacingOccurrences(of: "\n6", with:"")})
        }
        set { self.setExplicity(\.finderTags, to: newValue) }
    }
    
    internal var finderPrimaryTagColorIndex: Int? {
        get { self.value(\.finderPrimaryTagColorIndex) } }
    
    /// First finder tag color of the item.
    public var finderPrimaryTagColor: FinderTag.Color? {
        get {
            if let rawValue: Int = self.finderPrimaryTagColorIndex {
            return FinderTag.Color(rawValue: rawValue)
        }
            return nil
        }
    }
    
    /// Indicates whether the file is invisible.
    public var hasCustomIcon: Bool? {
        get { self.value(\.hasCustomIcon) } }
    
    /// The usage count of the file.
    public var usageCount: Int? {
        get { if let useCount = self.value(\.usageCount) {
            return useCount - 2
        }
            return nil
        } }
    
    /// If this item is a bundle, then this is the CFBundleIdentifier.
    public var bundleIdentifier: String? {
        get { self.value(\.bundleIdentifier) } }
    
    // Architectures the item requires to execute;architectures
    public var executableArchitectures: [String]? {
        get { self.value(\.executableArchitectures) } }
    
    // Platform the item requires to execute;platform
    public var executablePlatform: String? {
        get { self.value(\.executablePlatform) } }
    
    // Indicates whether the file is owned and managed by an application.
    public var isApplicationManaged: Bool? {
        get { self.value(\.isApplicationManaged) } }
    
    /// Application used to convert the original content into it's current form. For example, a PDF file might have an encoding application set to "Distiller".
    public var encodingApplications: [String]? {
        get { self.value(\.encodingApplications) } }
    
    // Categories application is a member of.
    public var applicationCategories: [String]? {
        get { self.value(\.applicationCategories) } }
        
    /// The AppStore category of the item if it's an application from the AppStore.
    public var appstoreCategory: String? {
        get { self.value(\.appstoreCategory) } }
    
    /// The AppStore category type of the item if it's an application from the AppStore.
    public var appstoreCategoryType: String? {
        get { self.value(\.appstoreCategoryType) } }
    
    // MARK: - Person / Contact

    
    // MARK: - Document
    
    /// Contains a text representation of the content of the document. Data in multiple fields should be combined using a whitespace character as a separator.
    public var textContent: String? {
        get { self.value(\.textContent) } }
    
    /// Subject of the this self.
    public var subject: String? {
        get { self.value(\.subject) } }
    
    /// Theme of the this self.
    public var theme: String? {
        get { self.value(\.theme) } }
    
    /// Publishable summary of the contents of the self.
    public var headline: String? {
        get { self.value(\.headline) } }
    
    /// Application or operation system used to create the document content (e.g.  "Word",  "Pages", 16.2, and so on).
    public var creator: String? {
        get { self.value(\.creator) } }
    
    /// Other information concerning the item, such as handling instructions.
    public var instructions: String? {
        get { self.value(\.instructions) } }
    
    /// Editors of the contents of the file.
    public var editors: [String]? {
        get { self.value(\.editors) } }
    
    /// The audience for which the file is intended. The audience may be determined by the creator or the publisher or by a third party.
    public var audiences: [String]? {
        get { self.value(\.audiences) } }
    
    /// Extent or scope of the content of the document.
    public var coverage: [String]? {
        get { self.value(\.coverage) } }
            
    /// The list of projects that this file is part of. For example, if you were working on a movie all of the files could be marked as belonging to the project “My Movie”.
    public var projects: [String]? {
        get { self.value(\.projects) } }
    
    /// Number of pages in the document.
    public var numberOfPages: Double? {
        get { self.value(\.numberOfPages) } }
    
    /// Width of the document page, in points (72 points per inch). For PDF files this indicates the width of the first page only.
    public var pageWidth: Double? {
        get { self.value(\.pageWidth) } }
    
    /// Height of the document page, in points (72 points per inch). For PDF files this indicates the height of the first page only.
    public var pageHeight: Double? {
        get { self.value(\.pageHeight) } }
    
    /// The copyright owner of the file contents.
    public var copyright: String? {
        get { self.value(\.copyright) } }
    
    /// An array of font names used in this self.
    public var fonts: [String]? {
        get { self.value(\.fonts) } }
    
    /// The family name of the font used in this self.
    public var fontFamilyName: String? {
        get { self.value(\.fontFamilyName) } }
    
    /// A list of contacts that are associated with this document, not including the authors.
    public var contactKeywords: [String]? {
        get { self.value(\.contactKeywords) } }
    
    /// Indicates the languages of the intellectual content of the resource.
    public var languages: [String]? {
        get { self.value(\.languages) } }
    
    /// Provides a link to information about rights held in and over the resource.
    public var rights: String? {
        get { self.value(\.rights) } }
    
    /// The company or organization that created the document.
    public var organizations: [String]? {
        get { self.value(\.organizations) } }
    
    /// The entity responsible for making the item available. For example, a person, an organization, or a service. Typically, the name of a publisher should be used to indicate the entity.
    public var publishers: [String]? {
        get { self.value(\.publishers) } }
    
    /// Email Addresses related to this self.
    public var emailAddresses: [String]? {
        get { self.value(\.emailAddresses) } }
    
    /// Phone numbers related to this self.
    public var phoneNumbers: [String]? {
        get { self.value(\.phoneNumbers) } }
    
    /// People or organizations contributing to the content of the document.
    public var contributors: [String]? {
        get { self.value(\.contributors) } }
    
    /// The security or encryption method used for the document.
    public var securityMethod: Double? {
        get { self.value(\.securityMethod) } }
            
    
    // MARK: - Places

    /// The full, publishable name of the country or region where the intellectual property of the item was created, according to guidelines of the provider.
    public var country: String? {
        get { self.value(\.country) }
        set { self.setExplicity(\.country, to: newValue) } }
        
    /// City of the self.
    public var city: String? {
        get { self.value(\.city) }
        set { self.setExplicity(\.city, to: newValue) } }
            
    /// Identifies the province or state of origin according to guidelines established by the provider. For example, "CA", "Ontario", or "Sussex".
    public var stateOrProvince: String? {
        get { self.value(\.stateOrProvince) }
        set { self.setExplicity(\.stateOrProvince, to: newValue) } }
     
    public var areaInformation: String? {
        get { self.value(\.areaInformation) } }
    
    /// The name of the location or point of interest associated with the self.
    public var namedLocation: String? {
        get { self.value(\.namedLocation) } }
    
    /// The altitude of the item in meters above sea level, expressed using the WGS84 datum. Negative values lie below sea level.
    public var altitude: Double? {
        get { self.value(\.altitude) } }
    
    /// The latitude of the item in degrees north of the equator, expressed using the WGS84 datum. Negative values lie south of the equator.
    public var latitude: Double? {
        get { self.value(\.latitude) } }
    
    /// The longitude of the item in degrees east of the prime meridian, expressed using the WGS84 datum. Negative values lie west of the prime meridian.
    public var longitude: Double? {
        get { self.value(\.longitude) } }
    
    /// The speed of the item, in kilometers per hour.
    public var speed: Double? {
        get { self.value(\.speed) } }
    
    /// The timestamp on the self. This generally is used to indicate the time at which the event captured by the item took place.
    public var timestamp: Date? {
        get { self.value(\.timestamp) } }

    /// The direction of travel of the item, in degrees from true north.
    public var gpsTrack: Double? {
        get { self.value(\.gpsTrack) } }
    
    public var gpsStatus: String? {
        get { self.value(\.gpsStatus) } }
    
    public var gpsMeasureMode: String? {
        get { self.value(\.gpsMeasureMode) } }
    
    public var gpsDop: Double? {
        get { self.value(\.gpsDop) } }
    
    public var gpsMapDatum: String? {
        get { self.value(\.gpsMapDatum) } }
    
    public var gpsDestLatitude: Double? {
        get { self.value(\.gpsDestLatitude) } }
    
    public var gpsDestLongitude: Double? {
        get { self.value(\.gpsDestLongitude) } }
    
    public var gpsDestBearing: Double? {
        get { self.value(\.gpsDestBearing) } }
    
    public var gpsDestDistance: Double? {
        get { self.value(\.gpsDestDistance) } }
    
    public var gpsProcessingMethod: String? {
        get { self.value(\.gpsProcessingMethod) } }
    
    public var gpsDateStamp: Date? {
        get { self.value(\.gpsDateStamp) } }
    
    public var gpsDifferental: Double? {
        get { self.value(\.gpsDifferental) } }
    
    
    // MARK: - Audio
    
    /// Sample rate of the audio data contained in the file. The sample rate is a float value representing hz (audio_frames/second). For example: 44100.0, 22254.54.
    public var audioSampleRate: Double? {
        get { self.value(\.audioSampleRate) } }
    
    /// Number of channels in the audio data contained in the file.
    public var audioChannelCount: Double? {
        get { self.value(\.audioChannelCount) } }
    
    /// The name of the application that encoded the data contained in the audio file.
    public var audioEncodingApplication: String? {
        get { self.value(\.audioEncodingApplication) } }
    
    /// A float value that specifies the beats per minute of the music contained in the audio file.
    public var tempo: Double? {
        get { self.value(\.tempo) } }
    
    /// The key of the music contained in the audio file. For example: C, Dm, F#m, Bb.
    public var keySignature: String? {
        get { self.value(\.keySignature) } }
    
    /// The time signature of the musical composition contained in the audio/MIDI file. For example: "4/4", "7/8".
    public var timeSignature: String? {
        get { self.value(\.timeSignature) } }

    /// The track number of a song or composition when it is part of an album.
    public var trackNumber: Int? {
        get { self.value(\.trackNumber) } }
    
    /// The composer of the music contained in the audio file.
    public var composer: String? {
        get { self.value(\.composer) } }
    
    /// The lyricist, or text writer, of the music contained in the audio file.
    public var lyricist: String? {
        get { self.value(\.lyricist) } }
    
    /// The recording date of the song or composition.
    public var recordingDate: Date? {
        get { self.value(\.recordingDate) } }
    
    /// Indicates the year the item was recorded. For example, 1964, 2003, etc.
    public var recordingYear: Double? {
        get { self.value(\.recordingYear) } }
    
    /// The musical genre of the song or composition contained in the audio file. For example: Jazz, Pop, Rock, Classical.
    public var musicalGenre: String? {
        get { self.value(\.musicalGenre) } }
    
    /// Indicates whether the MIDI sequence contained in the file is setup for use with a General MIDI device.
    public var isGeneralMidiSequence: Bool? {
        get { self.value(\.isGeneralMidiSequence) } }
    
    /// Specifies the loop's original key. The key is the root note or tonic for the loop, and does not include the scale type.
    public var appleLoopsRootKey: String? {
        get { self.value(\.appleLoopsRootKey) } }
    
    /// Specifies key filtering information about a loop. Loops are matched against projects that often in a major or minor key.
    public var appleLoopsKeyFilterType: String? {
        get { self.value(\.appleLoopsKeyFilterType) } }
    
    /// Specifies how a file should be played.
    public var appleLoopsLoopMode: String? {
        get { self.value(\.appleLoopsLoopMode) } }
    
    /// Specifies multiple pieces of descriptive information about a loop.
    public var appleLoopDescriptors: [String]? {
        get { self.value(\.appleLoopDescriptors) } }
    
    /// Specifies the category of an instrument.
    public var musicalInstrumentCategory: String? {
        get { self.value(\.musicalInstrumentCategory) } }
    
    /// Specifies the name of instrument relative to the instrument category.
    public var musicalInstrumentName: String? {
        get { self.value(\.musicalInstrumentName) } }
    
    
    // MARK: - Media
    
    /// The duration, as Duration, of the content of file. Usually for videos and audio.
    public var duration: TimeDuration? {
        get { if let durationSeconds = durationSeconds {
            return TimeDuration(durationSeconds)}
            return nil
        } }
    
    /// The duration, in seconds, of the content of file. Usually for videos and audio.
    public var durationSeconds: Double? {
        get { self.value(\.durationSeconds) } }
    
    /// The media types (video, sound) present in the content.
    public var mediaTypes: [String]? {
        get { self.value(\.mediaTypes) } }
    
    /// The codecs used to encode/decode the media.
    public var codecs: [String]? {
        get { self.value(\.codecs) } }
    
    /// The total bit rate, audio and video combined, of the media.
    public var totalBitRate: Double? {
        get { self.value(\.totalBitRate) } }
    
    /// The video bit rate.
    public var videoBitRate: Double? {
        get { self.value(\.videoBitRate) } }
    
    /// The audio bit rate.
    public var audioBitRate: Double? {
        get { self.value(\.audioBitRate) } }
    
    /// Idicates whether the content is prepared for streaming.
    public var streamable: Bool? {
        get { self.value(\.streamable) } }
    
    /// The delivery type. Values are “Fast start” or “RTSP”.
    public var mediaDeliveryType: String? {
        get { self.value(\.mediaDeliveryType) } }
    
    /// Original format of the video.
    public var originalFormat: String? {
        get { self.value(\.originalFormat) } }
    
    /// Original source of the video.
    public var originalSource: String? {
        get { self.value(\.originalSource) } }
    
    /// Genre of the content.
    public var genre: String? {
        get { self.value(\.genre) } }
    
    /// Directory of the content.
    public var director: String? {
        get { self.value(\.director) } }
    
    /// Producer of the content.
    public var producer: String? {
        get { self.value(\.producer) } }
    
    /// Performers of the content.
    public var performers: [String]? {
        get { self.value(\.performers) } }
    
    /// The list of people who are visible in an image or movie or written about in a document.
    public var participants: [String]? {
        get { self.value(\.participants) } }

    
    // MARK: - Image

    /// The pixel height of the contents. For example, the image height or the video frame height.
    public var pixelHeight: Double? {
        get { self.value(\.pixelHeight) } }
    
    /// The pixel width of the contents. For example, the image width or the video frame width.
    public var pixelWidth: Double? {
        get { self.value(\.pixelWidth) } }
    
    /// The pixel size of the contents. For example, the image size or the video frame size.
    public var pixelSize: CGSize? {
        get {
            if let height = self.pixelHeight, let width = self.pixelWidth {
                return CGSize(width: width, height: height) }
            return nil } }
    
    /// The total number of pixels in the contents. Same as pixelHeight x pixelWidth.
    public var pixelCount: Double? {
        get { self.value(\.pixelCount) } }
    
    /// The color space model used by the document contents. For example, “RGB”, “CMYK”, “YUV”, or “YCbCr”.
    public var colorSpace: String? {
        get { self.value(\.colorSpace) } }
    
    /// The number of bits per sample. For example, the bit depth of an image (8-bit, 16-bit etc...) or the bit depth per audio sample of uncompressed audio data (8, 16, 24, 32, 64, etc..).
    public var bitsPerSample: Double? {
        get { self.value(\.bitsPerSample) } }
            
    /// Indicates if a camera flash was used.
    public var flashOnOff: Bool? {
        get { self.value(\.flashOnOff) } }
    
    /// The actual focal length of the lens, in millimeters.
    public var focalLength: Double? {
        get { self.value(\.focalLength) } }
    
    /// The manufacturer of the device used for this self.  For example, Apple, Canon, etc.
    public var deviceManufacturer: String? {
        get { self.value(\.deviceManufacturer) } }
    
    /// The model of the device used for this self. For example, iPhone 13, etc.
    public var deviceModel: String? {
        get { self.value(\.deviceModel) } }
    
    /// The ISO speed used to acquire the document contents.
    public var isoSpeed: Double? {
        get { self.value(\.isoSpeed) } }
    
    
    public enum Orientation: Int, QueryRawRepresentable {
        case horizontal = 0
        case vertical = 1
    }
    
    /// The orientation of the document contents.
    public var orientation: Orientation? {
        get {  return self.value(\.orientation) }
    }
    
    /// The names of the layers in the file.
    public var layerNames: [String]? {
        get { self.value(\.layerNames) } }
    
    /// White balance setting a the camera.
    public enum WhiteBalance: Int, QueryRawRepresentable {
        case auto = 0
        case off = 1
        public init?(rawValue: Int) {
            self = (rawValue == 1) ? .off : .auto
        }
    }
    /// White balance setting of the camera when the picture was taken.
    public var whiteBalance: WhiteBalance? {
        get {  return self.value(\.whiteBalance) }
    }
    
    /// The aperture setting used to acquire the document contents. This unit is the APEX value.
    public var aperture: Double? {
        get { self.value(\.aperture) } }
    
    /// The name of the color profile used by the document contents.
    public var colorProfile: String? {
        get { self.value(\.colorProfile) } }
    
    /// Resolution width, in DPI, of this image.
    public var dpiResolutionWidth: Double? {
        get { self.value(\.dpiResolutionWidth) } }
    
    /// Resolution height, in DPI, of this image.
    public var dpiResolutionHeight: Double? {
        get { self.value(\.dpiResolutionHeight) } }
    
    /// The resolution size, in DPI, of the contents.
    public var dpiResolution: CGSize? {
        get {
            if let height = self.dpiResolutionHeight, let width = self.dpiResolutionWidth {
                return CGSize(width: width, height: height) }
            return nil } }
    
    /// The exposure mode used to acquire the document contents.
    public var exposureMode: Double? {
        get { self.value(\.exposureMode) } }
    
    /// The exposure time, in seconds, used to acquire the document contents.
    public var exposureTimeSeconds: Double? {
        get { self.value(\.exposureTimeSeconds) } }
    
    /// The version of the EXIF header used to generate the metadata.
    public var exifVersion: String? {
        get { self.value(\.exifVersion) } }
    
    /// The name of the camera company.
    public var cameraOwner: String? {
        get { self.value(\.cameraOwner) } }
    
    /// The actual focal length of the lens, in 35 millimeters.
    public var focalLength35Mm: Double? {
        get { self.value(\.focalLength35Mm) } }
    
    /// The name of the camera lens model.
    public var lensModel: String? {
        get { self.value(\.lensModel) } }

    /// The direction of the item's image, in degrees from true north.
    public var imageDirection: Double? {
        get { self.value(\.imageDirection) } }
    
    /// Indicates if this image file has an alpha channel.
    public var hasAlphaChannel: Bool? {
        get { self.value(\.hasAlphaChannel) } }
    
    /// Indicates if red-eye reduction was used to take the picture.
    public var redEyeOnOff: Bool? {
        get { self.value(\.redEyeOnOff) } }
    
    /// The metering mode used to take the image.
    public var meteringMode: String? {
        get { self.value(\.meteringMode) } }
    
    /// The smallest f-number of the lens. Ordinarily it is given in the range of 00.00 to 99.99.
    public var maxAperture: Double? {
        get { self.value(\.maxAperture) } }
    
    /// The diameter of the diaphragm aperture in terms of the effective focal length of the lens.
    public var fNumber: Double? {
        get { self.value(\.fNumber) } }
    
    /// The class of the exposure program used by the camera to set exposure when the image is taken. Possible values include: Manual, Normal, and Aperture priority.
    public var exposureProgram: String? {
        get { self.value(\.exposureProgram) } }
    
    /// The time of the exposure.
    public var exposureTimeString: String? {
        get { self.value(\.exposureTimeString) } }
    
    /// A bool determining if the file is a screen capture.
    public var isScreenCapture: Bool? {
        get { self.value(\.isScreenCapture) }  }
    
   /// The screen capture type.
    public enum ScreenCaptureType: String, QueryRawRepresentable {
        /// Screen capture of a display.
        case display
        /// Screen capture of a window.
        case window
        /// Screen capture of a selection.
        case selection
    }
    
    /// The screen capture type of the file.
    public var screenCaptureType: ScreenCaptureType? {
        get {  return self.value(\.screenCaptureType) }
    }
    
    /// The screen capture rect of the file.
    public var screenCaptureRect: CGRect? {
        get {
            let kp: PartialKeyPath<MetadataItem> = \.screenCaptureRect
            if let values: [Double] = self.value(for: kp.mdItemKey), values.count == 4 {
                return CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
        }
            return nil
        } }
    
    
    // MARK: - Messages / Mail
    
    /// This attribute indicates the author of the emails message addresses.
    public var authorEmailAddresses: [String]? {
        get { self.value(\.authorEmailAddresses) } }
    
    // Addresses for authors of this self.
    public var authorAddresses: [String]? {
        get { self.value(\.authorAddresses) } }
    
    /// Recipients of this self.
    public var recipients: [String]? {
        get { self.value(\.recipients) } }
    
    /// This attribute indicates the recipients email addresses. (This is always the email address, and not the human readable version).
    public var recipientEmailAddresses: [String]? {
        get { self.value(\.recipientEmailAddresses) } }
    
    /// This attribute indicates the recipient addresses of the document.
    public var recipientAddresses: [String]? {
        get { self.value(\.recipientAddresses) } }
    
    /// Instant message addresses related to this self.
    public var instantMessageAddresses: [String]? {
        get { self.value(\.instantMessageAddresses) } }
    
    /// Received dates for this file.
    public var receivedDates: [Date]? {
        get { self.value(\.receivedDates) } }
    
    /// Received recipients for this file.
    public var receivedRecipients : [String]? {
        get { self.value(\.receivedRecipients) } }
    
    /// Received recipient handles for this file.
    public var receivedRecipientHandles : [String]? {
        get { self.value(\.receivedRecipientHandles) } }
    
    /// Received sender for this file.
    public var receivedSenders : [String]? {
        get { self.value(\.receivedSenders) } }
    
    /// Received sender handles for this file.
    public var receivedSenderHandles : [String]? {
        get { self.value(\.receivedSenderHandles) } }
    
    /// Received types for this file.
    public var receivedTypes : [String]? {
        get { self.value(\.receivedTypes) } }
    
    // Whether the file is likely to be considered a junk file.
    public var isLikelyJunk: Bool? {
        get { self.value(\.isLikelyJunk) } }
    
    /**
     The value indicates the relevance of the item's content if it's part of a metadata query result.
     
     The value is a floating point value between 0.0 and 1.0
     */
    public var queryContentRelevance: Double? {
        get { self.value(\.queryContentRelevance) } }
}

public extension MetadataItem {
    func setExplicity<V, K: KeyPath<MetadataItem, V?>>(_ keyPath: K, to value: V?) {
        var value = value
        if keyPath.mdItemKey == "kMDItemUserTags", let val = value as? [String]  {
            value = val.compactMap({$0 + "\n6"}) as? V
        }
        if keyPath == \.pixelSize, let value = value as? CGSize {
            self.setExplicity(\.pixelWidth, to: Double(value.width))
            self.setExplicity(\.pixelHeight, to: Double(value.height))
        } else {
            let key = "com.apple.metadata:" + keyPath.mdItemKey
            self.url?.extendedAttributes[key] = value
        }
    }
    
    func getExplicity<V: Any, K: KeyPath<MetadataItem, V?>>(_ keyPath: K) -> V? {
        let key = "com.apple.metadata:" + keyPath.mdItemKey
        var value: V? = self.url?.extendedAttributes[key]
        if keyPath.mdItemKey == "kMDItemUserTags", let val = value as? [String]  {
            value = val.compactMap({$0.replacingOccurrences(of: "\n6", with:"")}) as? V
        }
        return value
    }
    
    
    subscript<T>(key: String, initalValue: T? = nil) -> T?  {
        get {
            guard let _url = self.url ?? self.url  else { return nil }
            return _url.extendedAttributes[key]
        }
        set {
            guard let _url = self.url ?? self.url  else { return }
            _url.extendedAttributes[key] = newValue
        }
    }
    
     func availableExtendedAttributes() throws -> [String] {
        guard let _url = self.url ?? self.url  else { return [] }
       return try _url.extendedAttributes.listExtendedAttributes()
    }
}

extension MetadataItem: Hashable {
    public static func == (lhs: MetadataItem, rhs: MetadataItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.item)
    }
}
