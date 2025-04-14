//
//  MDQueryInterposer.h
//  OnlyFansDownloader
//
//  Created by Florian Zand on 14.04.25.
//

#import <CoreServices/CoreServices.h>


// Handler to observe/override MDQueryCreate (optional)
extern void (*MDQueryCreateHandler)(MDQueryRef);

// Handler to override batching parameters
typedef void (*MDQueryBatchingParamsHandler)(MDQueryRef, MDQueryBatchingParams *params);
extern MDQueryBatchingParamsHandler MDQuerySetBatchingHandler;
