//
//  UIImage+TealiumAdditions.h
//  TealiumUtilities
//
//  Created by George Webster on 9/11/14.
//  Copyright (c) 2014 tealium. All rights reserved.
//

#import "UIImage+TealiumAdditions.h"

@implementation UIImage (TealiumAdditions)

+ (UIImage *) teal_imageWithColor:(UIColor *)color andSize:(CGSize)size {
    
    UIImage *image = nil;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,
                                   color.CGColor);
    CGContextFillRect(context, rect);
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
    
}

@end
