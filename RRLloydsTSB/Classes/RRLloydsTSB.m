//
//  RRLloydsTSB.m
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

#import "RRLloydsTSB.h"
#import "NSString+LWAdditions.h"


NSString * const RRLloydsTSBErrorDomain = @"RRLloydsTSBErrorDomain";


@implementation RRLloydsTSB {
    NSString            *_user;
    NSString            *_password;
    NSString            *_secret;
    
    BOOL                _connected;
    dispatch_queue_t    _dispatchQueue;
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    dispatch_release(_dispatchQueue);
}


#pragma mark -
#pragma mark RRLloydsTSB


- (id)initWithUser:(NSString *)user password:(NSString *)password secret:(NSString *)secret {
    
    if( (self = [self init]) ){
        NSAssert(!_user.length || !_password.length || !_secret.length, @"Incorrect data");
            
        _user           = user;
        _password       = password;
        _secret         = secret;
        _dispatchQueue  = dispatch_queue_create("RRLloydsTSBBackground", DISPATCH_QUEUE_CONCURRENT);
        
        // NSString *html = [self callURL:[[NSBundle mainBundle] URLForResource:@"" withExtension:nil] method:@"GET" data:nil];
    }
    
    return self;
}


- (NSError *)connectWithWithUser:(NSString *)user password:(NSString *)password secret:(NSString *)secret {
    
    NSError *error = nil;
    
    @synchronized( self ){
        if( _connected ) return error;
        
        NSString *html = [self callURL:[NSURL URLWithString:@"https://online.lloydstsb.co.uk/personal/logon/login.jsp?mobile=true"] method:@"GET" data:nil];
        
        // Parse out password request
        NSMutableDictionary *formData = [[self formDataInHTML:html] mutableCopy];
        if( formData.count ){
            [formData setObject:_user     forKey:@"frmLogin:strCustomerLogin_userID"];
            [formData setObject:_password forKey:@"frmLogin:strCustomerLogin_pwd"];
            
            html = [self callURL:[NSURL URLWithString:@"https://online.lloydstsb.co.uk/personal/mbprimarylogin"] method:@"POST" data:formData];
            
            // Parse out secret request
            formData = [[self formDataInHTML:html] mutableCopy];
            if( formData.count ){
                for( NSString *key in [[formData allKeys] reverseObjectEnumerator] ){
                    if( ![key matchesPredicateFormat:@".*formMem[0-9]+"] ) continue;
                    
                    NSInteger index = [[html stringByMatchingPattern:[NSString stringWithFormat:@"<label\\s+for\\s*=\\s*[\"']%@[\"'][^>]*>(\\d+)[a-z]+:</label>", key] range:1] intValue];
                    
                    NSAssert1(index>0, @"bad index for key %@", key);
                    
                    if( (NSUInteger)index <= _secret.length ){
                        [formData setObject: [@"&nbsp;" stringByAppendingString: [[_secret substringWithRange:NSMakeRange((NSUInteger)index -1, 1)] lowercaseString]]
                                     forKey: key];
                    }else{
                        [formData setObject:@"-" forKey:key];
                    }
                }
                
                html = [self callURL:[NSURL URLWithString:@"https://secure2.lloydstsb.co.uk/personal/a/useradmin/mobile/logon/entermemorableinformation.jsp"] method:@"POST" data:formData];
                
                _connected = [html matchesPredicateFormat:@".*lnkcmd=lnkLogout.*"];
                if( !_connected ){
                    error = [NSError errorWithDomain:RRLloydsTSBErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Bad secret"}];
                }
            }else{
                error = [NSError errorWithDomain:RRLloydsTSBErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Bad password"}];
            }
        }else{
            error = [NSError errorWithDomain:RRLloydsTSBErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Unknown error"}];
        }
    }
    
    return error;
}


- (void)accounts:(void (^)(NSDictionary *accounts, NSError *error))accounts {

    dispatch_async(_dispatchQueue, ^{
        NSError *error = nil;
        
        if( !self.isConnected ){
            if( (error = [self connectWithWithUser:_user password:_password secret:_secret]) ) {
                dispatch_async(dispatch_get_main_queue(), ^{ accounts(nil, error); });
                return;
            }
        }

        NSString *html = [self callURL:[NSURL URLWithString:@"https://secure2.lloydstsb.co.uk/personal/a/accountenquiry/mobile/viewaccountoverview/viewaccountoverview.jsp?lnkcmd=ltsblogo"] method:@"GET" data:nil];

        if( html.length ){
            NSRegularExpression *inputRegex = [NSRegularExpression regularExpressionWithPattern: @"<a[^>]+href\\s*=\\s*[\"'][^\"]*/viewaccountoverview/[^\"]+NOMINATED_ACCOUNT=([A-Z0-9]+)[^\"]*[\"'][^>]*><strong>(.*?)</strong>"
                                                                                        options: NSRegularExpressionCaseInsensitive
                                                                                          error: NULL];
            
            NSMutableDictionary *accountsList = [NSMutableDictionary dictionary];
            
            NSArray *checkingResults = [inputRegex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
            for ( NSTextCheckingResult *result in checkingResults ) {
                NSString *accountID    = [html substringWithRange:[result rangeAtIndex:1]];
                NSString *accountName  = [html substringWithRange:[result rangeAtIndex:2]];
                
                [accountsList setObject:accountName forKey:accountID];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{ accounts(accountsList, error); });
        }else{
            error = [NSError errorWithDomain:RRLloydsTSBErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Unknown error"}];
            dispatch_async(dispatch_get_main_queue(), ^{ accounts(nil, error); });
        }

    });
    
}


- (NSString *)callURL:(NSURL *)URL method:(NSString *)method data:(NSDictionary *)data {
    
    NSMutableString *html = nil;
    
    if( URL.isFileURL ){
        html = [NSMutableString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:NULL];
    }else{
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod: method];
        [request addValue:@"Mozilla/5.0 (iPhone; en-us) Mobile RRFinance" forHTTPHeaderField:@"User-Agent"];
        [request addValue:@"text/html;*/*" forHTTPHeaderField:@"Accept"];
        
        if( data.count ){
            NSMutableString *query = [NSMutableString string];
            [data enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
                if( query.length ) [query appendString:@"&"];
                [query appendFormat: @"%@=%@", [key stringByAddingPercentEscapes], (([value isKindOfClass:[NSNull class]])?@"":[value stringByAddingPercentEscapes])];
            }];
            
            if( [method isEqualToString:@"POST"] ){
                [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                [request setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }
        
        NSError *requestError = nil;
        NSHTTPURLResponse *urlResponse = nil;
        
        NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
        
        if( response && !requestError && response.length ){
            html = [[NSMutableString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        }else{
            NSLog(@"err %@ %@", requestError, urlResponse);
        }
    }
    
    [html replaceOccurrencesOfString:@"\n"      withString:@" "  options:0 range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"\r"      withString:@" "  options:0 range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@">\\s+<"  withString:@"><" options:NSRegularExpressionSearch range:NSMakeRange(0, html.length)];
    
    return html;
}


- (NSDictionary *)formDataInHTML:(NSString *)HTML {
    
    HTML = [HTML stringByMatchingPattern:@"<form.*?form>"];
    
    NSRegularExpression *inputRegex = [NSRegularExpression regularExpressionWithPattern: @"<(input|select)[^>]+name\\s*=\\s*[\"']([^\"]+)[\"'][^>]+>"
                                                                                options: NSRegularExpressionCaseInsensitive
                                                                                  error: NULL];
    
    NSRegularExpression *valueRegex = [NSRegularExpression regularExpressionWithPattern: @"value\\s*=\\s*[\"']([^\"]+)[\"']"
                                                                                options: NSRegularExpressionCaseInsensitive
                                                                                  error: NULL];
    
    NSMutableDictionary *formData = [NSMutableDictionary dictionary];
    
    NSArray *checkingResults = [inputRegex matchesInString:HTML options:0 range:NSMakeRange(0, HTML.length)];
    for ( NSTextCheckingResult *result in checkingResults ) {
        NSString *inputHTML  = [HTML substringWithRange:[result rangeAtIndex:0]];
        NSString *inputName  = [HTML substringWithRange:[result rangeAtIndex:2]];
        NSString *inputValue = nil;
        
        NSTextCheckingResult *match = [valueRegex firstMatchInString:inputHTML options:NSMatchingReportCompletion range:NSMakeRange(0, inputHTML.length)];
        if( match.range.location != NSNotFound ){
            inputValue = [inputHTML substringWithRange:[match rangeAtIndex:1]];
        }
        
        [formData setObject:(inputValue?inputValue:[NSNull null]) forKey:inputName];
    }
    
    return formData;
    
}


@end