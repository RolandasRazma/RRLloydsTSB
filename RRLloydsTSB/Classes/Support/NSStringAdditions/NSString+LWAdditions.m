//
//  NSString+LWAdditions.m
//
//  Created by Rolandas Razma on 7/24/12.
//  Copyright (c) 2012 LeanWorks Ltd. All rights reserved.
//

#import "NSString+LWAdditions.h"


@implementation NSString (UDAdditions)


- (BOOL)containsString:(NSString *)string {
    return ([self rangeOfString:string].location != NSNotFound);
}


- (NSString *)stringByAddingPercentEscapes {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, CFSTR("!*’();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
}


- (NSString *)stringByReplacingPercentEscapes {
    return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                                 (__bridge CFStringRef)[self stringByReplacingOccurrencesOfString:@"+" withString:@" "],
                                                                                                 CFSTR(" "),
                                                                                                 kCFStringEncodingUTF8);
}


- (BOOL)matchesPredicateFormat:(NSString *)predicateFormat {
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", predicateFormat] evaluateWithObject:self];
}


- (NSString *)stringByReplacingPattern:(NSString *)pattern withTemplate:(NSString *)template {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: pattern
                                                                           options: 0
                                                                             error: &error];

    return [regex stringByReplacingMatchesInString: self
                                           options: 0
                                             range: NSMakeRange(0, self.length)
                                      withTemplate: template];
}


- (NSString *)stringByMatchingPattern:(NSString *)pattern {
    return [self stringByMatchingPattern:pattern range:0];
}


- (NSString *)stringByMatchingPattern:(NSString *)pattern range:(NSUInteger)range {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: pattern
                                                                           options: 0
                                                                             error: &error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:self options:NSMatchingReportCompletion range:NSMakeRange(0, self.length)];
    
    if( match.range.location != NSNotFound ){
        return [self substringWithRange: [match rangeAtIndex:range]];
    }
    
    return nil;
}


@end
