//
//  RRLloydsTSBTransaction.m
//  RRLloydsTSB
//
//  Created by Rolandas Razma on 03/03/2013.
//  Copyright (c) 2013 Rolandas Razma. All rights reserved.
//

#import "RRLloydsTSBTransaction.h"
#import <CommonCrypto/CommonDigest.h>


@implementation RRLloydsTSBTransaction {
    NSDictionary    *_dictionary;
    NSString        *_UUID;
    NSDate          *_date;
    NSDecimalNumber *_balance;
    NSDecimalNumber *_amount;
    BOOL            _debit;
}


#pragma mark -
#pragma mark NSObject


- (NSString *)description {
    return [NSString stringWithFormat: @"<%@: %p | type = %@ | title = %@>", [self class], self, self.type, self.title];
}


- (BOOL)isEqual:(RRLloydsTSBTransaction *)object {
    if( ![object isKindOfClass:[RRLloydsTSBTransaction class]] ) return NO;
    return [self.UUID isEqualToString:object.UUID];
}


- (NSUInteger)hash {
    return [self.UUID hash];
}


#pragma mark -
#pragma mark RRLloydsTSBTransaction


- (id)initWithDictionary:(NSDictionary *)dictionary {
    if( (self = [self init]) ){
        _dictionary = dictionary;
        _debit      = [[_dictionary objectForKey:@"Debit Amount"] length] > [[_dictionary objectForKey:@"Credit Amount"] length];
    }
    return self;
}


- (NSString *)UUID {
    if( !_UUID ){
        @synchronized( self ){
            if( _UUID ) return _UUID;

            const char *str = [[_dictionary description] UTF8String];
            unsigned char digest[CC_MD5_DIGEST_LENGTH];
            CC_MD5(str, strlen(str), digest);
            
            _UUID = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];
        }
    }
    return _UUID;
}


- (NSString *)title {
    return [_dictionary objectForKey:@"Transaction Description"];
}


- (NSString *)type {
    return [_dictionary objectForKey:@"Transaction Type"];
}


- (NSDate *)date {
    if( !_date ){
        @synchronized( self ){
            if( _date ) return _date;

            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [dateFormatter setDateFormat:@"dd/MM/yyyy"];
            
            _date = [dateFormatter dateFromString:[_dictionary objectForKey:@"Transaction Date"]];
        }
    }
    return _date;
}


- (NSDecimalNumber *)balance {
    if( !_balance ){
        @synchronized( self ){
            if( _balance ) return _balance;
            
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [numberFormatter setGeneratesDecimalNumbers:YES];
            
            _balance = (NSDecimalNumber *)[numberFormatter numberFromString:[_dictionary objectForKey:@"Balance"]];
        }
    }
    return _balance;
}


- (NSDecimalNumber *)amount {
    if( !_amount ){
        @synchronized( self ){
            if( _amount ) return _amount;
            
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [numberFormatter setGeneratesDecimalNumbers:YES];
            
            if( self.isDebit ){
                _amount = (NSDecimalNumber *)[numberFormatter numberFromString:[_dictionary objectForKey:@"Debit Amount"]];
            }else{
                _amount = (NSDecimalNumber *)[numberFormatter numberFromString:[_dictionary objectForKey:@"Credit Amount"]];
            }
        }
    }
    return _amount;
}


@end
