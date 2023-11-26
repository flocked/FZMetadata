//
//  MetadataItem+Attribute.swift
//
//
//  Created by Florian Zand on 28.08.22.
//

import Foundation

extension MetadataItem     {
    public enum Attribute: String, CaseIterable, Comparable, Hashable {
        // MARK: - Common
        case url = "kMDItemURL"
        case path = "kMDItemPath"
        case fileName = "kMDItemFSName"
        case displayName = "kMDItemDisplayName"
        case alternateNames = "kMDItemAlternateNames"
        case fileExtension = "_kMDItemFSName"
     //   case fileSizeBytes = "kMDItemFSSize"
        case fileSize = "kMDItemFSSize"
        case fileIsInvisible = "kMDItemFSInvisible"
        case fileExtensionIsHidden = "kMDItemFSIsExtensionHidden"
        case fileType = "_kMDItemContentTypeTree"
        case contentType = "kMDItemContentType"
        case contentTypeTree = "kMDItemContentTypeTree"
       // case contentUTType = "_kMDItemContentType"
        case creationDate = "kMDItemFSCreationDate"
        case lastUsedDate = "kMDItemLastUsedDate"
        case lastUsageDates = "kMDItemUsedDates"
        case metadataModificationDate = "kMDItemAttributeChangeDate"
        case contentCreationDate = "kMDItemContentCreationDate"
        case contentChangeDate = "kMDItemFSContentChangeDate"
        case contentModificationDate = "kMDItemContentModificationDate"
        case dateAdded = "kMDItemDateAdded"
        case downloadedDate = "kMDItemDownloadedDate"
        case purchaseDate = "kMDItemPurchaseDate"
        case dueDate = "kMDItemDueDate"
        case directoryFilesCount = "kMDItemFSNodeCount"
        case description = "kMDItemDescription"
        case kind = "kMDItemKind"
        case information = "kMDItemInformation"
        case identifier = "kMDItemIdentifier"
        case keywords = "kMDItemwords"
        case title = "kMDItemTitle"
        case album = "kMDItemAlbum"
        case authors = "kMDItemAuthors"
        case version = "kMDItemVersion"
        case comment = "kMDItemComment"
        case starRating = "kMDItemStarRating"
        case whereFroms = "kMDItemWhereFroms"
        case finderComment = "kMDItemFinderComment"
        case finderTags = "kMDItemUserTags"
        case finderPrimaryTagColor = "kMDItemFSLabel"
        case hasCustomIcon = "kMDItemFSHasCustomIcon"
        case usageCount = "kMDItemUseCount"
        case bundleIdentifier = "kMDItemCFBundleIdentifier"
        case executableArchitectures = "kMDItemExecutableArchitectures"
        case executablePlatform = "kMDItemExecutablePlatform"
        case encodingApplications = "kMDItemEncodingApplications"
        case applicationCategories = "kMDItemApplicationCategories"
        case isApplicationManaged = "kMDItemIsApplicationManaged"
        case appstoreCategory = "kMDItemAppStoreCategory"
        case appstoreCategoryType = "kMDItemAppStoreCategoryType"
        
        // MARK: - Document
        case textContent = "kMDItemTextContent"
        case subject = "kMDItemSubject"
        case theme = "kMDItemTheme"
        case headline = "kMDItemHeadline"
        case creator = "kMDItemCreator"
        case instructions = "kMDItemInstructions"
        case editors = "kMDItemEditors"
        case audiences = "kMDItemAudiences"
        case coverage = "kMDItemCoverage"
        case projects = "kMDItemProjects"
        case numberOfPages = "kMDItemNumberOfPages"
        case pageWidth = "kMDItemPageWidth"
        case pageHeight = "kMDItemPageHeight"
        case copyright = "kMDItemCopyright"
        case fonts = "kMDItemFonts"
        case fontFamilyName = "com_apple_ats_name_family"
        case contactKeywords = "kMDItemContactKeywords"
        case languages = "kMDItemLanguages"
        case rights = "kMDItemRights"
        case organizations = "kMDItemOrganizations"
        case publishers = "kMDItemPublishers"
        case emailAddresses = "kMDItemEmailAddresses"
        case phoneNumbers = "kMDItemPhoneNumbers"
        case contributors = "kMDItemContributors"
        case securityMethod = "kMDItemSecurityMethod"
        
        // MARK: - Places
        case country = "kMDItemCountry"
        case city = "kMDItemCity"
        case stateOrProvince = "kMDItemStateOrProvince"
        case areaInformation = "kMDItemGPSAreaInformation"
        case namedLocation = "kMDItemNamedLocation"
        case altitude = "kMDItemAltitude"
        case latitude = "kMDItemLatitude"
        case longitude = "kMDItemLongitude"
        case speed = "kMDItemSpeed"
        case timestamp = "kMDItemTimestamp"
        case gpsTrack = "kMDItemGPSTrack"
        case gpsStatus = "kMDItemGPSStatus"
        case gpsMeasureMode = "kMDItemGPSMeasureMode"
        case gpsDop = "kMDItemGPSDOP"
        case gpsMapDatum = "kMDItemGPSMapDatum"
        case gpsDestLatitude = "kMDItemGPSDestLatitude"
        case gpsDestLongitude = "kMDItemGPSDestLongitude"
        case gpsDestBearing = "kMDItemGPSDestBearing"
        case gpsDestDistance = "kMDItemGPSDestDistance"
        case gpsProcessingMethod = "kMDItemGPSProcessingMethod"
        case gpsDateStamp = "kMDItemGPSDateStamp"
        case gpsDifferental = "kMDItemGPSDifferental"
        
        // MARK: - Audio
        case audioSampleRate = "kMDItemAudioSampleRate"
        case audioChannelCount = "kMDItemAudioChannelCount"
        case tempo = "kMDItemTempo"
        case keySignature = "kMDItemSignature"
        case timeSignature = "kMDItemTimeSignature"
        case audioEncodingApplication = "kMDItemAudioEncodingApplication"
        case trackNumber = "kMDItemAudioTrackNumber"
        case composer = "kMDItemComposer"
        case lyricist = "kMDItemLyricist"
        case recordingDate = "kMDItemRecordingDate"
        case recordingYear = "kMDItemRecordingYear"
        case musicalGenre = "kMDItemMusicalGenre"
        case isGeneralMidiSequence = "kMDItemIsGeneralMIDISequence"
        case appleLoopsRootKey = "kMDItemAppleLoopsRootKey"
        case appleLoopsKeyFilterType = "kMDItemAppleLoopsKeyFilterType"
        case appleLoopsLoopMode = "kMDItemAppleLoopsLoopMode"
        case appleLoopDescriptors = "kMDItemAppleLoopDescriptors"
        case musicalInstrumentCategory = "kMDItemMusicalInstrumentCategory"
        case musicalInstrumentName = "kMDItemMusicalInstrumentName"
        
        // MARK: - Media
    //    case durationSeconds = "kMDItemDurationSeconds"
        case duration = "kMDItemDurationSeconds"
        case mediaTypes = "kMDItemMediaTypes"
        case codecs = "kMDItemCodecs"
        case totalBitRate = "kMDItemTotalBitRate"
        case videoBitRate = "kMDItemVideoBitRate"
        case audioBitRate = "kMDItemAudioBitRate"
        case streamable = "kMDItemStreamable"
        case mediaDeliveryType = "kMDItemDeliveryType"
        case originalFormat = "kMDItemOriginalFormat"
        case originalSource = "kMDItemOriginalSource"
        case director = "kMDItemDirector"
        case producer = "kMDItemProducer"
        case genre = "kMDItemGenre"
        case performers = "kMDItemPerformers"
        case participants = "kMDItemParticipants"
        
        // MARK: - Image
        case pixelHeight = "kMDItemPixelHeight"
        case pixelWidth = "kMDItemPixelWidth"
        case pixelSize = "_kMDItemPixelSize"
        case pixelCount = "kMDItemPixelCount"
        case colorSpace = "kMDItemColorSpace"
        case bitsPerSample = "kMDItemBitsPerSample"
        case flashOnOff = "kMDItemFlashOnOff"
        case focalLength = "kMDItemFocalLength"
        case deviceManufacturer = "kMDItemAcquisitionMake"
        case deviceModel = "kMDItemAcquisitionModel"
        case isoSpeed = "kMDItemISOSpeed"
        case orientation = "kMDItemOrientation"
        case layerNames = "kMDItemLayerNames"
        case aperture = "kMDItemAperture"
        case colorProfile = "kMDItemProfileName"
        case dpiResolutionWidth = "kMDItemResolutionWidthDPI"
        case dpiResolutionHeight = "kMDItemResolutionHeightDPI"
        case dpiResolution = "_kMDItemResolutionSizeDPI"
        case exposureMode = "kMDItemExposureMode"
        case exposureTimeSeconds = "kMDItemExposureTimeSeconds"
        case exifVersion = "kMDItemEXIFVersion"
        case cameraOwner = "kMDItemCameraOwner"
        case focalLength35Mm = "kMDItemFocalLength35mm"
        case lensModel = "kMDItemLensModel"
        case imageDirection = "kMDItemImageDirection"
        case hasAlphaChannel = "kMDItemHasAlphaChannel"
        case redEyeOnOff = "kMDItemRedEyeOnOff"
        case meteringMode = "kMDItemMeteringMode"
        case maxAperture = "kMDItemMaxAperture"
        case fNumber = "kMDItemFNumber"
        case exposureProgram = "kMDItemExposureProgram"
        case exposureTimeString = "kMDItemExposureTimeString"
        case isScreenCapture = "kMDItemIsScreenCapture"
        case screenCaptureRect = "kMDItemScreenCaptureGlobalRect"
        case screenCaptureType = "kMDItemScreenCaptureType"
        
        // MARK: - Messages / Mail
        case authorEmailAddresses = "kMDItemAuthorEmailAddresses"
        case authorAddresses = "kMDItemAuthorAddresses"
        case recipients = "kMDItemRecipients"
        case recipientEmailAddresses = "kMDItemRecipientEmailAddresses"
        case recipientAddresses = "kMDItemRecipientAddresses"
        case instantMessageAddresses = "kMDItemInstantMessageAddresses"
        case receivedDates = "kMDItemUserSharedReceivedDate"
        case receivedRecipients = "kMDItemUserSharedReceivedRecipient"
        case receivedRecipientHandles = "kMDItemUserSharedReceivedRecipientHandle"
        case receivedSenders = "kMDItemUserSharedReceivedSender"
        case receivedSenderHandles = "kMDItemUserSharedReceivedSenderHandle"
        case receivedTypes = "kMDItemUserSharedReceivedTransport"
        case isLikelyJunk = "kMDItemIsLikelyJunk"
        
        internal static func values(for mdKeys: [String]) -> [Self] {
            var attriutes = mdKeys.compactMap({Self(rawValue: $0)})
            if (attriutes.contains(all: [.pixelWidth, .pixelHeight])) {
                attriutes.replace(.pixelWidth, with: .pixelSize)
                attriutes.remove(.pixelHeight)
            }
            if (attriutes.contains(all: [.dpiResolutionWidth, .dpiResolutionHeight])) {
                attriutes.replace(.dpiResolutionWidth, with: .dpiResolution)
                attriutes.remove(.dpiResolutionHeight)
            }
            return attriutes
        }
        
        internal var mdKeys: [String] {
            if (self.rawValue.contains("_")) {
                let value = self.rawValue.replacingOccurrences(of: "_", with: "")
                if (self.rawValue.contains("Size")) {
                    return [value.replacingOccurrences(of: "Size", with: "Width"), value.replacingOccurrences(of: "Size", with: "Height")]
                } else {
                    return [value]
                }
            }
            return [self.rawValue]
        }
        
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
