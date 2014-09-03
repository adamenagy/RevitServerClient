//
//  ServerConnection.h
//  RevitServerClient
//
//  Created by Adam Nagy on 02/04/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServerConnectionDataReadyDelegate 
@optional
-(void)dataReady:(NSDictionary *)data withRequestId:(int)requestId;
-(void)responseReady:(NSURLResponse *)data withRequestId:(int)requestId;
@end

@interface ServerConnection : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, assign) int requestId; 
@property (strong, nonatomic) NSURLConnection * conn;
@property (strong, nonatomic) id<ServerConnectionDataReadyDelegate> requestHandler;

+ (ServerConnection *)connectionWithRequestId:(int)requestId;

+ (NSString *)generateUuidString;

+ (void)showError:(NSString *)text;

+ (NSString *)getPath;

+ (void)setPath:(NSString *)path;

+ (NSString *)getDetailRequest;

+ (void)setDetailRequest:(NSString *)request;

+ (ServerConnection *)getData:(id<ServerConnectionDataReadyDelegate>)handler ofRequestType:(NSString *)requestType withRequest:(NSString *)request withRequestId:(int)requestId;

- (void)cancelData;

+ (void)setIp:(NSString *)ip;

+ (NSString *)getHtmlString:(NSString *)str withIndent:(int)indent; 

+ (NSString *)getDataAsHtmlString:(NSObject *)content withIndent:(int)indent;

+ (NSMutableArray *)getDataAsList:(NSDictionary *)content forItem:(NSString *)item andSubItem:(NSString *)subItem;

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;

# pragma mark - For Testing

+ (void)dumpArray:(NSArray *)content;

+ (void)dumpDictionary:(NSDictionary *)content;

@end
