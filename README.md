RRLloydsTSB
=================

unofficial block based [Lloyds TSB](http://www.lloydstsb.com) API for iOS using web scraping 

### Usage
```objc
RRLloydsTSB *lloydsTSB = [[RRLloydsTSB alloc] initWithUser: account
                                                  password: password
                                                    secret: secret];
            
// List accounts
[_lloydsTSB accounts: ^(NSArray *accounts, NSError *error) {
    if( error ){
        NSLog(@"NSError: %@", error.description);
        return;
    }
                
    for( RRLloydsTSBAccount *account in accounts ){
        NSLog(@"accounts\n\tTitle: %@\n\tShort Code: %@\n\tAccount Number: %@\n\tBalance: £%@", account.title, account.shortCode, account.accountNumber, account.balance);

        // Get account statements for past 30 days
        [_lloydsTSB statementForAccount: account
                               fromDate: [NSDate dateWithTimeIntervalSinceNow: -86400.0 *30]
                                 toDate: [NSDate date]
                      completionHandler: ^(NSSet *statement, NSError *error) {
                        if( error ){
                            NSLog(@"NSError: %@", error.description);
                            return;
                        }
                                      
                        NSLog(@"%@", statement);
                    }];
                 
        break;
    }
}];
```