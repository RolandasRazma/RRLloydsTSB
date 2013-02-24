//
//  NSString+LWAdditions.h
//
//  Created by Rolandas Razma on 7/24/12.
//  Copyright (c) 2012 LeanWorks Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (UDAdditions)

- (BOOL)containsString:(NSString *)string;
- (NSString *)stringByAddingPercentEscapes;
- (NSString *)stringByReplacingPercentEscapes;
- (BOOL)matchesPredicateFormat:(NSString *)predicateFormat;
- (NSString *)stringByReplacingPattern:(NSString *)pattern withTemplate:(NSString *)template;
- (NSString *)stringByMatchingPattern:(NSString *)pattern;
- (NSString *)stringByMatchingPattern:(NSString *)pattern range:(NSUInteger)range;

@end
