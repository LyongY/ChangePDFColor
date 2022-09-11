//
//  NSData+GunData.h
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (GunData)

- (NSData *)zippedData;
- (NSData *)unzipped;

@end

NS_ASSUME_NONNULL_END
