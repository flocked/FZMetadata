//
//  NSPredicateEditor+MetadataItem.swift
//
//
//  Created by Florian Zand on 27.06.24.
//


#if os(macOS)
import AppKit
import FZSwiftUtils

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
    /// A predicate editor row template for the attribute.
    public var predicateEditorRowTemplate: NSPredicateEditorRowTemplate? {
        if let valueType = rowValueType {
            return .init(leftExpressions: [.keyPath(rawValue)], rightExpressionAttributeType: valueType, operators: rowOperators, options: rowOptions)
        } else if let values = rowValues {
            return .init(leftExpressions: [.keyPath(rawValue)], rightExpressions: values.map({ NSExpression.constant($0) }), operators: rowOperators, options: rowOptions)
        }
        return nil
    }
    
    var rowValueType: NSAttributeType? {
        switch self {
        case .fileName, .displayName, .fileExtension, .contentDescription, .information, .identifier, .title, .album, .version, .comment, .finderComment, .bundleIdentifier, .executablePlatform, .appstoreCategory, .appstoreCategoryType, .textContent, .subject, .theme, .headline, .creator, .instructions, .copyright, .fontFamilyName, .rights, .country, .city, .stateOrProvince, .areaInformation, .namedLocation, .gpsStatus, .gpsMeasureMode, .gpsMapDatum, .gpsProcessingMethod, .audioEncodingApplication, .keySignature, .timeSignature, .composer, .lyricist, .musicalGenre, .appleLoopsRootKey, .appleLoopsKeyFilterType, .appleLoopsLoopMode, .musicalInstrumentCategory, .musicalInstrumentName, .mediaDeliveryType, .originalFormat, .originalSource, .genre, .director, .producer, .colorSpace, .deviceManufacturer, .deviceModel, .colorProfile, .exifVersion, .cameraOwner, .lensModel, .exposureProgram, .exposureTimeString, .ubiquitousItemContainerDisplayName, .contentType, .contentTypeTree:
            return .stringAttributeType
        case .alternateNames, .kind, .keywords, .authors, .whereFroms, .finderTags, .executableArchitectures, .encodingApplications, .applicationCategories, .editors, .audiences, .coverage, .projects, .fonts, .contactKeywords, .languages, .organizations, .publishers, .emailAddresses, .phoneNumbers, .contributors, .appleLoopDescriptors, .performers, .participants, .layerNames, .authorEmailAddresses, .authorAddresses, .recipients, .recipientEmailAddresses, .recipientAddresses, .instantMessageAddresses, .receivedRecipients, .receivedRecipientHandles, .receivedSenders, .receivedSenderHandles, .receivedTypes:
            return .stringAttributeType
        case .dueDate, .addedDate, .creationDate, .purchaseDate, .receivedDates, .recordingDate, .downloadedDate, .lastUsedDate, .lastUsageDates, .modificationDate, .contentCreationDate, .contentModificationDate, .attributeModificationDate, .timestamp, .gpsDateStamp:
            return .dateAttributeType
        case .fileIsInvisible, .fileExtensionIsHidden, .hasCustomIcon, .isApplicationManaged, .isGeneralMidiSequence, .streamable, .isFlashOn, .hasAlphaChannel, .redEyeOnOff, .isScreenCapture, .isLikelyJunk, .isUbiquitousItem, .ubiquitousItemDownloadRequested, .ubiquitousItemIsExternalDocument, .ubiquitousItemHasUnresolvedConflicts, .ubiquitousItemIsDownloaded, .ubiquitousItemIsDownloading, .ubiquitousItemIsUploaded, .ubiquitousItemIsUploading, .ubiquitousItemIsShared:
            return .booleanAttributeType
        case .directoryFilesCount, .usageCount, .audioChannelCount, .trackNumber:
            return .integer32AttributeType
        case .starRating, .numberOfPages, .pageWidth, .pageHeight, .securityMethod, .altitude, .latitude, .longitude, .speed, .gpsTrack, .gpsDop, .gpsDestLatitude, .gpsDestLongitude, .gpsDestBearing, .gpsDestDistance, .gpsDifferental, .audioSampleRate, .tempo, .recordingYear, .totalBitRate, .videoBitRate, .audioBitRate, .pixelHeight, .pixelWidth, .pixelCount, .bitsPerSample, .focalLength, .isoSpeed, .aperture, .dpiResolutionWidth, .dpiResolutionHeight, .exposureTimeSeconds, .focalLength35Mm, .imageDirection, .maxAperture, .fNumber, .ubiquitousItemPercentDownloaded, .ubiquitousItemPercentUploaded, .queryContentRelevance:
            return .doubleAttributeType
        default: return nil
        }
    }
    
    var rowValues: [String]? {
        switch self {
        case .meteringMode: return ["Average", "Center Weighted Average", "Spot", "Multispot", "Pattern", "Partial", "Unknown"]
        case .exposureMode: return ["Automatic", "Manual", "Automatic Bracket"]
        case .orientation: return ["Horizontal", "Vertical"]
        case .whiteBalance: return ["Auto", "Off"]
        case .screenCaptureType: return ["Display", "Window", "Selection"]
        case .fileType:
            let fileTypes: [FileType] = [.archive, .executable, .image, .document, .video, .audio, .folder, .pdf, .presentation, .application, .text]
            let values = ["Any"] + fileTypes.compactMap({$0.description}) + ["Other"]
            return values
        default: return nil
        }
    }
    
    var rowOperators: [NSComparisonPredicate.Operator] {
        switch rowValueType {
        case .stringAttributeType:
            return [.contains, .beginsWith, .endsWith, .equalTo, .notEqualTo]
        case .doubleAttributeType, .integer16AttributeType, .integer32AttributeType, .integer64AttributeType, .dateAttributeType:
            return [.equalTo, .lessThan, .greaterThan, .notEqualTo]
        default:
            return [.equalTo, .notEqualTo]
        }
    }
    
    var rowOptions: NSComparisonPredicate.Options {
        switch rowValueType {
        case .stringAttributeType: return [.caseInsensitive, .diacriticInsensitive]
        default: return []
        }
    }
}
#endif
