//
//  GooglePlacesAPIClient.m
//  DijkstraCodingChallenge
//
//  Created by Greg on 9/2/15.
//  Copyright (c) 2015 Greg. All rights reserved.
//

#import "GooglePlacesAPIClient.h"
#import "Mantle.h"
#import "DCPlace.h"

static NSString * const baseURL = @"https://maps.googleapis.com/maps/api/place/";
static NSString * const serverKey = @"AIzaSyAbA_Bl3c86E5I2yXrnYMNjkjxILDbsKGU";


@implementation GooglePlacesAPIClient
+ (GooglePlacesAPIClient *)sharedHTTPClient
{
    static GooglePlacesAPIClient *_sharedHTTPClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedHTTPClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
    });
    
    return _sharedHTTPClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        
    }
    
    return self;
}

-(void)fetchPlacesWithLongitude:(double)longitude
                      andLatitude:(double)latitude
                 withSuccessBlock:(void (^)(NSURLSessionDataTask *task, NSArray * products))successBlock
                     andFailBlock:(void (^)(NSURLSessionDataTask *task, NSError *error))failBlock{
    
    NSDictionary * params = @{
                              @"location" : [NSString stringWithFormat:@"%f,%f",latitude,longitude],
                              @"radius" : @1500,
                              @"types" : @"bar",
                              @"key" : serverKey
                            };
    
    [self GET:@"nearbysearch/json" parameters:params
      success:^(NSURLSessionDataTask * task, id responseObject) {
          NSDictionary * response = (NSDictionary*) responseObject;
          
          NSArray * jsonArray = (NSArray *)[response objectForKey:@"results"];
          
          NSError * error = nil;
          
          if(jsonArray.count > 0)
          {
              NSArray * places =[MTLJSONAdapter modelsOfClass:[DCPlace class] fromJSONArray:jsonArray error:&error];
              
              successBlock(task, places);
          }
          else{
              error = [[NSError alloc]initWithDomain:@"CCEmptyResults" code:0 userInfo:nil];
              
              failBlock(task, error);
          }
          
      } failure:failBlock];
    
    
}


@end
