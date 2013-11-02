//
//  NSDictionary+QueryString.m
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSDictionary+QueryString.h"
#import "NSString+PercentEncoding.h"


@implementation NSDictionary (QueryString)

// This method returns a simple query-string-style representation of the dictionary.
// All keys and values are expected to be strings, and if they are not then this method will attempt
// to serialize them using the -description method. Keys and values are percent-encoded before being
// added to the query string.

- (NSString *)queryString
{
    NSMutableArray *keyValuePairs = [NSMutableArray arrayWithCapacity:self.count];
    for (id key in self) {
        id value = self[key];
        NSString *keyValueString = [NSString stringWithFormat:@"%@=%@", [[key description] percentEncodedString], [[value description] percentEncodedString]];
        [keyValuePairs addObject:keyValueString];
    }
    return [keyValuePairs componentsJoinedByString:@"&"];
}

@end
