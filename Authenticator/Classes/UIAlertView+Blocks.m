//
//  UIAlertView+Blocks.m
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

#import "UIAlertView+Blocks.h"
@import ObjectiveC.runtime;


@implementation UIAlertView (Blocks)

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    self = [self initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles, nil];
    if (self) {
        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString *nextTitle = va_arg(args, NSString *); nextTitle != nil; nextTitle = va_arg(args, NSString *)) {
            [self addButtonWithTitle:nextTitle];
        }
        va_end(args);
    }
    return self;
}


#pragma mark - Properties

- (void)setClickedButtonHandler:(UIAlertViewButtonBlock)clickedButtonHandler
{
    objc_setAssociatedObject(self, @selector(clickedButtonHandler), clickedButtonHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIAlertViewButtonBlock)clickedButtonHandler
{
    return objc_getAssociatedObject(self, @selector(clickedButtonHandler));
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIAlertViewButtonBlock clickedButtonHandler = self.clickedButtonHandler;
    
    if (clickedButtonHandler) {
        clickedButtonHandler(alertView, buttonIndex);
    }
}

@end
