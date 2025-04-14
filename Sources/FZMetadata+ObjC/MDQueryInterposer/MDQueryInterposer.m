//
//  MDQueryInterposer.m
//  OnlyFansDownloader
//
//  Created by Florian Zand on 14.04.25.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import "include/MDQueryInterposer.h"

// Global handler storage
void (*MDQueryCreateHandler)(MDQueryRef) = NULL;
MDQueryBatchingParamsHandler MDQuerySetBatchingHandler = NULL;

// Interpose MDQueryCreate (optional)
MDQueryRef my_MDQueryCreate(CFAllocatorRef allocator, CFStringRef queryString, CFArrayRef valueList, CFArrayRef searchScopes) {
    MDQueryRef query = MDQueryCreate(allocator, queryString, valueList, searchScopes);

    if (MDQueryCreateHandler) {
        MDQueryCreateHandler(query);
    }

    return query;
}

// Interpose MDQuerySetBatchingParameters
void my_MDQuerySetBatchingParameters(MDQueryRef query, MDQueryBatchingParams params) {
    if (MDQuerySetBatchingHandler) {
        MDQuerySetBatchingHandler(query, &params);
    }

    MDQuerySetBatchingParameters(query, params);
}

// Interpose table
__attribute__((used)) static struct {
    const void *replacement;
    const void *original;
} interposers[] __attribute__((section("__DATA,__interpose"))) = {
    { (const void *)my_MDQueryCreate, (const void *)MDQueryCreate },
    { (const void *)my_MDQuerySetBatchingParameters, (const void *)MDQuerySetBatchingParameters }
};
