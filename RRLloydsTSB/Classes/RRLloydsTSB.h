//
//  RRLloydsTSB.h
//  RRLloydsTSB
//
//  Created by Rolandas Razma on 24/02/2013.
//  Copyright (c) 2013 Rolandas Razma. All rights reserved.
//

#import <Foundation/Foundation.h>


NSString * const RRLloydsTSBErrorDomain;


@interface RRLloydsTSB : NSObject

@property(nonatomic, readonly, getter=isConnected) BOOL connected;

- (id)initWithUser:(NSString *)user password:(NSString *)password secret:(NSString *)secret;
- (void)accounts:(void (^)(NSDictionary *accounts, NSError *error))accounts;

//- (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler

@end
