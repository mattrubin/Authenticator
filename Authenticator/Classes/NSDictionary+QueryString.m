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


// For alternate implementations, see:
// https://github.com/Singly/iOS-SDK/blob/master/SinglySDK/SinglySDK/NSDictionary%2BQueryString.m
// https://code.google.com/p/google-toolbox-for-mac/source/browse/trunk/Foundation/GTMNSDictionary%2BURLArguments.m

@implementation NSDictionary (QueryString)

// This method parses the arguments of a query string and returns a dictionary containing the
// key-value pairs. All keys and values are returned as percent-decoded strings, and nested arguments
// are not supported. Keys without arguments will not be included in the dictionary, and duplicate
// keys will have their values overwritten.

+ (instancetype)dictionaryWithQueryString:(NSString *)queryString
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSArray *pairs = [queryString componentsSeparatedByString:@"&"];

    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        if (elements.count == 2) {
            NSString *key = [elements[0] percentDecodedString];
            NSString *value = [elements[1] percentDecodedString];
            dictionary[key] = value;
        }
    }

    return dictionary;
}

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
