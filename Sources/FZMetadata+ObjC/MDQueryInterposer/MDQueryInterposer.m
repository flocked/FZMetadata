//
//  MDQueryInterposer.m
//
//
//  Created by Florian Zand on 14.04.25.
//

#import <CoreServices/CoreServices.h>

extern void swizzled_MDQuerySetBatchingParameters(MDQueryRef, MDQueryBatchingParams);

void my_MDQuerySetBatchingParameters(MDQueryRef query, MDQueryBatchingParams params) {
    swizzled_MDQuerySetBatchingParameters(query, params);
}

__attribute__((used)) static struct {
    const void *replacement;
    const void *original;
} interposers[] __attribute__((section("__DATA,__interpose"))) = {
    { (const void *)my_MDQuerySetBatchingParameters, (const void *)MDQuerySetBatchingParameters }
};
