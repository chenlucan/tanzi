//
//  MsgFormatter.h
//  tanzi
//
//  Created by Lucan Chen on 24/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MsgFormatter : NSObject

+(NSString *)RandStr4Digits;
    
+(NSString *)ToDeviceId;

+(NSDictionary *)ToHeartbeat:(NSString *)deviceid;

+(NSDictionary *)ToOfferICECandidate:(NSString *)deviceid
                          ToDeviceId:(NSString *)toDeviceId
                               index:(NSInteger)ind
                                 mid:(NSString *)mid
                           candidate:(NSString *)cand;

+(NSDictionary *)ToOfferSessionDescription:(NSString *)deviceid
                                ToDeviceId:(NSString *)toDeviceId
                                      type:(NSString*)type
                                       sdp:(NSString *)sdp;

@end
