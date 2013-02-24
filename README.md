RRLloydsTSB
=================

unofficial block based [Lloyds TSB](http://www.lloydstsb.com) API for iOS using web scraping 

### Usage
```objc
RRLloydsTSB *lloydsTSB = [[RRLloydsTSB alloc] initWithUser: account
                                                  password: password
                                                    secret: secret];
            
[lloydsTSB accounts:^(NSDictionary *accounts, NSError *error) {
  NSLog(@"%@", accounts);
}];
```
