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
    var rowTemplate: NSPredicateEditorRowTemplate {
        switch self {
        default:
            return NSPredicateEditorRowTemplate(constant: "Template", values: ["Value"])
        }
    }
    
    var valueType: ValueType {
        switch self {
        case .dueDate, .addedDate, .creationDate, .purchaseDate, .receivedDates, .recordingDate, .downloadedDate, .lastUsedDate, .lastUsageDates, .modificationDate, .contentCreationDate, .contentModificationDate, .attributeModificationDate, .timestamp, .gpsDateStamp:
            return .date
        case .isLikelyJunk, .isScreenCapture, .isApplicationManaged, .isGeneralMidiSequence, .fileIsInvisible, .fileExtensionIsHidden, .hasCustomIcon, .hasAlphaChannel, .streamable, .isFlashOn, .redEyeOnOff:
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
