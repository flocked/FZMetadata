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
    enum Attribute: String, Hashable, CustomStringConvertible, CaseIterable {
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
        case fileExtension = "kMDItemFSExtension"
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
        
        // MARK: - iCloud
        
        /// A Boolean indicating whether the item is stored in the cloud.
        case isUbiquitousItem = "NSMetadataItemIsUbiquitousKey"
        /// The name of the item’s container as the system displays it to users.
        case ubiquitousItemContainerDisplayName = "NSMetadataUbiquitousItemContainerDisplayNameKey"
        /// A Boolean value that indicates whether the user or the system requests a download of the item.
        case ubiquitousItemDownloadRequested = "NSMetadataUbiquitousItemDownloadRequestedKey"
        case ubiquitousItemIsExternalDocument = "NSMetadataUbiquitousItemIsExternalDocumentKey"
        case ubiquitousItemURLInLocalContainer = "NSMetadataUbiquitousItemURLInLocalContainerKey"
        /// A Boolean value that indicates whether the item has outstanding conflicts.
        case ubiquitousItemHasUnresolvedConflicts = "NSMetadataUbiquitousItemHasUnresolvedConflictsKey"
        case ubiquitousItemIsDownloaded = "NSMetadataUbiquitousItemIsDownloadedKey"
        /// A Boolean value that indicates whether the system is downloading the item.
        case ubiquitousItemIsDownloading = "NSMetadataUbiquitousItemIsDownloadingKey"
        /// A Boolean value that indicates whether data is present in the cloud for the item.
        case ubiquitousItemIsUploaded = "NSMetadataUbiquitousItemIsUploadedKey"
        /// A Boolean value that indicates whether the system is uploading the item.
        case ubiquitousItemIsUploading = "NSMetadataUbiquitousItemIsUploadingKey"
        /// The percentage of the file that has already been downloaded from the cloud.
        case ubiquitousItemPercentDownloaded = "NSMetadataUbiquitousItemPercentDownloadedKey"
        /// The percentage of the file that has already been downloaded from the cloud.
        case ubiquitousItemPercentUploaded = "NSMetadataUbiquitousItemPercentUploadedKey"
        /// The download status of the item.
        case ubiquitousItemDownloadingStatus = "NSMetadataUbiquitousItemDownloadingStatusKey"
        /// The error when downloading the item from iCloud fails.
        case ubiquitousItemDownloadingError = "NSMetadataUbiquitousItemDownloadingErrorKey"
        /// The error when uploading the item to iCloud fails.
        case ubiquitousItemUploadingError = "NSMetadataUbiquitousItemUploadingErrorKey"
        /// A Boolean value that indicates a shared item.
        case ubiquitousItemIsShared = "NSMetadataUbiquitousItemIsSharedKey"
        /// The current user’s permissions for the shared item.
        case ubiquitousSharedItemCurrentUserPermissions = "NSMetadataUbiquitousSharedItemCurrentUserPermissionsKey"
        case ubiquitousSharedItemCurrentUserRole = "NSMetadataUbiquitousSharedItemCurrentUserRoleKey"
        case ubiquitousSharedItemMostRecentEditorNameComponents = "NSMetadataUbiquitousSharedItemMostRecentEditorNameComponentsKey"
        case ubiquitousSharedItemOwnerNameComponents = "NSMetadataUbiquitousSharedItemOwnerNameComponentsKey"
        
        // MARK: - Query Content Relevance
        
        /**
         The relevance of the item's content, if it's part of a metadata query results that is sorted by this attribute.
         
         The value is a value between `0.0` and `1.0`.
         */
        case queryContentRelevance = "NSMetadataQueryResultContentRelevanceAttribute"
        
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
        
        var keyPath: PartialKeyPath<MetadataItem> {
            switch self {
                // MARK: - Common
            case .url: return \.url
            case .path: return \.path
            case .fileName: return \.fileName
            case .displayName: return \.displayName
            case .alternateNames: return \.alternateNames
            case .fileExtension: return \.fileExtension
            case .fileSize: return \.fileSize
            case .fileIsInvisible: return \.fileIsInvisible
            case .fileExtensionIsHidden: return \.fileExtensionIsHidden
            case .fileType: return \.fileType
            case .contentType:
                if  #available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *) {
                    return \.contentType
                } else {
                    return \.fileName
                }
            case .contentTypeTree:
                if  #available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *) {
                    return \.contentTypeTree
                } else {
                    return \.fileName
                }
            case .creationDate: return \.creationDate
            case .lastUsedDate: return \.lastUsedDate
            case .lastUsageDates: return \.lastUsageDates
            case .attributeModificationDate: return \.attributeModificationDate
            case .contentCreationDate: return \.contentCreationDate
            case .contentChangeDate: return \.contentChangeDate
            case .contentModificationDate: return \.contentModificationDate
            case .addedDate: return \.addedDate
            case .downloadedDate: return \.downloadedDate
            case .purchaseDate: return \.purchaseDate
            case .dueDate: return \.dueDate
            case .directoryFilesCount: return \.directoryFilesCount
            case .description: return \.description
            case .kind: return \.kind
            case .information: return \.information
            case .identifier: return \.identifier
            case .keywords: return \.keywords
            case .title: return \.title
            case .album: return \.album
            case .authors: return \.authors
            case .version: return \.version
            case .comment: return \.comment
            case .starRating: return \.starRating
            case .whereFroms: return \.whereFroms
            case .finderComment: return \.finderComment
            case .finderTags: return \.finderTags
            case .finderTagPrimaryColor: return \.finderTagPrimaryColor
            case .hasCustomIcon: return \.hasCustomIcon
            case .usageCount: return \.usageCount
            case .bundleIdentifier: return \.bundleIdentifier
            case .executableArchitectures: return \.executableArchitectures
            case .executablePlatform: return \.executablePlatform
            case .encodingApplications: return \.encodingApplications
            case .applicationCategories: return \.applicationCategories
            case .isApplicationManaged: return \.isApplicationManaged
            case .appstoreCategory: return \.appstoreCategory
            case .appstoreCategoryType: return \.appstoreCategoryType
                
                // MARK: - Document
            case .textContent: return \.textContent
            case .subject: return \.subject
            case .theme: return \.theme
            case .headline: return \.headline
            case .creator: return \.creator
            case .instructions: return \.instructions
            case .editors: return \.editors
            case .audiences: return \.audiences
            case .coverage: return \.coverage
            case .projects: return \.projects
            case .numberOfPages: return \.numberOfPages
            case .pageWidth: return \.pageWidth
            case .pageHeight: return \.pageHeight
            case .copyright: return \.copyright
            case .fonts: return \.fonts
            case .fontFamilyName: return \.fontFamilyName
            case .contactKeywords: return \.contactKeywords
            case .languages: return \.languages
            case .rights: return \.rights
            case .organizations: return \.organizations
            case .publishers: return \.publishers
            case .emailAddresses: return \.emailAddresses
            case .phoneNumbers: return \.phoneNumbers
            case .contributors: return \.contributors
            case .securityMethod: return \.securityMethod
                
                // MARK: - Places
            case .country: return \.country
            case .city: return \.city
            case .stateOrProvince: return \.stateOrProvince
            case .areaInformation: return \.areaInformation
            case .namedLocation: return \.namedLocation
            case .altitude: return \.altitude
            case .latitude: return \.latitude
            case .longitude: return \.longitude
            case .speed: return \.speed
            case .timestamp: return \.timestamp
            case .gpsTrack: return \.gpsTrack
            case .gpsStatus: return \.gpsStatus
            case .gpsMeasureMode: return \.gpsMeasureMode
            case .gpsDop: return \.gpsDop
            case .gpsMapDatum: return \.gpsMapDatum
            case .gpsDestLatitude: return \.gpsDestLatitude
            case .gpsDestLongitude: return \.gpsDestLongitude
            case .gpsDestBearing: return \.gpsDestBearing
            case .gpsDestDistance: return \.gpsDestDistance
            case .gpsProcessingMethod: return \.gpsProcessingMethod
            case .gpsDateStamp: return \.gpsDateStamp
            case .gpsDifferental: return \.gpsDifferental
                
                // MARK: - Audio
            case .audioSampleRate: return \.audioSampleRate
            case .audioChannelCount: return \.audioChannelCount
            case .tempo: return \.tempo
            case .keySignature: return \.keySignature
            case .timeSignature: return \.timeSignature
            case .audioEncodingApplication: return \.audioEncodingApplication
            case .trackNumber: return \.trackNumber
            case .composer: return \.composer
            case .lyricist: return \.lyricist
            case .recordingDate: return \.recordingDate
            case .recordingYear: return \.recordingYear
            case .musicalGenre: return \.musicalGenre
            case .isGeneralMidiSequence: return \.isGeneralMidiSequence
            case .appleLoopsRootKey: return \.appleLoopsRootKey
            case .appleLoopsKeyFilterType: return \.appleLoopsKeyFilterType
            case .appleLoopsLoopMode: return \.appleLoopsLoopMode
            case .appleLoopDescriptors: return \.appleLoopDescriptors
            case .musicalInstrumentCategory: return \.musicalInstrumentCategory
            case .musicalInstrumentName: return \.musicalInstrumentName
                
                // MARK: - Media
            case .duration: return \.duration
            case .mediaTypes: return \.mediaTypes
            case .codecs: return \.codecs
            case .totalBitRate: return \.totalBitRate
            case .videoBitRate: return \.videoBitRate
            case .audioBitRate: return \.audioBitRate
            case .streamable: return \.streamable
            case .mediaDeliveryType: return \.mediaDeliveryType
            case .originalFormat: return \.originalFormat
            case .originalSource: return \.originalSource
            case .director: return \.director
            case .producer: return \.producer
            case .genre: return \.genre
            case .performers: return \.performers
            case .participants: return \.participants
                
                // MARK: - Image
            case .pixelHeight: return \.pixelHeight
            case .pixelWidth: return \.pixelWidth
            case .pixelSize: return \.pixelSize
            case .pixelCount: return \.pixelCount
            case .colorSpace: return \.colorSpace
            case .bitsPerSample: return \.bitsPerSample
            case .flashOnOff: return \.flashOnOff
            case .focalLength: return \.focalLength
            case .deviceManufacturer: return \.deviceManufacturer
            case .deviceModel: return \.deviceModel
            case .isoSpeed: return \.isoSpeed
            case .orientation: return \.orientation
            case .layerNames: return \.layerNames
            case .aperture: return \.aperture
            case .colorProfile: return \.colorProfile
            case .dpiResolutionWidth: return \.dpiResolutionWidth
            case .dpiResolutionHeight: return \.dpiResolutionHeight
            case .dpiResolution: return \.dpiResolution
            case .exposureMode: return \.exposureMode
            case .exposureTimeSeconds: return \.exposureTimeSeconds
            case .exifVersion: return \.exifVersion
            case .cameraOwner: return \.cameraOwner
            case .focalLength35Mm: return \.focalLength35Mm
            case .lensModel: return \.lensModel
            case .imageDirection: return \.imageDirection
            case .hasAlphaChannel: return \.hasAlphaChannel
            case .redEyeOnOff: return \.redEyeOnOff
            case .meteringMode: return \.meteringMode
            case .maxAperture: return \.maxAperture
            case .fNumber: return \.fNumber
            case .exposureProgram: return \.exposureProgram
            case .exposureTimeString: return \.exposureTimeString
            case .isScreenCapture: return \.isScreenCapture
            case .screenCaptureRect: return \.screenCaptureRect
            case .screenCaptureType: return \.screenCaptureType
            case .whiteBalance: return \.whiteBalance
                
                // MARK: - Messages / Mail
            case .authorEmailAddresses: return \.authorEmailAddresses
            case .authorAddresses: return \.authorAddresses
            case .recipients: return \.recipients
            case .recipientEmailAddresses: return \.recipientEmailAddresses
            case .recipientAddresses: return \.recipientAddresses
            case .instantMessageAddresses: return \.instantMessageAddresses
            case .receivedDates: return \.receivedDates
            case .receivedRecipients: return \.receivedRecipients
            case .receivedRecipientHandles: return \.receivedRecipientHandles
            case .receivedSenders: return \.receivedSenders
            case .receivedSenderHandles: return \.receivedSenderHandles
            case .receivedTypes: return \.receivedTypes
            case .isLikelyJunk: return \.isLikelyJunk
                
                // MARK: - iCloud
            case .isUbiquitousItem: return \.isUbiquitousItem
            case .ubiquitousItemContainerDisplayName: return \.ubiquitousItemContainerDisplayName
            case .ubiquitousItemDownloadRequested: return \.ubiquitousItemDownloadRequested
            case .ubiquitousItemIsExternalDocument: return \.ubiquitousItemIsExternalDocument
            case .ubiquitousItemURLInLocalContainer: return \.ubiquitousItemURLInLocalContainer
            case .ubiquitousItemHasUnresolvedConflicts: return \.ubiquitousItemHasUnresolvedConflicts
            case .ubiquitousItemIsDownloaded: return \.ubiquitousItemIsDownloaded
            case .ubiquitousItemIsDownloading: return \.ubiquitousItemIsDownloading
            case .ubiquitousItemIsUploaded: return \.ubiquitousItemIsUploaded
            case .ubiquitousItemIsUploading: return \.ubiquitousItemIsUploading
            case .ubiquitousItemPercentDownloaded: return \.ubiquitousItemPercentDownloaded
            case .ubiquitousItemPercentUploaded: return \.ubiquitousItemPercentUploaded
            case .ubiquitousItemDownloadingStatus: return \.ubiquitousItemDownloadingStatus
            case .ubiquitousItemDownloadingError: return \.ubiquitousItemDownloadingError
            case .ubiquitousItemUploadingError: return \.ubiquitousItemUploadingError
            case .ubiquitousItemIsShared: return \.ubiquitousItemIsShared
            case .ubiquitousSharedItemCurrentUserPermissions: return \.ubiquitousSharedItemCurrentUserPermissions
            case .ubiquitousSharedItemCurrentUserRole: return \.ubiquitousSharedItemCurrentUserRole
            case .ubiquitousSharedItemMostRecentEditorNameComponents: return \.ubiquitousSharedItemMostRecentEditorNameComponents
            case .ubiquitousSharedItemOwnerNameComponents: return \.ubiquitousSharedItemOwnerNameComponents
                
                // MARK: - Query Content Relevance
                case .queryContentRelevance: return \.queryContentRelevance }
        }
    }
}

extension PartialKeyPath where Root == MetadataItem {
    /// The metadata query key for the attribute at the key path.
    var mdItemKey: String {
        var key = MetadataItem.Attribute.allCases.first(where: {$0.keyPath == self})?.rawValue ?? MetadataItem.Attribute.fileName.rawValue
        if key.hasPrefix("_") {
            key = String(key.dropFirst())
        }
        return key
    }
}

/*
 "**"                        = "Any Text";
 "kHSMDItemContentKind"        = "Content Kind";
 "kHSMDItemDisplayNames"        = "Name";
 "kHSMDItemFSFileExtension"    = "File Extension";
 "kHSMDItemKeywordsAndTags"    = "Keywords & Tags";
 "kHSMDItemHasAttachment"    = "Has Attachment";x
 */
