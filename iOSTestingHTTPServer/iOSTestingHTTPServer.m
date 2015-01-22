//
//  iOSTesting-HTTP-Server.m
//
//  Created by Benjamin Whiting on 21/01/2015.
//  Copyright (c) 2015 VocaLink Holdings Limited. All rights reserved.
//

#import "iOSTestingHTTPServer.h"
#import <UIKit/UIKit.h>
#import "GCDWebServer.h"
#import "GCDWebServerURLEncodedFormRequest.h"

@interface iOSTestingHTTPServer()

@property (nonatomic, strong) GCDWebServer *webServer;
@end

@implementation iOSTestingHTTPServer

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        self.webServer = [GCDWebServer new];
    }
    return self;
}

+ (instancetype) sharedInstance
{
    static iOSTestingHTTPServer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
                  ^{
                      sharedInstance = [self new];
                  });
    return sharedInstance;
}

+ (void) startLocalWebServer
{
    [[iOSTestingHTTPServer sharedInstance] startWebServer];
}

- (void) startWebServer
{
    [self addPOSTHandler];
    [self.webServer startWithPort:8080 bonjourName:nil];
}

- (void) addPOSTHandler
{
    __weak typeof(self) weakSelf = self;
    [self.webServer addHandlerForMethod:@"POST"
                                   path:@"/"
                           requestClass:[GCDWebServerURLEncodedFormRequest class]
                           processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request)
     {
         __strong typeof(weakSelf) strongSelf = weakSelf;
         if(strongSelf)
         {
             NSDictionary* postArguments = [(GCDWebServerURLEncodedFormRequest*)request arguments];
             
             [strongSelf processPost:postArguments];
             
         }
         return nil;
     }];
}

- (void) processPost:(NSDictionary *) postArguments
{
    NSLog(@"Post %@", postArguments);
    if([[postArguments valueForKey:@"method"] isKindOfClass:[NSString class]])
    {
        NSString *methodName = [postArguments valueForKey:@"method"];
        SEL methodSelector = NSSelectorFromString(methodName);
        
        if([[UIApplication sharedApplication].delegate respondsToSelector:methodSelector])
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [[UIApplication sharedApplication].delegate performSelector:methodSelector withObject:postArguments];
#pragma clang diagnostic pop
        }
    }
}

+ (NSURL *) localWebServerURL
{
    return [iOSTestingHTTPServer sharedInstance].webServer.serverURL;
    
}

@end