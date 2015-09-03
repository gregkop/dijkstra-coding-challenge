//
//  GooglePlacesAPIClient.h
//  DijkstraCodingChallenge
//
//  Created by Greg on 9/2/15.
//  Copyright (c) 2015 Greg. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface GooglePlacesAPIClient : AFHTTPSessionManager

+ (GooglePlacesAPIClient *)sharedHTTPClient;
- (instancetype)initWithBaseURL:(NSURL *)url;

-(void)fetchPlacesWithLongitude:(double)longitude
                      andLatitude:(double)latitude
                 withSuccessBlock:(void (^)(NSURLSessionDataTask *task, NSArray * placesResults))successBlock
                     andFailBlock:(void (^)(NSURLSessionDataTask *task, NSError *error))failBlock;


@end
