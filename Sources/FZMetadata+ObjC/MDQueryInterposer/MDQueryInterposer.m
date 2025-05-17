//
//  MDQueryInterposer.m
//
//
//  Created by Florian Zand on 14.04.25.
//

#if TARGET_OS_OSX
#import <CoreServices/CoreServices.h>

extern Boolean swizzled_MDQueryExecute(MDQueryRef, CFOptionFlags);

Boolean my_MDQueryExecute(MDQueryRef query, CFOptionFlags flags) {
    return swizzled_MDQueryExecute(query, flags);
}

extern void swizzled_MDQuerySetBatchingParameters(MDQueryRef, MDQueryBatchingParams);

void my_MDQuerySetBatchingParameters(MDQueryRef query, MDQueryBatchingParams params) {
    swizzled_MDQuerySetBatchingParameters(query, params);
}

/*
extern MDQueryRef swizzled_MDQueryCreate(CFAllocatorRef allocator, CFStringRef queryString, CFArrayRef queryScope, CFArrayRef attributes);

MDQueryRef my_MDQueryCreate(CFAllocatorRef allocator, CFStringRef queryString, CFArrayRef queryScope, CFArrayRef attributes) {
    return swizzled_MDQueryCreate(allocator, queryString, queryScope, attributes);
}
 */

__attribute__((used)) static struct {
    const void *replacement;
    const void *original;
} interposers[] __attribute__((section("__DATA,__interpose"))) = {
    { (const void *)my_MDQuerySetBatchingParameters, (const void *)MDQuerySetBatchingParameters },
    { (const void *)my_MDQueryExecute, (const void *)MDQueryExecute },
    // { (const void *)my_MDQueryCreate, (const void *)MDQueryCreate },
};
#endif
