//
//  TRSNetworkAgent+Commons.h
//  Pods
//
//  Created by Gero Herkenrath on 04/07/16.
//
//

#import "TRSNetworkAgent.h"

@interface TRSNetworkAgent (Commons)

- (BOOL)didReturnErrorForTSID:(NSString *)tsID apiToken:(NSString *)apiToken failureBlock:(void (^)(NSError *error))failure;
- (NSError *)standardErrorForResponseCode:(NSInteger)code;

@end
