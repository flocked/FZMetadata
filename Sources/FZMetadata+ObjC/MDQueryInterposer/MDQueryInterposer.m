//
//  MDQueryInterposer.m
//
//
//  Created by Florian Zand on 14.04.25.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import "include/MDQueryInterposer.h"

extern void swizzled_MDQuerySetBatchingParameters(MDQueryRef, MDQueryBatchingParams);
extern MDQueryRef swizzled_MDQueryCreate(CFAllocatorRef alloc, CFStringRef queryString, CFArrayRef attrList, CFArrayRef scopeList);

MDQueryRef my_MDQueryCreate(CFAllocatorRef allocator, CFStringRef queryString, CFArrayRef valueList, CFArrayRef searchScopes) {
    return swizzled_MDQueryCreate(allocator, queryString, valueList, searchScopes);
}

void my_MDQuerySetBatchingParameters(MDQueryRef query, MDQueryBatchingParams params) {
    swizzled_MDQuerySetBatchingParameters(query, params);
}

__attribute__((used)) static struct {
    const void *replacement;
    const void *original;
} interposers[] __attribute__((section("__DATA,__interpose"))) = {
    { (const void *)my_MDQueryCreate, (const void *)MDQueryCreate },
    { (const void *)my_MDQuerySetBatchingParameters, (const void *)MDQuerySetBatchingParameters }
};
