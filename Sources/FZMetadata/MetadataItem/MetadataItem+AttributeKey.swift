//
//  MetadataItem+AttributeKey.swift
//
//
//  Created by Florian Zand on 22.05.22.
//

import Foundation

extension PartialKeyPath where Root == MetadataItem {
    var mdItemKey: String {
        if var itemKey = MetadataItem.attributeKeys[self]?.rawValue {
            if itemKey.hasPrefix("_") {
                itemKey = String(itemKey.dropFirst())
            }
            return itemKey
        }
        return MetadataItem.Attribute.fileName.rawValue
    }
}

extension MetadataItem {
    static var attributeKeys: [PartialKeyPath<MetadataItem>: Attribute] {
        var attributeKeys = _attributeKeys
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, macCatalyst 14.0, *) {
            attributeKeys[\.contentType] = .contentType
            attributeKeys[\.contentTypeTree] = .contentTypeTree
        }
        return attributeKeys
    }
    
    static let _attributeKeys: [PartialKeyPath<MetadataItem>: Attribute] = [
            // MARK: - Common
            \.url: .url,
            \.path: .path,
            \.fileName: .fileName,
            \.displayName: .displayName,
            \.alternateNames: .alternateNames,
            \.fileExtension: .fileExtension,
            \.fileSize: .fileSize,
            \.fileIsInvisible: .fileIsInvisible,
            \.fileExtensionIsHidden: .fileExtensionIsHidden,
            \.fileType: .fileType,
            \.creationDate: .creationDate,
            \.lastUsedDate: .lastUsedDate,
            \.lastUsageDates: .lastUsageDates,
            \.attributeModificationDate: .attributeModificationDate,
            \.contentCreationDate: .contentCreationDate,
            \.contentChangeDate: .contentChangeDate,
            \.contentModificationDate: .contentModificationDate,
            \.addedDate: .addedDate,
            \.downloadedDate: .downloadedDate,
            \.purchaseDate: .purchaseDate,
            \.dueDate: .dueDate,
            \.directoryFilesCount: .directoryFilesCount,
            \.description: .description,
            \.kind: .kind,
            \.information: .information,
            \.identifier: .identifier,
            \.keywords: .keywords,
            \.title: .title,
            \.album: .album,
            \.authors: .authors,
            \.version: .version,
            \.comment: .comment,
            \.starRating: .starRating,
            \.whereFroms: .whereFroms,
            \.finderComment: .finderComment,
            \.finderTags: .finderTags,
            \.finderTagPrimaryColor: .finderTagPrimaryColor,
            \.hasCustomIcon: .hasCustomIcon,
            \.usageCount: .usageCount,
            \.bundleIdentifier: .bundleIdentifier,
            \.executableArchitectures: .executableArchitectures,
            \.executablePlatform: .executablePlatform,
            \.encodingApplications: .encodingApplications,
            \.applicationCategories: .applicationCategories,
            \.isApplicationManaged: .isApplicationManaged,
            \.appstoreCategory: .appstoreCategory,
            \.appstoreCategoryType: .appstoreCategoryType,

             // MARK: - Document
            \.textContent: .textContent,
            \.subject: .subject,
            \.theme: .theme,
            \.headline: .headline,
            \.creator: .creator,
            \.instructions: .instructions,
            \.editors: .editors,
            \.audiences: .audiences,
            \.coverage: .coverage,
            \.projects: .projects,
            \.numberOfPages: .numberOfPages,
            \.pageWidth: .pageWidth,
            \.pageHeight: .pageHeight,
            \.copyright: .copyright,
            \.fonts: .fonts,
            \.fontFamilyName: .fontFamilyName,
            \.contactKeywords: .contactKeywords,
            \.languages: .languages,
            \.rights: .rights,
            \.organizations: .organizations,
            \.publishers: .publishers,
            \.emailAddresses: .emailAddresses,
            \.phoneNumbers: .phoneNumbers,
            \.contributors: .contributors,
            \.securityMethod: .securityMethod,

             // MARK: - Places
            \.country: .country,
            \.city: .city,
            \.stateOrProvince: .stateOrProvince,
            \.areaInformation: .areaInformation,
            \.namedLocation: .namedLocation,
            \.altitude: .altitude,
            \.latitude: .latitude,
            \.longitude: .longitude,
            \.speed: .speed,
            \.timestamp: .timestamp,
            \.gpsTrack: .gpsTrack,
            \.gpsStatus: .gpsStatus,
            \.gpsMeasureMode: .gpsMeasureMode,
            \.gpsDop: .gpsDop,
            \.gpsMapDatum: .gpsMapDatum,
            \.gpsDestLatitude: .gpsDestLatitude,
            \.gpsDestLongitude: .gpsDestLongitude,
            \.gpsDestBearing: .gpsDestBearing,
            \.gpsDestDistance: .gpsDestDistance,
            \.gpsProcessingMethod: .gpsProcessingMethod,
            \.gpsDateStamp: .gpsDateStamp,
            \.gpsDifferental: .gpsDifferental,

             // MARK: - Audio
            \.audioSampleRate: .audioSampleRate,
            \.audioChannelCount: .audioChannelCount,
            \.tempo: .tempo,
            \.keySignature: .keySignature,
            \.timeSignature: .timeSignature,
            \.audioEncodingApplication: .audioEncodingApplication,
            \.trackNumber: .trackNumber,
            \.composer: .composer,
            \.lyricist: .lyricist,
            \.recordingDate: .recordingDate,
            \.recordingYear: .recordingYear,
            \.musicalGenre: .musicalGenre,
            \.isGeneralMidiSequence: .isGeneralMidiSequence,
            \.appleLoopsRootKey: .appleLoopsRootKey,
            \.appleLoopsKeyFilterType: .appleLoopsKeyFilterType,
            \.appleLoopsLoopMode: .appleLoopsLoopMode,
            \.appleLoopDescriptors: .appleLoopDescriptors,
            \.musicalInstrumentCategory: .musicalInstrumentCategory,
            \.musicalInstrumentName: .musicalInstrumentName,

             // MARK: - Media
            \.duration: .duration,
            \.mediaTypes: .mediaTypes,
            \.codecs: .codecs,
            \.totalBitRate: .totalBitRate,
            \.videoBitRate: .videoBitRate,
            \.audioBitRate: .audioBitRate,
            \.streamable: .streamable,
            \.mediaDeliveryType: .mediaDeliveryType,
            \.originalFormat: .originalFormat,
            \.originalSource: .originalSource,
            \.director: .director,
            \.producer: .producer,
            \.genre: .genre,
            \.performers: .performers,
            \.participants: .participants,

             // MARK: - Image
            \.pixelHeight: .pixelHeight,
            \.pixelWidth: .pixelWidth,
            \.pixelSize: .pixelSize,
            \.pixelCount: .pixelCount,
            \.colorSpace: .colorSpace,
            \.bitsPerSample: .bitsPerSample,
            \.flashOnOff: .flashOnOff,
            \.focalLength: .focalLength,
            \.deviceManufacturer: .deviceManufacturer,
            \.deviceModel: .deviceModel,
            \.isoSpeed: .isoSpeed,
            \.orientation: .orientation,
            \.layerNames: .layerNames,
            \.aperture: .aperture,
            \.colorProfile: .colorProfile,
            \.dpiResolutionWidth: .dpiResolutionWidth,
            \.dpiResolutionHeight: .dpiResolutionHeight,
            \.dpiResolution: .dpiResolution,
            \.exposureMode: .exposureMode,
            \.exposureTimeSeconds: .exposureTimeSeconds,
            \.exifVersion: .exifVersion,
            \.cameraOwner: .cameraOwner,
            \.focalLength35Mm: .focalLength35Mm,
            \.lensModel: .lensModel,
            \.imageDirection: .imageDirection,
            \.hasAlphaChannel: .hasAlphaChannel,
            \.redEyeOnOff: .redEyeOnOff,
            \.meteringMode: .meteringMode,
            \.maxAperture: .maxAperture,
            \.fNumber: .fNumber,
            \.exposureProgram: .exposureProgram,
            \.exposureTimeString: .exposureTimeString,
            \.isScreenCapture: .isScreenCapture,
            \.screenCaptureRect: .screenCaptureRect,
            \.screenCaptureType: .screenCaptureType,
            \.whiteBalance: .whiteBalance,

             // MARK: - Messages / Mail
            \.authorEmailAddresses: .authorEmailAddresses,
            \.authorAddresses: .authorAddresses,
            \.recipients: .recipients,
            \.recipientEmailAddresses: .recipientEmailAddresses,
            \.recipientAddresses: .recipientAddresses,
            \.instantMessageAddresses: .instantMessageAddresses,
            \.receivedDates: .receivedDates,
            \.receivedRecipients: .receivedRecipients,
            \.receivedRecipientHandles: .receivedRecipientHandles,
            \.receivedSenders: .receivedSenders,
            \.receivedSenderHandles: .receivedSenderHandles,
            \.receivedTypes: .receivedTypes,
            \.isLikelyJunk: .isLikelyJunk,

             // MARK: - iCloud
            \.isUbiquitousItem: .isUbiquitousItem,
            \.ubiquitousItemContainerDisplayName: .ubiquitousItemContainerDisplayName,
            \.ubiquitousItemDownloadRequested: .ubiquitousItemDownloadRequested,
            \.ubiquitousItemIsExternalDocument: .ubiquitousItemIsExternalDocument,
            \.ubiquitousItemURLInLocalContainer: .ubiquitousItemURLInLocalContainer,
            \.ubiquitousItemHasUnresolvedConflicts: .ubiquitousItemHasUnresolvedConflicts,
            \.ubiquitousItemIsDownloaded: .ubiquitousItemIsDownloaded,
            \.ubiquitousItemIsDownloading: .ubiquitousItemIsDownloading,
            \.ubiquitousItemIsUploaded: .ubiquitousItemIsUploaded,
            \.ubiquitousItemIsUploading: .ubiquitousItemIsUploading,
            \.ubiquitousItemPercentDownloaded: .ubiquitousItemPercentDownloaded,
            \.ubiquitousItemPercentUploaded: .ubiquitousItemPercentUploaded,
            \.ubiquitousItemDownloadingStatus: .ubiquitousItemDownloadingStatus,
            \.ubiquitousItemDownloadingError: .ubiquitousItemDownloadingError,
            \.ubiquitousItemUploadingError: .ubiquitousItemUploadingError,
            \.ubiquitousItemIsShared: .ubiquitousItemIsShared,
            \.ubiquitousSharedItemCurrentUserPermissions: .ubiquitousSharedItemCurrentUserPermissions,
            \.ubiquitousSharedItemCurrentUserRole: .ubiquitousSharedItemCurrentUserRole,
            \.ubiquitousSharedItemMostRecentEditorNameComponents: .ubiquitousSharedItemMostRecentEditorNameComponents,
            \.ubiquitousSharedItemOwnerNameComponents: .ubiquitousSharedItemOwnerNameComponents,

             // MARK: - Query Content Relevance
            \.queryContentRelevance: .queryContentRelevance,
    ]
}
