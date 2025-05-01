//
//  MetadataQuery+SortDescriptor.swift
//
//
//  Created by Florian Zand on 10.02.23.
//

import Foundation
import FZSwiftUtils

extension MetadataQuery {
    /**
      A description of how to order the results of a query according to a metadata attribute.

      ```swift
       query.sortedBy = [.creationDate, .fileSize.descending] // Sorts by ascending creationDate & descending fileSize
     ```
      */
    public struct SortDescriptor {
        /// The metadata attribute of the sort descriptor.
        let attribute: MetadataItem.Attribute
        
        /// A Boolean value that indicates whether the sort descriptor specifies sorting in ascending order.
        let isAscending: Bool
        
        init(_ attribute: MetadataItem.Attribute, ascending: Bool = true) {
            self.attribute = attribute
            self.isAscending = ascending            
        }
        
        /**
         An ascending sort descriptor for the specified metadata attribute.
         
         - Parameter attribute: The comparable metadata attribute.
         */
        public static func ascending(_ attribute: MetadataItem.Attribute) -> SortDescriptor {
            SortDescriptor(attribute, ascending: true)
        }
        
        /**
         A descending sort descriptor for the specified metadata attribute.
         
         - Parameter attribute: The comparable metadata attribute.
         */
        public static func descending(_ attribute: MetadataItem.Attribute) -> SortDescriptor {
            SortDescriptor(attribute, ascending: false)
        }
        
        public var ascending: Self {
            Self(attribute, ascending: true)
        }
        
        /// Sorts the items from largest to smallest for the attribute value.
        public var descending: Self {
            Self(attribute, ascending: false)
        }
        
        var sortDescriptor: NSSortDescriptor {
            NSSortDescriptor(key: attribute.rawValue, ascending: isAscending)
        }
    }
}

extension MetadataQuery.SortDescriptor {
    /// The url of the file.
    public static let url = Self(.url)

    /// The full path of the file.
    public static let path = Self(.path)

    /// The name of the file including the extension.
    public static let filename = Self(.fileName)

    /// The display name of the file, which may be different then the file system name.
    public static let displayName = Self(.displayName)

    /// The alternative names of the file.
    public static let alternateNames = Self(.alternateNames)

    /// The extension of the file.
    public static let fileExtension = Self(.fileExtension)

    /// The size of the file.
    public static let fileSize = Self(.fileSize)

    /// A Boolean value that indicates whether the file is invisible.
    public static let fileIsInvisible = Self(.fileIsInvisible)

    /// A Boolean value that indicates whether the file extension is hidden.
    public static let fileExtensionIsHidden = Self(.fileExtensionIsHidden)

    /// The file type. For example: `video`, `document` or `directory`
    public static let fileType = Self(.fileType)

    /// The content type of the file.
    public static let contentType = Self(.contentType)

    /// The content type tree of the file.
    public static let contentTypeTree = Self(.contentTypeTree)

    /// The date that the file was created.
    public static let creationDate = Self(.creationDate)

    /// The last date that the file was used.
    public static let lastUsedDate = Self(.lastUsedDate)

    /// The dates the file was last used.
    public static let lastUsageDates = Self(.lastUsageDates)

    /// The last date that the attributes of the file were changed.
    public static let attributeModificationDate = Self(.attributeModificationDate)

    /// The date that the content of the file was created.
    public static let contentCreationDate = Self(.contentCreationDate)

    /// The last date that the content of the file was changed.
    public static let modificationDate = Self(.modificationDate)

    /// The last date that the content of the file was modified.
    public static let contentModificationDate = Self(.contentModificationDate)

    /// The date the file was created, or renamed into or within its parent directory.
    public static let addedDate = Self(.addedDate)

    /// The date that the file was downloaded.
    public static let downloadedDate = Self(.downloadedDate)

    /// The date that the file was purchased.
    public static let purchaseDate = Self(.purchaseDate)

    /// The date that this item is due (e.g. for a calendar event file).
    public static let dueDate = Self(.dueDate)

    /// The number of files in a directory.
    public static let directoryFilesCount = Self(.directoryFilesCount)

    ///  A description of the content of the item. The description may include an abstract, table of contents, reference to a graphical representation of content or a free-text account of the content.
    public static let description = Self(.description)

    /// A description of the kind of item the file represents.
    public static let kind = Self(.kind)

    /// Information of this item.
    public static let information = Self(.information)

    /// The formal identifier used to reference the item within a given context.
    public static let identifier = Self(.identifier)

    /// The keywords associated with the file. For example: `Birthday` or `Important`.
    public static let keywords = Self(.keywords)

    /// The title of the file. For example, this could be the title of a document, the name of a song, or the subject of an email message.
    public static let title = Self(.title)

    /// The title for a collection of media. This is analagous to a record album, or photo album.
    public static let album = Self(.album)

    /// The authors, artists, etc. of the contents of the file.
    public static let authors = Self(.authors)

    /// The version of the file.
    public static let version = Self(.version)

    /// A comment related to the file. This differs from `finderComment`.
    public static let comment = Self(.comment)

    /// The user rating of the file. For example, the stars rating of an iTunes track.
    public static let starRating = Self(.starRating)

    /// A describes where the file was obtained from. For example download urls.
    public static let whereFroms = Self(.whereFroms)

    /// The finder comment of the file. This differs from the `comment`.
    public static let finderComment = Self(.finderComment)

    /// The finder tags of the file.
    public static let finderTags = Self(.finderTags)

    /// The primary (first) finder tag color.
    public static let finderTagPrimaryColor = Self(.finderTagPrimaryColor)

    /// A Boolean value that indicates whether the file has a custom icon.
    public static let hasCustomIcon = Self(.hasCustomIcon)

    /// The number of usages of the file.
    public static let usageCount = Self(.usageCount)

    /// The bundle identifier of this item. If this item is a bundle, then this is the `CFBundleIdentifier`.
    public static let bundleIdentifier = Self(.bundleIdentifier)

    /// The architectures this item requires to execute.
    public static let executableArchitectures = Self(.executableArchitectures)

    /// The platform this item requires to execute.
    public static let executablePlatform = Self(.executablePlatform)

    /// The application used to convert the original content into it's current form. For example, a PDF file might have an encoding application set to "Distiller".
    public static let encodingApplications = Self(.encodingApplications)

    /// The categories the application is a member of.
    public static let applicationCategories = Self(.applicationCategories)

    /// A Boolean value that indicates whether the file is owned and managed by an application.
    public static let isApplicationManaged = Self(.isApplicationManaged)

    /// The AppStore category of this item if it's an application from the AppStore.
    public static let appstoreCategory = Self(.appstoreCategory)

    /// The AppStore category type of this item if it's an application from the AppStore.
    public static let appstoreCategoryType = Self(.appstoreCategoryType)

    // MARK: - Document

    /// A text representation of the content of the document.
    public static let textContent = Self(.textContent)

    /// The subject of the this item
    public static let subject = Self(.subject)

    /// The theme of the this item.
    public static let theme = Self(.theme)

    /// A publishable summary of the contents of the item.
    public static let headline = Self(.headline)

    /// the application or operation system used to create the document content. For example: `Word`,  `Pages` or `16.2`.
    public static let creator = Self(.creator)

    /// Other information concerning this item, such as handling instructions.
    public static let instructions = Self(.instructions)

    /// The editors of the contents of the file.
    public static let editors = Self(.editors)

    /// The audience for which the file is intended. The audience may be determined by the creator or the publisher or by a third party.
    public static let audiences = Self(.audiences)

    /// The extent or scope of the content of the document.
    public static let coverage = Self(.coverage)

    /// The list of projects that the file is part of. For example, if you were working on a movie all of the files could be marked as belonging to the project `My Movie`.
    public static let projects = Self(.projects)

    /// The number of pages in the document.
    public static let numberOfPages = Self(.numberOfPages)

    /// The width of the document page, in points (72 points per inch). For PDF files this indicates the width of the first page only.
    public static let pageWidth = Self(.pageWidth)

    /// The height of the document page, in points (72 points per inch). For PDF files this indicates the height of the first page only.
    public static let pageHeight = Self(.pageHeight)

    /// The copyright owner of the file contents.
    public static let copyright = Self(.copyright)

    /// The names of the fonts used in his document.
    public static let fonts = Self(.fonts)

    /// The family name of the font used in this document.
    public static let fontFamilyName = Self(.fontFamilyName)

    /// A list of contacts that are associated with this document, not including the authors.
    public static let contactKeywords = Self(.contactKeywords)

    /// The languages of the intellectual content of the resource.
    public static let languages = Self(.languages)

    /// A link to information about rights held in and over the resource.
    public static let rights = Self(.rights)

    /// The company or organization that created the document.
    public static let organizations = Self(.organizations)

    /// The entity responsible for making this item available. For example, a person, an organization, or a service. Typically, the name of a publisher should be used to indicate the entity.
    public static let publishers = Self(.publishers)

    /// The email Addresses related to this document.
    public static let emailAddresses = Self(.emailAddresses)

    /// The phone numbers related to this document.
    public static let phoneNumbers = Self(.phoneNumbers)

    /// The people or organizations contributing to the content of the document.
    public static let contributors = Self(.contributors)

    /// The security or encryption method used for the document.
    public static let securityMethod = Self(.securityMethod)

    // MARK: - Places

    /// The full, publishable name of the country or region where the intellectual property of this item was created, according to guidelines of the provider.
    public static let country = Self(.country)

    /// The city.of this document.
    public static let city = Self(.city)

    /// The province or state of origin according to guidelines established by the provider. For example: `CA`, `Ontario` or `Sussex`.
    public static let stateOrProvince = Self(.stateOrProvince)

    /// The area information of the file.
    public static let areaInformation = Self(.areaInformation)

    /// The name of the location or point of interest associated with the
    public static let namedLocation = Self(.namedLocation)

    /// The altitude of this item in meters above sea level, expressed using the WGS84 datum. Negative values lie below sea level.
    public static let altitude = Self(.altitude)

    /// The latitude of this item in degrees north of the equator, expressed using the WGS84 datum. Negative values lie south of the equator.
    public static let latitude = Self(.latitude)

    /// The longitude of this item in degrees east of the prime meridian, expressed using the WGS84 datum. Negative values lie west of the prime meridian.
    public static let longitude = Self(.longitude)

    /// The speed of this item, in kilometers per hour.
    public static let speed = Self(.speed)

    /// The timestamp on the item  This generally is used to indicate the time at which the event captured by this item took place.
    public static let timestamp = Self(.timestamp)

    /// The direction of travel of this item, in degrees from true north.
    public static let gpsTrack = Self(.gpsTrack)

    /// The gps status of this item.
    public static let gpsStatus = Self(.gpsStatus)

    /// The gps measure mode of this item.
    public static let gpsMeasureMode = Self(.gpsMeasureMode)

    /// The gps dop of this item.
    public static let gpsDop = Self(.gpsDop)

    /// The gps map datum of this item.
    public static let gpsMapDatum = Self(.gpsMapDatum)

    /// The gps destination latitude of this item.
    public static let gpsDestLatitude = Self(.gpsDestLatitude)

    /// The gps destination longitude of this item.
    public static let gpsDestLongitude = Self(.gpsDestLongitude)

    /// The gps destination bearing of this item.
    public static let gpsDestBearing = Self(.gpsDestBearing)

    /// The gps destination distance of this item.
    public static let gpsDestDistance = Self(.gpsDestDistance)

    /// The gps processing method of this item.
    public static let gpsProcessingMethod = Self(.gpsProcessingMethod)

    /// The gps date stamp of this item.
    public static let gpsDateStamp = Self(.gpsDateStamp)

    /// The gps differental of this item.
    public static let gpsDifferental = Self(.gpsDifferental)

    // MARK: - Audio

    /// The sample rate of the audio data contained in the file. The sample rate representing `audio_frames/second`. For example: `44100.0`, `22254.54`.
    public static let audioSampleRate = Self(.audioSampleRate)

    /// The number of channels in the audio data contained in the file.
    public static let audioChannelCount = Self(.audioChannelCount)

    /// The tempo that specifies the beats per minute of the music contained in the audio file.
    public static let tempo = Self(.tempo)

    /// The key of the music contained in the audio file. For example: `C`, `Dm`, `F#, `Bb`.
    public static let keySignature = Self(.keySignature)

    /// The time signature of the musical composition contained in the audio/MIDI file. For example: `4/4`, `7/8`.
    public static let timeSignature = Self(.timeSignature)

    /// The name of the application that encoded the data of a audio file.
    public static let audioEncodingApplication = Self(.audioEncodingApplication)

    /// The track number of a song or composition when it is part of an album.
    public static let trackNumber = Self(.trackNumber)

    /// The composer of the music contained in the audio file.
    public static let composer = Self(.composer)

    /// The lyricist, or text writer, of the music contained in the audio file.
    public static let lyricist = Self(.lyricist)

    /// The recording date of the song or composition.
    public static let recordingDate = Self(.recordingDate)

    /// Indicates the year this item was recorded. For example: `1964`, `2003`.
    public static let recordingYear = Self(.recordingYear)

    /// The musical genre of the song or composition contained in the audio file. For example: `Jazz`, `Pop`, `Rock`, `Classical`.
    public static let musicalGenre = Self(.musicalGenre)

    /// A Boolean value that indicates whether the MIDI sequence contained in the file is setup for use with a General MIDI device.
    public static let isGeneralMidiSequence = Self(.isGeneralMidiSequence)

    /// The original key of an Apple loop. The key is the root note or tonic for the loop, and does not include the scale type.
    public static let appleLoopsRootKey = Self(.appleLoopsRootKey)

    /// The key filtering information of an Apple loop. Loops are matched against projects that often in a major or minor key.
    public static let appleLoopsKeyFilterType = Self(.appleLoopsKeyFilterType)

    /// The looping mode of an Apple loop.
    public static let appleLoopsLoopMode = Self(.appleLoopsLoopMode)

    /// The escriptive information of an Apple loop.
    public static let appleLoopDescriptors = Self(.appleLoopDescriptors)

    /// The category of the instrument.
    public static let musicalInstrumentCategory = Self(.musicalInstrumentCategory)

    /// The name of the instrument relative to the instrument category.
    public static let musicalInstrumentName = Self(.musicalInstrumentName)

    // MARK: - Media

    /// The duration of the content of file. Usually for videos and audio.
    public static let duration = Self(.duration)

    /// The media types (video, sound) present in the content.
    public static let mediaTypes = Self(.mediaTypes)

    /// The codecs used to encode/decode the media.
    public static let codecs = Self(.codecs)

    /// The total bit rate, audio and video combined, of the media.
    public static let totalBitRate = Self(.totalBitRate)

    /// The video bit rate of the media.
    public static let videoBitRate = Self(.videoBitRate)

    /// The audio bit rate of the media.
    public static let audioBitRate = Self(.audioBitRate)

    /// A Boolean value that indicates whether the media is prepared for streaming.
    public static let streamable = Self(.streamable)

    /// The delivery type of the media. Either `Fast start` or `RTSP`.
    public static let mediaDeliveryType = Self(.mediaDeliveryType)

    /// Original format of the media.
    public static let originalFormat = Self(.originalFormat)

    /// Original source of the media.
    public static let originalSource = Self(.originalSource)

    /// The director of the content.
    public static let director = Self(.director)

    /// The producer of the content.
    public static let producer = Self(.producer)

    /// The genre of the content.
    public static let genre = Self(.genre)

    /// The performers of the content.
    public static let performers = Self(.performers)

    /// The people that are visible in an image or movie or are written about in a document.
    public static let participants = Self(.participants)

    // MARK: - Image

    /// The pixel height of the contents. For example, the height of a image or video.
    public static let pixelHeight = Self(.pixelHeight)

    /// The pixel width of the contents. For example, the width of a image or video.
    public static let pixelWidth = Self(.pixelWidth)

    /// The pixel size of the contents. For example, the image size or the video frame size.
    public static let pixelSize = Self(.pixelSize)

    /// The total number of pixels in the contents. Same as `pixelHeight x pixelWidth`.
    public static let pixelCount = Self(.pixelCount)

    /// The color space model used by the contents. For example: `RGB`, `CMYK`, `YUV`, or `YCbCr`.
    public static let colorSpace = Self(.colorSpace)

    /// The number of bits per sample. For example, the bit depth of an image (8-bit, 16-bit etc...) or the bit depth per audio sample of uncompressed audio data (8, 16, 24, 32, 64, etc..).
    public static let bitsPerSample = Self(.bitsPerSample)

    /// A Boolean value that indicates whether a camera flash was used.
    public static let isFlashOn = Self(.isFlashOn)

    /// The actual focal length of the lens, in millimeters.
    public static let focalLength = Self(.focalLength)

    /// The manufacturer of the device used for the contents. For example: `Apple`, `Canon`.
    public static let deviceManufacturer = Self(.deviceManufacturer)

    /// The model of the device used for the contents. For example: `iPhone 13`.
    public static let deviceModel = Self(.deviceModel)

    /// The ISO speed used to acquire the contents.
    public static let isoSpeed = Self(.isoSpeed)

    /// The orientation of the contents.
    public static let orientation = Self(.orientation)

    /// The names of the layers in the file.
    public static let layerNames = Self(.layerNames)

    /// The aperture setting used to acquire the document contents. This unit is the APEX value.
    public static let aperture = Self(.aperture)

    /// The name of the color profile used by the document contents.
    public static let colorProfile = Self(.colorProfile)

    /// The resolution width, in DPI, of the contents.
    public static let dpiResolutionWidth = Self(.dpiResolutionWidth)

    /// The resolution height, in DPI, of the contents.
    public static let dpiResolutionHeight = Self(.dpiResolutionHeight)

    /// The resolution size, in DPI, of the contents.
    public static let dpiResolution = Self(.dpiResolution)

    /// The exposure mode used to acquire the contents.
    public static let exposureMode = Self(.exposureMode)

    /// The exposure time, in seconds, used to acquire the contents.
    public static let exposureTimeSeconds = Self(.exposureTimeSeconds)

    /// The version of the EXIF header used to generate the metadata.
    public static let exifVersion = Self(.exifVersion)

    /// The name of the camera company.
    public static let cameraOwner = Self(.cameraOwner)

    /// The actual focal length of the lens, in 35 millimeters.
    public static let focalLength35Mm = Self(.focalLength35Mm)

    /// The name of the camera lens model.
    public static let lensModel = Self(.lensModel)

    /// The direction of the item's image, in degrees from true north.
    public static let imageDirection = Self(.imageDirection)

    /// A Boolean value that indicates whether the image has an alpha channel.
    public static let hasAlphaChannel = Self(.hasAlphaChannel)

    /// A Boolean value that indicates whether a red-eye reduction was used to take the picture.
    public static let redEyeOnOff = Self(.redEyeOnOff)

    /// The metering mode used to take the image.
    public static let meteringMode = Self(.meteringMode)

    /// The smallest f-number of the lens. Ordinarily it is given in the range of 00.00 to 99.99.
    public static let maxAperture = Self(.maxAperture)

    /// The diameter of the diaphragm aperture in terms of the effective focal length of the lens.
    public static let fNumber = Self(.fNumber)

    /// The class of the exposure program used by the camera to set exposure when the image is taken. Possible values include: Manual, Normal, and Aperture priority.
    public static let exposureProgram = Self(.exposureProgram)

    /// The time of the exposure of the imge.
    public static let exposureTimeString = Self(.exposureTimeString)

    /// A Boolean value that indicates whether the file is a screen capture.
    public static let isScreenCapture = Self(.isScreenCapture)

    /// The screen capture rect of the file.
    public static let screenCaptureRect = Self(.screenCaptureRect)

    /// The screen capture type of the file.
    public static let screenCaptureType = Self(.screenCaptureType)

    /// The white balance setting of the camera when the picture was taken.
    public static let whiteBalance = Self(.whiteBalance)

    // MARK: - Messages / Mail

    /// The email addresses for the authors of this item.
    public static let authorEmailAddresses = Self(.authorEmailAddresses)

    /// The addresses for the authors of this item.
    public static let authorAddresses = Self(.authorAddresses)

    /// The recipients of this item.
    public static let recipients = Self(.recipients)

    /// The rmail addresses for the recipients of this item.
    public static let recipientEmailAddresses = Self(.recipientEmailAddresses)

    /// The addresses for the recipients of this item.
    public static let recipientAddresses = Self(.recipientAddresses)

    /// The instant message addresses related to this item.
    public static let instantMessageAddresses = Self(.instantMessageAddresses)

    /// The received dates for this item.
    public static let receivedDates = Self(.receivedDates)

    /// The received recipients for this item.
    public static let receivedRecipients = Self(.receivedRecipients)

    /// Received recipient handles for this item.
    public static let receivedRecipientHandles = Self(.receivedRecipientHandles)

    /// The received sendesr for this item.
    public static let receivedSenders = Self(.receivedSenders)

    /// The received sender handles for this item.
    public static let receivedSenderHandles = Self(.receivedSenderHandles)

    /// The received types for this item.
    public static let receivedTypes = Self(.receivedTypes)

    /// A Boolean value that indicates whether the file is likely to be considered a junk file.
    public static let isLikelyJunk = Self(.isLikelyJunk)

    // MARK: - iCloud

    /// A Boolean indicating whether the item is stored in the cloud.
    public static let isUbiquitousItem = Self(.isUbiquitousItem)

    /// The name of the item’s container as the system displays it to users.
    public static let ubiquitousItemContainerDisplayName = Self(.ubiquitousItemContainerDisplayName)

    /// A Boolean value that indicates whether the user or the system requests a download of the item.
    public static let ubiquitousItemDownloadRequested = Self(.ubiquitousItemDownloadRequested)

    public static let ubiquitousItemIsExternalDocument = Self(.ubiquitousItemIsExternalDocument)

    public static let ubiquitousItemURLInLocalContainer = Self(.ubiquitousItemURLInLocalContainer)

    /// A Boolean value that indicates whether the item has outstanding conflicts.
    public static let ubiquitousItemHasUnresolvedConflicts = Self(.ubiquitousItemHasUnresolvedConflicts)

    public static let ubiquitousItemIsDownloaded = Self(.ubiquitousItemIsDownloaded)

    /// A Boolean value that indicates whether the system is downloading the item.
    public static let ubiquitousItemIsDownloading = Self(.ubiquitousItemIsDownloading)

    /// A Boolean value that indicates whether data is present in the cloud for the item.
    public static let ubiquitousItemIsUploaded = Self(.ubiquitousItemIsUploaded)

    /// A Boolean value that indicates whether the system is uploading the item.
    public static let ubiquitousItemIsUploading = Self(.ubiquitousItemIsUploading)

    /// The percentage of the file that has already been downloaded from the cloud.
    public static let ubiquitousItemPercentDownloaded = Self(.ubiquitousItemPercentDownloaded)

    /// The percentage of the file that has already been downloaded from the cloud.
    public static let ubiquitousItemPercentUploaded = Self(.ubiquitousItemPercentUploaded)

    /// The download status of the item.
    public static let ubiquitousItemDownloadingStatus = Self(.ubiquitousItemDownloadingStatus)

    /// The error when downloading the item from iCloud fails.
    public static let ubiquitousItemDownloadingError = Self(.ubiquitousItemDownloadingError)

    /// The error when uploading the item to iCloud fails.
    public static let ubiquitousItemUploadingError = Self(.ubiquitousItemUploadingError)

    /// A Boolean value that indicates a shared item.
    public static let ubiquitousItemIsShared = Self(.ubiquitousItemIsShared)

    /// The current user’s permissions for the shared item.
    public static let ubiquitousSharedItemCurrentUserPermissions = Self(.ubiquitousSharedItemCurrentUserPermissions)

    public static let ubiquitousSharedItemCurrentUserRole = Self(.ubiquitousSharedItemCurrentUserRole)

    public static let ubiquitousSharedItemMostRecentEditorNameComponents = Self(.ubiquitousSharedItemMostRecentEditorNameComponents)

    public static let ubiquitousSharedItemOwnerNameComponents = Self(.ubiquitousSharedItemOwnerNameComponents)

    // MARK: - Query Content Relevance

    /**
     The relevance of the item's content,

     The value is a value between `0.0` and `1.0`.
     */
    public static let queryContentRelevance = Self(.queryContentRelevance)
}
