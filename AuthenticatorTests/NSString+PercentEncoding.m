//
//  NSString+PercentEncoding.m
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

#import "NSString+PercentEncoding.h"


// For alternate implementations, see:
// https://github.com/Singly/iOS-SDK/blob/master/SinglySDK/SinglySDK/NSString%2BURLEncoding.m
// https://code.google.com/p/google-toolbox-for-mac/source/browse/trunk/Foundation/GTMNSString%2BURLArguments.m

@implementation NSString (PercentEncoding)

// NSString's stringByAddingPercentEscapesUsingEncoding: doesn't percent-encode the reserved
// characters defined in the URI specification ( https://tools.ietf.org/html/rfc3986#section-2.2 ).
// This method escapes every reserved character to produce a string which is a valid argument for a
// URL query string. (via http://simonwoodside.com/weblog/2009/4/22/how_to_really_url_encode/ )

- (NSString *)percentEncodedString
{
    CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                        (__bridge CFStringRef)(self),
                                                                        NULL,
                                                                        CFSTR(":/?#[]@!$&'()*+,;=%"),
                                                                        kCFStringEncodingUTF8);
    return CFBridgingRelease(escapedString);
}

// This method unescapes all percent-encoded characters to convert a string from a URL into a human-
// readable format. Prior to unescaping, it also converts all instances of '+' to spaces.

- (NSString *)percentDecodedString
{
    // If a "+" exists in this string, it represents a space, since a literal "+" should have been converted to "%2B"
    NSString *stringWithSpaces = [self stringByReplacingOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, self.length)];
    // Convert all percent-encoded characters back to their readable equivalents
    CFStringRef decodedString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                        (__bridge CFStringRef)(stringWithSpaces),
                                                                                        CFSTR(""),
                                                                                        kCFStringEncodingUTF8);
    return CFBridgingRelease(decodedString);
}

@end
