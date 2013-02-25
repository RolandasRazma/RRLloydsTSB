RRLloydsTSB
=================

unofficial block based [Lloyds TSB](http://www.lloydstsb.com) API using web scraping for iOS

### Usage
```objc
RRLloydsTSB *lloydsTSB = [[RRLloydsTSB alloc] initWithUser: account
                                                  password: password
                                                    secret: secret];
            
// List accounts
[_lloydsTSB accounts:^(NSArray *accounts, NSError *error) {
                
    for( RRLloydsTSBAccount *account in accounts ){
        NSLog(@"accounts: %@", account);

        // Get account statements for past 30 days
        [_lloydsTSB statementForAccount: account
                               fromDate: [NSDate dateWithTimeIntervalSinceNow: -86400.0 *30]
                                 toDate: [NSDate date]
                      completionHandler: ^(NSArray *statement, NSError *error) {
                        NSLog(@"%@", statement);
        }];
                 
        break;
    }
                
}];
```

