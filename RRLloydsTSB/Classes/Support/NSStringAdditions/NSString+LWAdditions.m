//
//  NSString+LWAdditions.m
//
//  Created by Rolandas Razma on 7/24/12.
//
//  Copyright (c) 2013 Rolandas Razma <rolandas@razma.lt>
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "NSString+LWAdditions.h"


@implementation NSString (UDAdditions)


- (NSString *)stringByAddingPercentEscapes {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, CFSTR("!*’();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
}


- (NSString *)stringByReplacingPercentEscapes {
    return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                                 (__bridge CFStringRef)[self stringByReplacingOccurrencesOfString:@"+" withString:@" "],
                                                                                                 CFSTR(" "),
                                                                                                 kCFStringEncodingUTF8);
}


- (BOOL)containsString:(NSString *)string {
    return ([self rangeOfString:string].location != NSNotFound);
}


- (BOOL)matchesPredicateFormat:(NSString *)predicateFormat {
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", predicateFormat] evaluateWithObject:self];
}


- (NSString *)stringByMatchingPattern:(NSString *)pattern {
    return [self stringByMatchingPattern:pattern range:0];
}


- (NSString *)stringByMatchingPattern:(NSString *)pattern range:(NSUInteger)range {
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: pattern
                                                                           options: ( NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionAnchorsMatchLines )
                                                                             error: NULL];
    
    NSTextCheckingResult *match = [regex firstMatchInString: self
                                                    options: NSMatchingReportCompletion
                                                      range: NSMakeRange(0, self.length)];
    
    if( match.range.location != NSNotFound ){
        return [self substringWithRange: [match rangeAtIndex:range]];
    }
    
    return nil;
}


- (NSArray *)matchesForPattern:(NSString *)pattern {
    NSRegularExpression *inputRegex = [NSRegularExpression regularExpressionWithPattern: pattern
                                                                                options: ( NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionAnchorsMatchLines )
                                                                                  error: NULL];
    
    return [inputRegex matchesInString: self
                               options: NSMatchingReportCompletion
                                 range: NSMakeRange(0, self.length)];
}


- (BOOL)parseCSVUsingBlock:(void (^)(NSDictionary *data))block {
    
    NSArray *keys = nil;
    
    NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
    
    NSScanner *lineScanner = [NSScanner scannerWithString:self];
    [lineScanner setCharactersToBeSkipped:newlineCharacterSet];
    
    NSString *newLine;
    while ( [lineScanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&newLine] || ![lineScanner isAtEnd] ) {
        NSMutableArray *lineData = [[newLine componentsSeparatedByString:@","] mutableCopy];
        if( !keys ){
            keys = lineData;
            continue;
        }
        
        NSAssert(keys.count>=lineData.count, @"less keys than data?");
        
        if( lineData.count < keys.count ){
            [lineData addObject:@""];
        }
        
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjects:lineData forKeys:keys];
        [data removeObjectForKey:@""];
        
        block( data );
    }
    
    
    return YES;
}


@end
