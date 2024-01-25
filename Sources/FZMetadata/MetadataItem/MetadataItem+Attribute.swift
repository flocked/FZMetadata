//
//  MetadataItem+Attribute.swift
//
//
//  Created by Florian Zand on 28.08.22.
//

import Foundation
import FZSwiftUtils

public extension MetadataItem {
    /// The attribute of metadata item.
    enum Attribute: String, Hashable, CustomStringConvertible {
        public var description: String {
            rawValue.replacingOccurrences(of: "kMDItem", with: "").lowercasedFirst()
        }
        
        // MARK: - Common

        /// The url of the file.
        case url = "kMDItemURL"
        /// The full path of the file.
        case path = "kMDItemPath"
        /// The name of the file including the extension.
        case fileName = "kMDItemFSName"
        /// The display name of the file, which may be different then the file system name.
        case displayName = "kMDItemDisplayName"
        /// The alternative names of the file.
        case alternateNames = "kMDItemAlternateNames"
        /// The extension of the file.
        case fileExtension = "_kMDItemFSName"
        /// The size of the file.
        case fileSize = "kMDItemFSSize"
        /// A Boolean value that indicates whether the file is invisible.
        case fileIsInvisible = "kMDItemFSInvisible"
        /// A Boolean value that indicates whether the file extension is hidden.
        case fileExtensionIsHidden = "kMDItemFSIsExtensionHidden"
        /// The file type. For example: `video`, `document` or `directory`
        case fileType = "_kMDItemContentTypeTree"
        /// The content type of the file.
        case contentType = "kMDItemContentType"
        /// The content type tree of the file.
        case contentTypeTree = "kMDItemContentTypeTree"
        /// The date that the file was created.
        case creationDate = "kMDItemFSCreationDate"
        /// The last date that the file was used.
        case lastUsedDate = "kMDItemLastUsedDate"
        /// The dates the file was last used.
        case lastUsageDates = "kMDItemUsedDates"
        /// The last date that the attributes of the file were changed.
        case attributeModificationDate = "kMDItemAttributeChangeDate"
        /// The date that the content of the file was created.
        case contentCreationDate = "kMDItemContentCreationDate"
        /// The last date that the content of the file was changed.
        case contentChangeDate = "kMDItemFSContentChangeDate"
        /// The last date that the content of the file was modified.
        case contentModificationDate = "kMDItemContentModificationDate"
        /// The date the file was created, or renamed into or within its parent directory.
        case addedDate = "kMDItemDateAdded"
        /// The date that the file was downloaded.
        case downloadedDate = "kMDItemDownloadedDate"
        /// The date that the file was purchased.
        case purchaseDate = "kMDItemPurchaseDate"
        /// The date that this item is due (e.g. for a calendar event file).
        case dueDate = "kMDItemDueDate"
        /// The number of files in a directory.
        case directoryFilesCount = "kMDItemFSNodeCount"
        ///  A description of the content of the item. The description may include an abstract, table of contents, reference to a graphical representation of content or a free-text account of the content.
        case description = "kMDItemDescription"
        /// A description of the kind of item the file represents.
        case kind = "kMDItemKind"
        /// Information of this item.
        case information = "kMDItemInformation"
        /// The formal identifier used to reference the item within a given context.
        case identifier = "kMDItemIdentifier"
        /// The keywords associated with the file. For example: `Birthday` or `Important`.
        case keywords = "kMDItemwords"
        /// The title of the file. For example, this could be the title of a document, the name of a song, or the subject of an email message.
        case title = "kMDItemTitle"
        /// The title for a collection of media. This is analagous to a record album, or photo album.
        case album = "kMDItemAlbum"
        /// The authors, artists, etc. of the contents of the file.
        case authors = "kMDItemAuthors"
        /// The version of the file.
        case version = "kMDItemVersion"
        /// A comment related to the file. This differs from `finderComment`.
        case comment = "kMDItemComment"
        /// The user rating of the file. For example, the stars rating of an iTunes track.
        case starRating = "kMDItemStarRating"
        /// A describes where the file was obtained from. For example download urls.
        case whereFroms = "kMDItemWhereFroms"
        /// The finder comment of the file. This differs from the `comment`.
        case finderComment = "kMDItemFinderComment"
        /// The finder tags of the file.
        case finderTags = "kMDItemUserTags"
        /// The primary (first) finder tag color.
        case finderTagPrimaryColor = "kMDItemFSLabel"
        /// A Boolean value that indicates whether the file has a custom icon.
        case hasCustomIcon = "kMDItemFSHasCustomIcon"
        /// The number of usages of the file.
        case usageCount = "kMDItemUseCount"
        /// The bundle identifier of this item. If this item is a bundle, then this is the `CFBundleIdentifier`.
        case bundleIdentifier = "kMDItemCFBundleIdentifier"
        /// The architectures this item requires to execute.
        case executableArchitectures = "kMDItemExecutableArchitectures"
        /// The platform this item requires to execute.
        case executablePlatform = "kMDItemExecutablePlatform"
        /// The application used to convert the original content into it's current form. For example, a PDF file might have an encoding application set to "Distiller".
        case encodingApplications = "kMDItemEncodingApplications"
        /// The categories the application is a member of.
        case applicationCategories = "kMDItemApplicationCategories"
        /// A Boolean value that indicates whether the file is owned and managed by an application.
        case isApplicationManaged = "kMDItemIsApplicationManaged"
        /// The AppStore category of this item if it's an application from the AppStore.
        case appstoreCategory = "kMDItemAppStoreCategory"
        /// The AppStore category type of this item if it's an application from the AppStore.
        case appstoreCategoryType = "kMDItemAppStoreCategoryType"

        // MARK: - Document

        /// A text representation of the content of the document.
        case textContent = "kMDItemTextContent"
        /// The subject of the this item
        case subject = "kMDItemSubject"
        /// The theme of the this item.
        case theme = "kMDItemTheme"
        /// A publishable summary of the contents of the item.
        case headline = "kMDItemHeadline"
        /// the application or operation system used to create the document content. For example: `Word`,  `Pages` or `16.2`.
        case creator = "kMDItemCreator"
        /// Other information concerning this item, such as handling instructions.
        case instructions = "kMDItemInstructions"
        /// The editors of the contents of the file.
        case editors = "kMDItemEditors"
        /// The audience for which the file is intended. The audience may be determined by the creator or the publisher or by a third party.
        case audiences = "kMDItemAudiences"
        /// The extent or scope of the content of the document.
        case coverage = "kMDItemCoverage"
        /// The list of projects that the file is part of. For example, if you were working on a movie all of the files could be marked as belonging to the project `My Movie`.
        case projects = "kMDItemProjects"
        /// The number of pages in the document.
        case numberOfPages = "kMDItemNumberOfPages"
        /// The width of the document page, in points (72 points per inch). For PDF files this indicates the width of the first page only.
        case pageWidth = "kMDItemPageWidth"
        /// The height of the document page, in points (72 points per inch). For PDF files this indicates the height of the first page only.
        case pageHeight = "kMDItemPageHeight"
        /// The copyright owner of the file contents.
        case copyright = "kMDItemCopyright"
        /// The names of the fonts used in his document.
        case fonts = "kMDItemFonts"
        /// The family name of the font used in this document.
        case fontFamilyName = "com_apple_ats_name_family"
        /// A list of contacts that are associated with this document, not including the authors.
        case contactKeywords = "kMDItemContactKeywords"
        /// The languages of the intellectual content of the resource.
        case languages = "kMDItemLanguages"
        /// A link to information about rights held in and over the resource.
        case rights = "kMDItemRights"
        /// The company or organization that created the document.
        case organizations = "kMDItemOrganizations"
        /// The entity responsible for making this item available. For example, a person, an organization, or a service. Typically, the name of a publisher should be used to indicate the entity.
        case publishers = "kMDItemPublishers"
        /// The email Addresses related to this document.
        case emailAddresses = "kMDItemEmailAddresses"
        /// The phone numbers related to this document.
        case phoneNumbers = "kMDItemPhoneNumbers"
        /// The people or organizations contributing to the content of the document.
        case contributors = "kMDItemContributors"
        /// The security or encryption method used for the document.
        case securityMethod = "kMDItemSecurityMethod"

        // MARK: - Places

        /// The full, publishable name of the country or region where the intellectual property of this item was created, according to guidelines of the provider.
        case country = "kMDItemCountry"
        /// The city.of this document.
        case city = "kMDItemCity"
        /// The province or state of origin according to guidelines established by the provider. For example: `CA`, `Ontario` or `Sussex`.
        case stateOrProvince = "kMDItemStateOrProvince"
        /// The area information of the file.
        case areaInformation = "kMDItemGPSAreaInformation"
        /// The name of the location or point of interest associated with the
        case namedLocation = "kMDItemNamedLocation"
        /// The altitude of this item in meters above sea level, expressed using the WGS84 datum. Negative values lie below sea level.
        case altitude = "kMDItemAltitude"
        /// The latitude of this item in degrees north of the equator, expressed using the WGS84 datum. Negative values lie south of the equator.
        case latitude = "kMDItemLatitude"
        /// The longitude of this item in degrees east of the prime meridian, expressed using the WGS84 datum. Negative values lie west of the prime meridian.
        case longitude = "kMDItemLongitude"
        /// The speed of this item, in kilometers per hour.
        case speed = "kMDItemSpeed"
        /// The timestamp on the item  This generally is used to indicate the time at which the event captured by this item took place.
        case timestamp = "kMDItemTimestamp"
        /// The direction of travel of this item, in degrees from true north.
        case gpsTrack = "kMDItemGPSTrack"
        /// The gps status of this item.
        case gpsStatus = "kMDItemGPSStatus"
        /// The gps measure mode of this item.
        case gpsMeasureMode = "kMDItemGPSMeasureMode"
        /// The gps dop of this item.
        case gpsDop = "kMDItemGPSDOP"
        /// The gps map datum of this item.
        case gpsMapDatum = "kMDItemGPSMapDatum"
        /// The gps destination latitude of this item.
        case gpsDestLatitude = "kMDItemGPSDestLatitude"
        /// The gps destination longitude of this item.
        case gpsDestLongitude = "kMDItemGPSDestLongitude"
        /// The gps destination bearing of this item.
        case gpsDestBearing = "kMDItemGPSDestBearing"
        /// The gps destination distance of this item.
        case gpsDestDistance = "kMDItemGPSDestDistance"
        /// The gps processing method of this item.
        case gpsProcessingMethod = "kMDItemGPSProcessingMethod"
        /// The gps date stamp of this item.
        case gpsDateStamp = "kMDItemGPSDateStamp"
        /// The gps differental of this item.
        case gpsDifferental = "kMDItemGPSDifferental"

        // MARK: - Audio

        /// The sample rate of the audio data contained in the file. The sample rate representing `audio_frames/second`. For example: `44100.0`, `22254.54`.
        case audioSampleRate = "kMDItemAudioSampleRate"
        /// The number of channels in the audio data contained in the file.
        case audioChannelCount = "kMDItemAudioChannelCount"
        /// The tempo that specifies the beats per minute of the music contained in the audio file.
        case tempo = "kMDItemTempo"
        /// The key of the music contained in the audio file. For example: `C`, `Dm`, `F#, `Bb`.
        case keySignature = "kMDItemSignature"
        /// The time signature of the musical composition contained in the audio/MIDI file. For example: `4/4`, `7/8`.
        case timeSignature = "kMDItemTimeSignature"
        /// The name of the application that encoded the data of a audio file.
        case audioEncodingApplication = "kMDItemAudioEncodingApplication"
        /// The track number of a song or composition when it is part of an album.
        case trackNumber = "kMDItemAudioTrackNumber"
        /// The composer of the music contained in the audio file.
        case composer = "kMDItemComposer"
        /// The lyricist, or text writer, of the music contained in the audio file.
        case lyricist = "kMDItemLyricist"
        /// The recording date of the song or composition.
        case recordingDate = "kMDItemRecordingDate"
        /// Indicates the year this item was recorded. For example: `1964`, `2003`.
        case recordingYear = "kMDItemRecordingYear"
        /// The musical genre of the song or composition contained in the audio file. For example: `Jazz`, `Pop`, `Rock`, `Classical`.
        case musicalGenre = "kMDItemMusicalGenre"
        /// A Boolean value that indicates whether the MIDI sequence contained in the file is setup for use with a General MIDI device.
        case isGeneralMidiSequence = "kMDItemIsGeneralMIDISequence"
        /// The original key of an Apple loop. The key is the root note or tonic for the loop, and does not include the scale type.
        case appleLoopsRootKey = "kMDItemAppleLoopsRootKey"
        /// The key filtering information of an Apple loop. Loops are matched against projects that often in a major or minor key.
        case appleLoopsKeyFilterType = "kMDItemAppleLoopsKeyFilterType"
        /// The looping mode of an Apple loop.
        case appleLoopsLoopMode = "kMDItemAppleLoopsLoopMode"
        /// The escriptive information of an Apple loop.
        case appleLoopDescriptors = "kMDItemAppleLoopDescriptors"
        /// The category of the instrument.
        case musicalInstrumentCategory = "kMDItemMusicalInstrumentCategory"
        /// The name of the instrument relative to the instrument category.
        case musicalInstrumentName = "kMDItemMusicalInstrumentName"

        // MARK: - Media

        /// The duration of the content of file. Usually for videos and audio.
        case duration = "kMDItemDurationSeconds"
        /// The media types (video, sound) present in the content.
        case mediaTypes = "kMDItemMediaTypes"
        /// The codecs used to encode/decode the media.
        case codecs = "kMDItemCodecs"
        /// The total bit rate, audio and video combined, of the media.
        case totalBitRate = "kMDItemTotalBitRate"
        /// The video bit rate of the media.
        case videoBitRate = "kMDItemVideoBitRate"
        /// The audio bit rate of the media.
        case audioBitRate = "kMDItemAudioBitRate"
        /// A Boolean value that indicates whether the media is prepared for streaming.
        case streamable = "kMDItemStreamable"
        /// The delivery type of the media. Either `Fast start` or `RTSP`.
        case mediaDeliveryType = "kMDItemDeliveryType"
        /// Original format of the media.
        case originalFormat = "kMDItemOriginalFormat"
        /// Original source of the media.
        case originalSource = "kMDItemOriginalSource"
        /// The director of the content.
        case director = "kMDItemDirector"
        /// The producer of the content.
        case producer = "kMDItemProducer"
        /// The genre of the content.
        case genre = "kMDItemGenre"
        /// The performers of the content.
        case performers = "kMDItemPerformers"
        /// The people that are visible in an image or movie or are written about in a document.
        case participants = "kMDItemParticipants"

        // MARK: - Image

        /// The pixel height of the contents. For example, the height of a image or video.
        case pixelHeight = "kMDItemPixelHeight"
        /// The pixel width of the contents. For example, the width of a image or video.
        case pixelWidth = "kMDItemPixelWidth"
        /// The pixel size of the contents. For example, the image size or the video frame size.
        case pixelSize = "_kMDItemPixelSize"
        /// The total number of pixels in the contents. Same as `pixelHeight x pixelWidth`.
        case pixelCount = "kMDItemPixelCount"
        /// The color space model used by the contents. For example: `RGB`, `CMYK`, `YUV`, or `YCbCr`.
        case colorSpace = "kMDItemColorSpace"
        /// The number of bits per sample. For example, the bit depth of an image (8-bit, 16-bit etc...) or the bit depth per audio sample of uncompressed audio data (8, 16, 24, 32, 64, etc..).
        case bitsPerSample = "kMDItemBitsPerSample"
        /// A Boolean value that indicates whether a camera flash was used.
        case flashOnOff = "kMDItemFlashOnOff"
        /// The actual focal length of the lens, in millimeters.
        case focalLength = "kMDItemFocalLength"
        /// The manufacturer of the device used for the contents. For example: `Apple`, `Canon`.
        case deviceManufacturer = "kMDItemAcquisitionMake"
        /// The model of the device used for the contents. For example: `iPhone 13`.
        case deviceModel = "kMDItemAcquisitionModel"
        /// The ISO speed used to acquire the contents.
        case isoSpeed = "kMDItemISOSpeed"
        /// The orientation of the contents.
        case orientation = "kMDItemOrientation"
        /// The names of the layers in the file.
        case layerNames = "kMDItemLayerNames"
        /// The aperture setting used to acquire the document contents. This unit is the APEX value.
        case aperture = "kMDItemAperture"
        /// The name of the color profile used by the document contents.
        case colorProfile = "kMDItemProfileName"
        /// The resolution width, in DPI, of the contents.
        case dpiResolutionWidth = "kMDItemResolutionWidthDPI"
        /// The resolution height, in DPI, of the contents.
        case dpiResolutionHeight = "kMDItemResolutionHeightDPI"
        /// The resolution size, in DPI, of the contents.
        case dpiResolution = "_kMDItemResolutionSizeDPI"
        /// The exposure mode used to acquire the contents.
        case exposureMode = "kMDItemExposureMode"
        /// The exposure time, in seconds, used to acquire the contents.
        case exposureTimeSeconds = "kMDItemExposureTimeSeconds"
        /// The version of the EXIF header used to generate the metadata.
        case exifVersion = "kMDItemEXIFVersion"
        /// The name of the camera company.
        case cameraOwner = "kMDItemCameraOwner"
        /// The actual focal length of the lens, in 35 millimeters.
        case focalLength35Mm = "kMDItemFocalLength35mm"
        /// The name of the camera lens model.
        case lensModel = "kMDItemLensModel"
        /// The direction of the item's image, in degrees from true north.
        case imageDirection = "kMDItemImageDirection"
        /// A Boolean value that indicates whether the image has an alpha channel.
        case hasAlphaChannel = "kMDItemHasAlphaChannel"
        /// A Boolean value that indicates whether a red-eye reduction was used to take the picture.
        case redEyeOnOff = "kMDItemRedEyeOnOff"
        /// The metering mode used to take the image.
        case meteringMode = "kMDItemMeteringMode"
        /// The smallest f-number of the lens. Ordinarily it is given in the range of 00.00 to 99.99.
        case maxAperture = "kMDItemMaxAperture"
        /// The diameter of the diaphragm aperture in terms of the effective focal length of the lens.
        case fNumber = "kMDItemFNumber"
        /// The class of the exposure program used by the camera to set exposure when the image is taken. Possible values include: Manual, Normal, and Aperture priority.
        case exposureProgram = "kMDItemExposureProgram"
        /// The time of the exposure of the imge.
        case exposureTimeString = "kMDItemExposureTimeString"
        /// A Boolean value that indicates whether the file is a screen capture.
        case isScreenCapture = "kMDItemIsScreenCapture"
        /// The screen capture rect of the file.
        case screenCaptureRect = "kMDItemScreenCaptureGlobalRect"
        /// The screen capture type of the file.
        case screenCaptureType = "kMDItemScreenCaptureType"
        /// The white balance setting of the camera when the picture was taken.
        case whiteBalance = "kMDItemWhiteBalance"

        // MARK: - Messages / Mail

        /// The email addresses for the authors of this item.
        case authorEmailAddresses = "kMDItemAuthorEmailAddresses"
        /// The addresses for the authors of this item.
        case authorAddresses = "kMDItemAuthorAddresses"
        /// The recipients of this item.
        case recipients = "kMDItemRecipients"
        /// The rmail addresses for the recipients of this item.
        case recipientEmailAddresses = "kMDItemRecipientEmailAddresses"
        /// The addresses for the recipients of this item.
        case recipientAddresses = "kMDItemRecipientAddresses"
        /// The instant message addresses related to this item.
        case instantMessageAddresses = "kMDItemInstantMessageAddresses"
        /// The received dates for this item.
        case receivedDates = "kMDItemUserSharedReceivedDate"
        /// The received recipients for this item.
        case receivedRecipients = "kMDItemUserSharedReceivedRecipient"
        /// Received recipient handles for this item.
        case receivedRecipientHandles = "kMDItemUserSharedReceivedRecipientHandle"
        /// The received sendesr for this item.
        case receivedSenders = "kMDItemUserSharedReceivedSender"
        /// The received sender handles for this item.
        case receivedSenderHandles = "kMDItemUserSharedReceivedSenderHandle"
        /// The received types for this item.
        case receivedTypes = "kMDItemUserSharedReceivedTransport"
        /// A Boolean value that indicates whether the file is likely to be considered a junk file.
        case isLikelyJunk = "kMDItemIsLikelyJunk"

        /**
         The relevance of the item's content, if it's part of a metadata query result.

         The value is a value between `0.0` and `1.0`.
         */
        case queryContentRelevance = "kMDQueryResultContentRelevance"

        static func values(for mdKeys: [String]) -> [Self] {
            var attriutes = mdKeys.compactMap { Self(rawValue: $0) }
            if attriutes.contains(all: [.pixelWidth, .pixelHeight]) {
                attriutes.replace(.pixelWidth, with: .pixelSize)
                attriutes.remove(.pixelHeight)
            }
            if attriutes.contains(all: [.dpiResolutionWidth, .dpiResolutionHeight]) {
                attriutes.replace(.dpiResolutionWidth, with: .dpiResolution)
                attriutes.remove(.dpiResolutionHeight)
            }
            return attriutes
        }

        var mdKeys: [String] {
            if rawValue.contains("_") {
                let value = rawValue.replacingOccurrences(of: "_", with: "")
                if rawValue.contains("Size") {
                    return [value.replacingOccurrences(of: "Size", with: "Width"), value.replacingOccurrences(of: "Size", with: "Height")]
                } else {
                    return [value]
                }
            }
            return [rawValue]
        }
    }
}

#if os(macOS)
import AppKit

// Currently unused
extension MetadataItem {
    class PredicateEditorRowTemplate: NSPredicateEditorRowTemplate {
        let attribute: MetadataItem.Attribute
        init(attribute: MetadataItem.Attribute) {
            self.attribute = attribute
            super.init()
        }
                
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension MetadataItem.Attribute {
    var rowTemplate: NSPredicateEditorRowTemplate {
        switch self {
        default:
            return NSPredicateEditorRowTemplate(constant: "Template", values: ["Value"])
        }
    }
    
    var valueType: ValueType {
        switch self {
        case .dueDate, .addedDate, .creationDate, .purchaseDate, .receivedDates, .recordingDate, .downloadedDate, .lastUsedDate, .lastUsageDates, .contentChangeDate, .contentCreationDate, .contentModificationDate, .attributeModificationDate, .timestamp, .gpsDateStamp:
            return .date
        case .isLikelyJunk, .isScreenCapture, .isApplicationManaged, .isGeneralMidiSequence, .fileIsInvisible, .fileExtensionIsHidden, .hasCustomIcon, .hasAlphaChannel, .streamable, .flashOnOff, .redEyeOnOff:
            return .bool
        case .usageCount, .audioChannelCount, .fileSize, .directoryFilesCount, .finderTagPrimaryColor, .trackNumber:
            return .integer
        case .starRating, .numberOfPages, .pageWidth, .pageHeight, .pixelSize, .pixelWidth, .pixelHeight, .dpiResolutionWidth, .dpiResolutionHeight, .dpiResolution, .securityMethod, .altitude, .latitude, .longitude, .gpsDestLatitude, .gpsDestLongitude, .speed, .gpsTrack, .gpsDop, .gpsDestBearing, .gpsDestDistance, .gpsDifferental, .audioSampleRate, .tempo, .recordingYear, .duration, .totalBitRate, .videoBitRate, .audioBitRate, .pixelCount, .bitsPerSample, .focalLength, .isoSpeed, .aperture, .exposureMode, .exposureTimeSeconds, .focalLength35Mm, .imageDirection, .maxAperture, .fNumber, .screenCaptureRect, .queryContentRelevance:
            return .double
        case .orientation:
            return .value(["Horizontal", "Vertical"])
        case .whiteBalance:
            return .value(["Auto", "Off"])
        case .screenCaptureType:
            return .value(["Display", "Window", "Selection"])
        case .fileType:
            let fileTypes: [FileType] = [.archive, .executable, .image, .document, .video, .audio, .folder, .pdf, .presentation, .application, .text]
          let values = ["Any"] + fileTypes.compactMap({$0.description}) + ["Other"]
            return .value(values)
        default: return .string
        }
    }
    
    enum ValueType {
        case string
        case double
        case integer
        case bool
        case date
        case value([String])
        
        var operators: [NSComparisonPredicate.Operator] {
            switch self {
            case .string:
                return [.matches, .contains, .beginsWith, .endsWith, .equalTo, .notEqualTo]
            case .double, .integer, .date:
                return [.equalTo, .lessThan, .greaterThan, .notEqualTo]
            case .bool, .value:
                return [.equalTo, .notEqualTo]
            }
        }
        
        var options: NSComparisonPredicate.Options {
            switch self {
            case .string: return [.caseInsensitive, .diacriticInsensitive]
            default: return []
            }
        }
    }
}
#endif
