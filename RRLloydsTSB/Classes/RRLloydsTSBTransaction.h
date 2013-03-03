//
//  RRLloydsTSBTransaction.h
//  RRLloydsTSB
//
//  Created by Rolandas Razma on 03/03/2013.
//  Copyright (c) 2013 Rolandas Razma. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RRLloydsTSBTransaction : NSObject

@property(nonatomic, readonly) NSString *UUID;  // WARNING: if transaction will be created, canceled and created again UUID will be same
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSString *type;
@property(nonatomic, readonly) NSDate   *date;
@property(nonatomic, readonly, getter = isDebit) BOOL debit;
@property(nonatomic, readonly) NSDecimalNumber *balance;
@property(nonatomic, readonly) NSDecimalNumber *amount;

@end
