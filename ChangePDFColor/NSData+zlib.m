//
//  NSData+GunData.m
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/9.
//

#import "NSData+zlib.h"
#import <zlib.h>

@implementation NSData (GunData)
- (NSData *)zippedDataWithCompressionLevel:(float)level
{
    if (self.length == 0)
    {
        return self;
    }

    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    stream.avail_in = (uint)self.length;
    stream.next_in = (Bytef *)(void *)self.bytes;
    stream.total_out = 0;
    stream.avail_out = 0;

    static const NSUInteger ChunkSize = 16384;

    NSMutableData *output = nil;
    int compression = (level < 0.0f)? Z_DEFAULT_COMPRESSION: (int)(roundf(level * 9));
    if (deflateInit(&stream, compression) == Z_OK)
    {
        output = [NSMutableData dataWithLength:ChunkSize];
        while (stream.avail_out == 0)
        {
            if (stream.total_out >= output.length)
            {
                output.length += ChunkSize;
            }
            stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
            stream.avail_out = (uInt)(output.length - stream.total_out);
            deflate(&stream, Z_FINISH);
        }
        deflateEnd(&stream);
        output.length = stream.total_out;
    }

    return output;
}

- (NSData *)zippedData
{
    return [self zippedDataWithCompressionLevel:-1.0f];
}

- (NSData *)unzipped {
    const UInt8 *bytes = (const UInt8 *)self.bytes;
    if (!(self.length >= 2 && bytes[0] == 0x78 && bytes[1] == 0x9c)) {
        return nil;
    }

    if (self.length == 0)
    {
        return self;
    }

    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.avail_in = (uint)self.length;
    stream.next_in = (Bytef *)self.bytes;
    stream.total_out = 0;
    stream.avail_out = 0;

    NSMutableData *output = nil;
    if (inflateInit(&stream) == Z_OK)
    {
        int status = Z_OK;
        output = [NSMutableData dataWithCapacity:self.length * 2];
        while (status == Z_OK)
        {
            if (stream.total_out >= output.length)
            {
                output.length += self.length / 2;
            }
            stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
            stream.avail_out = (uInt)(output.length - stream.total_out);
            status = inflate (&stream, Z_SYNC_FLUSH);
        }
        if (inflateEnd(&stream) == Z_OK)
        {
            if (status == Z_STREAM_END)
            {
                output.length = stream.total_out;
            }
        }
    }

    return output;
}

@end
