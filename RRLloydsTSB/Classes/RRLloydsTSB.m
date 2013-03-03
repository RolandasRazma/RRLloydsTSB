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
#import "RRLloydsTSBAccountPrivate.h"


NSString * const RRLloydsTSBErrorDomain = @"RRLloydsTSBErrorDomain";


@implementation RRLloydsTSB {
    NSString            *_user;
    NSString            *_password;
    NSString            *_secret;
    
    dispatch_queue_t    _mainDispatchQueue;
    BOOL                _connected;
    NSString            *_accounOpened;
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    dispatch_release(_mainDispatchQueue);
}


#pragma mark -
#pragma mark RRLloydsTSB


- (id)initWithUser:(NSString *)user password:(NSString *)password secret:(NSString *)secret {
    
    if( (self = [self init]) ){
        NSAssert(!_user.length || !_password.length || !_secret.length, @"Incorrect data");
            
        _user               = user;
        _password           = password;
        _secret             = secret;
        _mainDispatchQueue  = dispatch_queue_create("RRLloydsTSBMainSerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}


- (NSError *)connectWithWithUser:(NSString *)user password:(NSString *)password secret:(NSString *)secret {
    NSError *error = nil;
    
    @synchronized( self ){
        // We already connected - just return
        if( _connected ) return nil;

        NSString *html = [self callURL: [NSURL URLWithString:@"https://online.lloydstsb.co.uk/personal/logon/login.jsp"]
                                method: @"GET"
                                  data: nil
                                 error: &error];
 
        // Do we have error?
        if( error ) return error;

        // Parse out password request
        NSMutableDictionary *formData = [[self formDataInHTML:html] mutableCopy];
        [formData setObject:_user       forKey:@"frmLogin:strCustomerLogin_userID"];
        [formData setObject:_password   forKey:@"frmLogin:strCustomerLogin_pwd"];
        
        html = [self callURL: [NSURL URLWithString:@"https://online.lloydstsb.co.uk/personal/primarylogin"]
                      method: @"POST"
                        data: formData
                       error: &error];
        
        // Do we have error?
        if( error ) return error;
        
        // Parse out secret request
        formData = [[self formDataInHTML:html] mutableCopy];
        for( NSString *key in [[formData allKeys] reverseObjectEnumerator] ){
            if( ![key matchesPredicateFormat:@".*memInfo[0-9]+"] ) continue;
            
            NSInteger index = [[html stringByMatchingPattern:[NSString stringWithFormat:@"<label\\s+for\\s*=\\s*[\"']%@[\"'][^>]*>[ a-zA-Z]*(\\d+)[ a-zA-Z]*:</label>", key] range:1] intValue];
            
            NSAssert1(index>0, @"bad index for key %@", key);
            
            if( (NSUInteger)index <= _secret.length ){
                [formData setObject: [@"&nbsp;" stringByAppendingString: [[_secret substringWithRange:NSMakeRange((NSUInteger)index -1, 1)] lowercaseString]]
                             forKey: key];
            }else{
                [formData setObject: @"-" forKey:key];
            }
        }
        
        html = [self callURL: [NSURL URLWithString:@"https://secure2.lloydstsb.co.uk/personal/a/logon/entermemorableinformation.jsp"]
                      method: @"POST"
                        data: formData
                       error: &error];
        
        // Do we have error?
        if( error ) return error;
        
        // Set connection flag to not make connection next time
        _connected = ([html matchesPredicateFormat:@".*lnkcmd=lnkLogout.*"] || [html matchesPredicateFormat:@".*lnkcmd=lnkCustomerLogoff.*"]);
        
        if( !_connected ){
            return [NSError errorWithDomain:RRLloydsTSBErrorDomain code:kRRLloydsTSBInternalError userInfo:@{NSLocalizedDescriptionKey:@"Bad secret"}];
        }
    }
    
    return nil;
}


- (void)accounts:(void (^)(NSArray *accounts, NSError *error))completionHandler {

    dispatch_async(_mainDispatchQueue, ^{
        NSError *error = nil;
        
        // Connect if needed
        if( (error = [self connectWithWithUser:_user password:_password secret:_secret]) ) {
            dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(nil, error); });
            return;
        }

        NSString *html = [self callURL: [NSURL URLWithString:@"https://secure2.lloydstsb.co.uk/personal/a/account_overview_personal/"]
                                method: @"GET"
                                  data: nil
                                 error: &error];

        // Do we have error?
        if( error ){
            dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(nil, error); });
            return;
        }

        // Parse accounts
        NSMutableArray *accountsList = [NSMutableArray array];
        [html enumerateMatchesForPattern: @"accountDetails.*?<a[^>]+href\\s*=\\s*[\"'][^\"]*/viewaccount/[^\"]+NOMINATED_ACCOUNT=([a-z0-9]+)[^\"]*[\"'][^>]*>\\s*<img[^>]+>([^>]+)</a>.*?>\\s*Sort\\s+Code[^>]+>([^<]+).*?Account\\s+Number[^>]+>([^<]+).*?accountBalance.*?>\\s*Balance\\s*<[^>]+>([^<]+)"
                              usingBlock: ^(NSTextCheckingResult *checkingResult, BOOL *stop) {
                                  
                                  RRLloydsTSBAccount *lloydsTSBAccount = [[RRLloydsTSBAccount alloc] initWithUUID: [[html substringWithRange:[checkingResult rangeAtIndex:1]] trimmedString]];
                                  
                                  // Title
                                  [lloydsTSBAccount setTitle: [[html substringWithRange:[checkingResult rangeAtIndex:2]] trimmedString]];
                                  
                                  // Short Code
                                  [lloydsTSBAccount setShortCode: [[html substringWithRange:[checkingResult rangeAtIndex:3]] trimmedString]];
                                  
                                  // Account Number
                                  [lloydsTSBAccount setAccountNumber: [[html substringWithRange:[checkingResult rangeAtIndex:4]] trimmedString]];
                                  
                                  // Balance
                                  NSString *accountBalance = [[html substringWithRange:[checkingResult rangeAtIndex:5]] trimmedString];
                                  accountBalance = [accountBalance stringByReplacingOccurrencesOfString: @"[^\\d.]"
                                                                                             withString: @""
                                                                                                options: NSRegularExpressionSearch
                                                                                                  range: NSMakeRange(0, accountBalance.length)];
                                  
                                  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                                  [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                                  [numberFormatter setGeneratesDecimalNumbers:YES];
                                  NSNumber *balance = [numberFormatter numberFromString:accountBalance];
                                  [lloydsTSBAccount setBalance: (NSDecimalNumber *)(balance?balance:[NSDecimalNumber numberWithInt:0])];
                                  
                                  // Add to list
                                  [accountsList addObject: lloydsTSBAccount];
                              }];
        
        dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(accountsList, error); });
    });
    
}


- (void)statementForAccount:(RRLloydsTSBAccount *)account fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate completionHandler:(void (^)(NSArray *statement, NSError *error))completionHandler {
        
    dispatch_async(_mainDispatchQueue, ^{
        NSError *error = nil;
        
        // Connect if needed
        if( (error = [self connectWithWithUser:_user password:_password secret:_secret]) ) {
            dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(nil, error); });
            return;
        }
        
        // Open account if needed
        if( (error = [self openAccountWithUUID:account.UUID]) ){
            dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(nil, error); });
            return;
        }
        
        // Statements
        NSMutableArray *statement = [NSMutableArray array];
        
        // Number of calls requered to gett all statements (lloyds TSB allows export only fro 30d and 150 records)
        NSInteger numberOfDays = (NSInteger)ceil([toDate timeIntervalSinceDate:fromDate] /86400.0);
        NSUInteger dayIncrement = (NSUInteger)ceilf(numberOfDays /ceilf(numberOfDays /(27.0f *3.0f)));
        
        NSDate *nextToDate  = nil;
        NSDate *nextFromDate= fromDate;
        
        do {
            // Get new range
            nextToDate = [nextFromDate dateByAddingTimeInterval:dayIncrement *86400.0];
            if( [toDate compare:nextToDate] == NSOrderedAscending ){
                nextToDate = toDate;
            }

            NSDateComponents *fromDateComponents = [[NSCalendar currentCalendar] components: (NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:nextFromDate];
            NSDateComponents *toDateComponents   = [[NSCalendar currentCalendar] components: (NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:nextToDate];

            // Get export form
            NSString *html = [self callURL: [NSURL URLWithString:@"https://secure2.lloydstsb.co.uk/personal/a/viewproductdetails/ViewProductDetails.jsp"]
                                    method: @"GET"
                                      data: @{ @"lnkcmd": @"pnlgrpStatement:conS1:lkoverlay", @"al": @""}
                                     error: &error];
            
            // Error in request?
            if( error ){
                dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(nil, error); });
                return;
            }
            
            NSMutableDictionary *formData = [[self formDataInHTML:html] mutableCopy];
            formData[@"frmTest:dtSearchFromDate"]       = [NSString stringWithFormat:@"%02d", fromDateComponents.day];
            formData[@"frmTest:dtSearchFromDate.month"] = [NSString stringWithFormat:@"%02d", fromDateComponents.month];
            formData[@"frmTest:dtSearchFromDate.year"]  = [NSString stringWithFormat:@"%i",   fromDateComponents.year];
            formData[@"frmTest:dtSearchToDate"]         = [NSString stringWithFormat:@"%02d", toDateComponents.day];
            formData[@"frmTest:dtSearchToDate.month"]   = [NSString stringWithFormat:@"%02d", toDateComponents.month];
            formData[@"frmTest:dtSearchToDate.year"]    = [NSString stringWithFormat:@"%i",   toDateComponents.year];
            formData[@"frmTest:strExportFormatSelected"]= @"Internet banking text/spreadsheet (.CSV)";

            // Ask for export
            html = [self callURL: [NSURL URLWithString:@"https://secure2.lloydstsb.co.uk/personal/a/viewproductdetails/m44_exportstatement_fallback.jsp"]
                          method: @"POST"
                            data: formData
                           error: &error];
            
            // If export returned error
            if( error ){
                dispatch_async(dispatch_get_main_queue(), ^{ completionHandler(nil, error); });
                return;
            }
            
            // Parse export
            [html parseCSVUsingBlock: ^(NSDictionary *data) {
                [statement addObject:data];
            }];

            // Push new dates
            nextFromDate  = nextToDate;
            numberOfDays -= dayIncrement;
        } while ( numberOfDays > 0 );
        
        // Do callback
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler( statement, nil );
        });
    });
    
}


- (NSError *)openAccountWithUUID:(NSString *)UUID{
    if( [_accounOpened isEqualToString:UUID] ) return nil;
    
    _accounOpened = nil;
    
    NSError *error;
    
    NSString *html = [self callURL: [NSURL URLWithString:@"https://secure2.lloydstsb.co.uk/personal/a/viewaccount/accountoverviewpersonalbase.jsp"]
                            method: @"GET"
                              data: @{ @"NOMINATED_ACCOUNT": UUID,
                                                  @"lnkcmd": @"frm1:lstAccLst:lkImageRetail1",
                                                      @"al": @""}
                            error: &error];
    
    if( error ){
        return error;
    }else if( ![html containsString:@"lnkcmd=lkAccOverView_retail"] ){
        return [NSError errorWithDomain:RRLloydsTSBErrorDomain code:kRRLloydsTSBInternalError userInfo:@{NSLocalizedDescriptionKey:@"Unable to oppen account"}];
    }
    
    _accounOpened = UUID;
    
    return nil;
}


- (NSString *)callURL:(NSURL *)URL method:(NSString *)method data:(NSDictionary *)data error:(NSError **)error {
    
    NSMutableString *html = nil;
    NSError *internalError;

    if( URL.isFileURL ){
        html = [NSMutableString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&internalError];
    }else{
        NSMutableURLRequest *request = nil;

        // Build NSMutableURLRequest
        if( data.count ){
            NSMutableString *query = [NSMutableString string];
            [data enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
                if( query.length ) [query appendString:@"&"];
                [query appendFormat: @"%@=%@", [key stringByAddingPercentEscapes], (([value isKindOfClass:[NSNull class]])?@"":[[value description] stringByAddingPercentEscapes])];
            }];
            
            if( [method isEqualToString:@"GET"] ){
                NSString *absoluteURLString = URL.absoluteString;
                absoluteURLString = [absoluteURLString stringByAppendingFormat: ([absoluteURLString containsString:@"?"]?@"&%@":@"?%@"), query];

                request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:absoluteURLString]];
            }else if( [method isEqualToString:@"POST"] ){
                request = [NSMutableURLRequest requestWithURL:URL];
                [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                [request setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
            }else{
                NSAssert(NO, @"Unknown method");
            }
        }else{
            request = [NSMutableURLRequest requestWithURL:URL];
        }
        
        [request setHTTPMethod: method];
        [request addValue:@"Mozilla/5.0 (en-us) Gecko/x" forHTTPHeaderField:@"User-Agent"];
        [request addValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" forHTTPHeaderField:@"Accept"];

        // Query server
        NSHTTPURLResponse *urlResponse  = nil;
        
        NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&internalError];
        
        if( internalError ){
            // So we got request error...
        }else if( urlResponse.statusCode != 200 ){
            internalError = [NSError errorWithDomain: RRLloydsTSBErrorDomain
                                                code: kRRLloydsTSBServerError
                                            userInfo: @{NSLocalizedDescriptionKey:[NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode]}];
        }else if( response && response.length ){
            html = [[NSMutableString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        }else{
            internalError = [NSError errorWithDomain: RRLloydsTSBErrorDomain
                                                code: kRRLloydsTSBServerError
                                            userInfo: @{NSLocalizedDescriptionKey:@"Server call error"}];
        }
        
        // Cleanup HTML for easyer parsing
        if( !internalError && html.length && [[[urlResponse allHeaderFields] objectForKey:@"Content-Type"] containsString:@"text/htm"] ){
            [html replaceOccurrencesOfString:@"\r"      withString:@" "  options:0 range:NSMakeRange(0, html.length)];
            [html replaceOccurrencesOfString:@"\n"      withString:@" "  options:0 range:NSMakeRange(0, html.length)];
            [html replaceOccurrencesOfString:@"\t"      withString:@" "  options:0 range:NSMakeRange(0, html.length)];
            [html replaceOccurrencesOfString:@">\\s+<"  withString:@"><" options:NSRegularExpressionSearch range:NSMakeRange(0, html.length)];
            
            NSString *errorString = [[html stringByMatchingPattern:@"class\\s*=\\s*[\"']formSubmitError[\"'][^>]*>(.*?)</" range:1] trimmedString];
            if( errorString.length ){
                internalError = [NSError errorWithDomain:RRLloydsTSBErrorDomain code:kRRLloydsTSBServerError userInfo:@{NSLocalizedDescriptionKey:errorString}];
            }
        }
    }
    
    if( internalError ){
        if( error != NULL ) *error = internalError;
        return nil;
    }
    
    return html;
}


- (NSDictionary *)formDataInHTML:(NSString *)HTML {

    NSMutableDictionary *formData = [NSMutableDictionary dictionary];
    
    HTML = [HTML stringByMatchingPattern:@"<form.*?</form>"];

    // Parse out inputs
    NSRegularExpression *valueRegex = [NSRegularExpression regularExpressionWithPattern: @"value\\s*=\\s*[\"']([^\"]+)[\"']"
                                                                                options: NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionAnchorsMatchLines
                                                                                  error: NULL];

    [HTML enumerateMatchesForPattern: @"<input\\s+[^>]+name\\s*=\\s*[\"']([^\"]+)[\"'][^>]*>"
                          usingBlock: ^(NSTextCheckingResult *checkingResult, BOOL *stop) {
                              
                              NSString *outerHTML  = [HTML substringWithRange:[checkingResult rangeAtIndex:0]];
                              NSString *inputName  = [HTML substringWithRange:[checkingResult rangeAtIndex:1]];
                              NSString *inputValue = nil;
                              
                              NSTextCheckingResult *match = [valueRegex firstMatchInString:outerHTML options:NSMatchingReportCompletion range:NSMakeRange(0, outerHTML.length)];
                              if( match.range.location != NSNotFound ){
                                  inputValue = [outerHTML substringWithRange:[match rangeAtIndex:1]];
                              }
                              
                              [formData setObject:(inputValue?inputValue:[NSNull null]) forKey:inputName];
                              
                          }];

    // Parse out selects
    NSRegularExpression *optionRegex = [NSRegularExpression regularExpressionWithPattern: @"<option(\\s*value=\"([^\"]+)\")*(\\s*selected)*>(.*?)</option>"
                                                                                 options: ( NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionAnchorsMatchLines )
                                                                                   error: NULL];
    
    [HTML enumerateMatchesForPattern: @"<select[^>]+name\\s*=\\s*[\"']([^\"]+)[\"'][^>]*>(.*?)</select>"
                          usingBlock: ^(NSTextCheckingResult *selects, BOOL *stop) {
                              NSString *outerHTML  = [HTML substringWithRange:[selects rangeAtIndex:0]];
                              NSString *selectName = [HTML substringWithRange:[selects rangeAtIndex:1]];

                              NSArray *checkingResults = [optionRegex matchesInString: outerHTML
                                                                             options: NSMatchingReportCompletion
                                                                               range: NSMakeRange(0, outerHTML.length)];
                              
                              [checkingResults enumerateObjectsUsingBlock: ^(NSTextCheckingResult *options, NSUInteger index, BOOL *stop) {
                                  NSString *optionValue;
                                  
                                  NSRange range = [options rangeAtIndex:2];
                                  if( range.location != NSNotFound ){
                                      optionValue = [[outerHTML substringWithRange:range] trimmedString];
                                  }else{
                                      optionValue = [[outerHTML substringWithRange:[options rangeAtIndex:4]] trimmedString];
                                  }

                                  range = [options rangeAtIndex:3];
                                  if( range.location != NSNotFound ){
                                      *stop = YES;
                                      
                                      [formData setObject:optionValue forKey:selectName];
                                  }else if( index == 0 ){
                                      [formData setObject:optionValue forKey:selectName];
                                  }
                                  
                              }];
                          }];

    // we will newer use cancel
    [formData removeObjectForKey:@"frmTest:btnCancel"];
    
    return formData;
    
}


@end