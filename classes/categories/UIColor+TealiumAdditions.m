//
//  UIColor+TealiumAdditions.m
//  TealiumUtilities
//
//  Created by Jason Koo & George Webster
//  Copyright (c) 2014 tealium. All rights reserved.
//

#import "UIColor+TealiumAdditions.h"

@implementation UIColor (TealiumAdditions)

+ (UIColor *) teal_colorWithHexString:(NSString *)hexString {
    
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = TEALColorComponent(colorString, 1, 1);
            green = TEALColorComponent(colorString, 1, 1);
            blue  = TEALColorComponent(colorString, 2, 1);
            break;
        case 4: // #ARGB
            alpha = TEALColorComponent(colorString, 0, 1);
            red   = TEALColorComponent(colorString, 1, 1);
            green = TEALColorComponent(colorString, 2, 1);
            blue  = TEALColorComponent(colorString, 3, 1);
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = TEALColorComponent(colorString, 0, 2);
            green = TEALColorComponent(colorString, 2, 2);
            blue  = TEALColorComponent(colorString, 4, 2);
            break;
        case 8: // #AARRGGBB
            alpha = TEALColorComponent(colorString, 0, 2);
            red   = TEALColorComponent(colorString, 2, 2);
            green = TEALColorComponent(colorString, 4, 2);
            blue  = TEALColorComponent(colorString, 6, 2);
            break;
        default:
            alpha = 0.5;
            red = 0.5;
            green = 0.5;
            blue = 0.5;
            break;
    }
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *) teal_randomColor {
    
    CGFloat hue         = ( arc4random() % 256 / 256.0 );           //  0.0 to 1.0
    CGFloat saturation  = ( arc4random() % 128 / 256.0 ) + 0.5;     //  0.5 to 1.0, away from white
    CGFloat brightness  = ( arc4random() % 128 / 256.0 ) + 0.5;     //  0.5 to 1.0, away from black
    
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

CGFloat TEALColorComponent(NSString *string, NSUInteger start, NSUInteger length) {
    
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

@end
