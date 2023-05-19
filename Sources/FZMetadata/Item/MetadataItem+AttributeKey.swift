//
//  URLMetadata+MDItemKey.swift
//  FZCollection
//
//  Created by Florian Zand on 22.05.22.
//

import Foundation

internal struct MetadataAttributeKey {
    let keypath: PartialKeyPath<MetadataItem>
    let mdItemKey: String
    init(_ keypath: PartialKeyPath<MetadataItem>, _ mdItemKey: String) {
        self.keypath = keypath
        self.mdItemKey = mdItemKey
    }
}

internal extension MetadataItem {
    typealias Key = MetadataAttributeKey
    
    static func partialKeyPath(for mdKey: String) -> PartialKeyPath<MetadataItem>? {
        attributeKeys.first(where: {$0.mdItemKey == mdKey})?.keypath
    }
    
    static var attributeKeys: [MetadataAttributeKey] {
        var keys = [
            Key(\.url, "kMDItemURL"),
            Key(\.path, "kMDItemPath"),
            Key(\.fileName, "kMDItemFSName"),
            Key(\.displayName, "kMDItemDisplayName"),
            Key(\.alternateNames, "kMDItemAlternateNames"),
            Key(\.fileExtension, "kMDItemFSExtension"),
            Key(\.fileSizeBytes, "kMDItemFSSize"),
            Key(\.fileSize, "kMDItemFSSize"),
            Key(\.fileIsInvisible, "kMDItemFSInvisible"),
            Key(\.fileExtensionIsHidden, "kMDItemFSIsExtensionHidden"),
            Key(\.fileType, "kMDItemContentTypeTree"),
            Key(\.contentType, "kMDItemContentType"),
            Key(\.contentTypeTree, "kMDItemContentTypeTree"),
            Key(\.creationDate, "kMDItemFSCreationDate"),
            Key(\.lastUsedDate, "kMDItemLastUsedDate"),
            Key(\.lastUsageDates, "kMDItemUsedDates"),
            Key(\.metadataModificationDate, "kMDItemAttributeChangeDate"),
            Key(\.contentCreationDate, "kMDItemContentCreationDate"),
            Key(\.contentChangeDate, "kMDItemFSContentChangeDate"),
            Key(\.contentModificationDate, "kMDItemContentModificationDate"),
            Key(\.dateAdded, "kMDItemDateAdded"),
            Key(\.downloadedDate, "kMDItemDownloadedDate"),
            Key(\.purchaseDate, "kMDItemPurchaseDate"),
            Key(\.dueDate, "kMDItemDueDate"),
            Key(\.directoryFilesCount, "kMDItemFSNodeCount"),
            Key(\.description, "kMDItemDescription"),
            Key(\.kind, "kMDItemKind"),
            Key(\.information, "kMDItemInformation"),
            Key(\.identifier, "kMDItemIdentifier"),
            Key(\.keywords, "kMDItemwords"),
            Key(\.title, "kMDItemTitle"),
            Key(\.album, "kMDItemAlbum"),
            Key(\.authors, "kMDItemAuthors"),
            Key(\.version, "kMDItemVersion"),
            Key(\.comment, "kMDItemComment"),
            Key(\.starRating, "kMDItemStarRating"),
            Key(\.whereFroms, "kMDItemWhereFroms"),
            Key(\.finderComment, "kMDItemFinderComment"),
            Key(\.finderTags, "kMDItemUserTags"),
            Key(\.finderPrimaryTagColorIndex, "kMDItemFSLabel"),
            Key(\.finderPrimaryTagColor, "kMDItemFSLabel"),
            Key(\.hasCustomIcon, "kMDItemFSHasCustomIcon"),
            Key(\.usageCount, "kMDItemUseCount"),
            Key(\.bundleIdentifier, "kMDItemCFBundleIdentifier"),
            Key(\.executableArchitectures, "kMDItemExecutableArchitectures"),
            Key(\.executablePlatform, "kMDItemExecutablePlatform"),
            Key(\.encodingApplications, "kMDItemEncodingApplications"),
            Key(\.applicationCategories, "kMDItemApplicationCategories"),
            Key(\.isApplicationManaged, "kMDItemIsApplicationManaged"),
            Key(\.appstoreCategory, "kMDItemAppStoreCategory"),
            Key(\.appstoreCategoryType, "kMDItemAppStoreCategoryType"),
            
            // MARK: - Document
            Key(\.textContent, "kMDItemTextContent"),
            Key(\.subject, "kMDItemSubject"),
            Key(\.theme, "kMDItemTheme"),
            Key(\.headline, "kMDItemHeadline"),
            Key(\.creator, "kMDItemCreator"),
            Key(\.instructions, "kMDItemInstructions"),
            Key(\.editors, "kMDItemEditors"),
            Key(\.audiences, "kMDItemAudiences"),
            Key(\.coverage, "kMDItemCoverage"),
            Key(\.projects, "kMDItemProjects"),
            Key(\.numberOfPages, "kMDItemNumberOfPages"),
            Key(\.pageWidth, "kMDItemPageWidth"),
            Key(\.pageHeight, "kMDItemPageHeight"),
            Key(\.copyright, "kMDItemCopyright"),
            Key(\.fonts, "kMDItemFonts"),
            Key(\.fontFamilyName, "com_apple_ats_name_family"),
            Key(\.contactKeywords, "kMDItemContactKeywords"),
            Key(\.languages, "kMDItemLanguages"),
            Key(\.rights, "kMDItemRights"),
            Key(\.organizations, "kMDItemOrganizations"),
            Key(\.publishers, "kMDItemPublishers"),
            Key(\.emailAddresses, "kMDItemEmailAddresses"),
            Key(\.phoneNumbers, "kMDItemPhoneNumbers"),
            Key(\.contributors, "kMDItemContributors"),
            Key(\.securityMethod, "kMDItemSecurityMethod"),
         
            // MARK: - Places
            Key(\.country, "kMDItemCountry"),
            Key(\.city, "kMDItemCity"),
            Key(\.stateOrProvince, "kMDItemStateOrProvince"),
            Key(\.areaInformation, "kMDItemGPSAreaInformation"),
            Key(\.namedLocation, "kMDItemNamedLocation"),
            Key(\.altitude, "kMDItemAltitude"),
            Key(\.latitude, "kMDItemLatitude"),
            Key(\.longitude, "kMDItemLongitude"),
            Key(\.speed, "kMDItemSpeed"),
            Key(\.timestamp, "kMDItemTimestamp"),
            Key(\.gpsTrack, "kMDItemGPSTrack"),
            Key(\.gpsStatus, "kMDItemGPSStatus"),
            Key(\.gpsMeasureMode, "kMDItemGPSMeasureMode"),
            Key(\.gpsDop, "kMDItemGPSDOP"),
            Key(\.gpsMapDatum, "kMDItemGPSMapDatum"),
            Key(\.gpsDestLatitude, "kMDItemGPSDestLatitude"),
            Key(\.gpsDestLongitude, "kMDItemGPSDestLongitude"),
            Key(\.gpsDestBearing, "kMDItemGPSDestBearing"),
            Key(\.gpsDestDistance, "kMDItemGPSDestDistance"),
            Key(\.gpsProcessingMethod, "kMDItemGPSProcessingMethod"),
            Key(\.gpsDateStamp, "kMDItemGPSDateStamp"),
            Key(\.gpsDifferental, "kMDItemGPSDifferental"),
            
            // MARK: - Audio
            Key(\.audioSampleRate, "kMDItemAudioSampleRate"),
            Key(\.audioChannelCount, "kMDItemAudioChannelCount"),
            Key(\.tempo, "kMDItemTempo"),
            Key(\.keySignature, "kMDItemSignature"),
            Key(\.timeSignature, "kMDItemTimeSignature"),
            Key(\.audioEncodingApplication, "kMDItemAudioEncodingApplication"),
            Key(\.trackNumber, "kMDItemAudioTrackNumber"),
            Key(\.composer, "kMDItemComposer"),
            Key(\.lyricist, "kMDItemLyricist"),
            Key(\.recordingDate, "kMDItemRecordingDate"),
            Key(\.recordingYear, "kMDItemRecordingYear"),
            Key(\.musicalGenre, "kMDItemMusicalGenre"),
            Key(\.isGeneralMidiSequence, "kMDItemIsGeneralMIDISequence"),
            Key(\.appleLoopsRootKey, "kMDItemAppleLoopsRootKey"),
            Key(\.appleLoopsKeyFilterType, "kMDItemAppleLoopsKeyFilterType"),
            Key(\.appleLoopsLoopMode, "kMDItemAppleLoopsLoopMode"),
            Key(\.appleLoopDescriptors, "kMDItemAppleLoopDescriptors"),
            Key(\.musicalInstrumentCategory, "kMDItemMusicalInstrumentCategory"),
            Key(\.musicalInstrumentName, "kMDItemMusicalInstrumentName"),
            
            // MARK: - Media
            Key(\.durationSeconds, "kMDItemDurationSeconds"),
            Key(\.duration, "kMDItemDurationSeconds"),
            Key(\.mediaTypes, "kMDItemMediaTypes"),
            Key(\.codecs, "kMDItemCodecs"),
            Key(\.totalBitRate, "kMDItemTotalBitRate"),
            Key(\.videoBitRate, "kMDItemVideoBitRate"),
            Key(\.audioBitRate, "kMDItemAudioBitRate"),
            Key(\.streamable, "kMDItemStreamable"),
            Key(\.mediaDeliveryType, "kMDItemDeliveryType"),
            Key(\.originalFormat, "kMDItemOriginalFormat"),
            Key(\.originalSource, "kMDItemOriginalSource"),
            Key(\.director, "kMDItemDirector"),
            Key(\.producer, "kMDItemProducer"),
            Key(\.genre, "kMDItemGenre"),
            Key(\.performers, "kMDItemPerformers"),
            Key(\.participants, "kMDItemParticipants"),
            
            // MARK: - Image
            Key(\.pixelHeight, "kMDItemPixelHeight"),
            Key(\.pixelWidth, "kMDItemPixelWidth"),
            Key(\.pixelSize, "kMDItemPixelSize"),
            Key(\.pixelCount, "kMDItemPixelCount"),
            Key(\.colorSpace, "kMDItemColorSpace"),
            Key(\.bitsPerSample, "kMDItemBitsPerSample"),
            Key(\.flashOnOff, "kMDItemFlashOnOff"),
            Key(\.focalLength, "kMDItemFocalLength"),
            Key(\.deviceManufacturer, "kMDItemAcquisitionMake"),
            Key(\.deviceModel, "kMDItemAcquisitionModel"),
            Key(\.isoSpeed, "kMDItemISOSpeed"),
            Key(\.orientation, "kMDItemOrientation"),
            Key(\.layerNames, "kMDItemLayerNames"),
            Key(\.aperture, "kMDItemAperture"),
            Key(\.colorProfile, "kMDItemProfileName"),
            Key(\.dpiResolutionWidth, "kMDItemResolutionWidthDPI"),
            Key(\.dpiResolutionHeight, "kMDItemResolutionHeightDPI"),
            Key(\.dpiResolution, "kMDItemResolutionSizeDPI"),
            Key(\.exposureMode, "kMDItemExposureMode"),
            Key(\.exposureTimeSeconds, "kMDItemExposureTimeSeconds"),
            Key(\.exifVersion, "kMDItemEXIFVersion"),
            Key(\.cameraOwner, "kMDItemCameraOwner"),
            Key(\.focalLength35Mm, "kMDItemFocalLength35mm"),
            Key(\.lensModel, "kMDItemLensModel"),
            Key(\.imageDirection, "kMDItemImageDirection"),
            Key(\.hasAlphaChannel, "kMDItemHasAlphaChannel"),
            Key(\.redEyeOnOff, "kMDItemRedEyeOnOff"),
            Key(\.meteringMode, "kMDItemMeteringMode"),
            Key(\.maxAperture, "kMDItemMaxAperture"),
            Key(\.fNumber, "kMDItemFNumber"),
            Key(\.exposureProgram, "kMDItemExposureProgram"),
            Key(\.exposureTimeString, "kMDItemExposureTimeString"),
            Key(\.isScreenCapture, "kMDItemIsScreenCapture"),
            Key(\.screenCaptureRect, "kMDItemScreenCaptureGlobalRect"),
            Key(\.screenCaptureType, "kMDItemScreenCaptureType"),
            
            // MARK: - Messages / Mail
            Key(\.authorEmailAddresses, "kMDItemAuthorEmailAddresses"),
            Key(\.authorAddresses, "kMDItemAuthorAddresses"),
            Key(\.recipients, "kMDItemRecipients"),
            Key(\.recipientEmailAddresses, "kMDItemRecipientEmailAddresses"),
            Key(\.recipientAddresses, "kMDItemRecipientAddresses"),
            Key(\.instantMessageAddresses, "kMDItemInstantMessageAddresses"),
            Key(\.receivedDates, "kMDItemUserSharedReceivedDate"),
            Key(\.receivedRecipients, "kMDItemUserSharedReceivedRecipient"),
            Key(\.receivedRecipientHandles, "kMDItemUserSharedReceivedRecipientHandle"),
            Key(\.receivedSenders, "kMDItemUserSharedReceivedSender"),
            Key(\.receivedSenderHandles, "kMDItemUserSharedReceivedSenderHandle"),
            Key(\.receivedTypes, "kMDItemUserSharedReceivedTransport"),
            Key(\.isLikelyJunk, "kMDItemIsLikelyJunk"),

            Key(\.queryContentRelevance, "kMDQueryResultContentRelevance"),
        ]
        if #available(macOS 11.0, iOS 14.0, *) {
            keys.append(Key(\.contentUTType, "kMDItemContentType"))
        }
        return keys
    }
}

extension PartialKeyPath where Root == MetadataItem {
    internal var attributeKey: MetadataAttributeKey? {
        return MetadataItem.attributeKeys.first(where: {$0.keypath == self})
    }
    public var mdItemKey: String {
        return attributeKey?.mdItemKey ?? "kMDItemFSName"
    }
}
