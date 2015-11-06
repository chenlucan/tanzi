//
//  MsgFormatter.m
//  tanzi
//
//  Created by Lucan Chen on 24/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import "MsgFormatter.h"

#include <stdlib.h>

@implementation MsgFormatter

+(NSString *)ToDeviceId {
    // HwType-UseType-OS-AppVersion-<Randome 4 digits>
    // iphone-phone-ios-1.0-<>
    NSMutableString * deviceid = [NSMutableString stringWithString:@"1-1-1-"];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    int randomNumber = 1000 + arc4random() % 8999;
    NSString *fourDigitRandNum = [NSString stringWithFormat:@"%d", randomNumber];
    [deviceid appendString:appVersion];
    [deviceid appendString:fourDigitRandNum];
    return deviceid;
}

+(NSDictionary *)ToHeartbeat:(NSString *)deviceid {
    NSDictionary* dataDict = @{@"MsgType"       : @1,
                               @"DeviceId"      : deviceid
                               };
    return dataDict;
}

+(NSDictionary *)ToOfferICECandidate:(NSString *)deviceid
                          ToDeviceId:(NSString *)toDeviceId
                               index:(NSInteger)ind
                                 mid:(NSString *)mid
                           candidate:(NSString *)cand {
    NSDictionary* dataDict = @{@"MsgType"       : @2,
                               @"DeviceId"      : deviceid,
                               @"ToDeviceId"    : toDeviceId,
                               @"ICECandidate"  : @{
                                       @"sdpMLineIndex" : [NSNumber numberWithInteger:ind],
                                       @"sdpMid"        : mid,
                                       @"candidate"     : cand
                                       }
                               };
    return dataDict;
}

+(NSDictionary *)ToOfferSessionDescription:(NSString *)deviceid
                                ToDeviceId:(NSString *)toDeviceId
                                      type:(NSString*)type
                                       sdp:(NSString *)sdp {
    NSDictionary* dataDict = @{@"MsgType"       : @3,
                               @"DeviceId"      : deviceid,
                               @"ToDeviceId"    : toDeviceId,
                               @"SessionDescription"  : @{
                                       @"type" : type,
                                       @"sdp"  : sdp                                       }
                               };
    return dataDict;
}

@end
