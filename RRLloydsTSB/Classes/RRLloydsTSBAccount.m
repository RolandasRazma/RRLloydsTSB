//
//  RRLloydsTSBAccount.m
//  RRLloydsTSB
//
//  Created by Rolandas Razma on 24/02/2013.
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

#import "RRLloydsTSBAccount.h"
#import "RRLloydsTSBAccountPrivate.h"


@implementation RRLloydsTSBAccount {
    NSString        *_UUID;
    NSString        *_title;
    NSString        *_shortCode;
    NSString        *_accountNumber;
    NSDecimalNumber *_balance;
}


#pragma mark -
#pragma mark NSObject


- (NSString *)description {
    return [NSString stringWithFormat: @"<%@: %p | UUID = %@ | title = %@>", [self class], self, _UUID, _title];
}


#pragma mark -
#pragma mark RRLloydsTSBAccount


- (id)initWithUUID:(NSString *)UUID {
    if( (self = [self init]) ){
        _UUID   = UUID;
    }
    return self;
}


@end
