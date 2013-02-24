RRLloydsTSB
=================

unofficial block based [Lloyds TSB](http://www.lloydstsb.com) API using web scraping for iOS

### Usage
```objc
RRLloydsTSB *lloydsTSB = [[RRLloydsTSB alloc] initWithUser: account
                                                  password: password
                                                    secret: secret];
            
[lloydsTSB accounts:^(NSDictionary *accounts, NSError *error) {
  NSLog(@"%@", accounts);
}];
```
