//
//  ServerConnection.m
//  RevitServerClient
//
//  Created by Adam Nagy on 02/04/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import "ServerConnection.h"

@implementation ServerConnection

///////////////////////////////////////////////////////////////////////
// Static Properties //////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

static NSString * _ipWithSvc = nil;
//static ServerConnection * _server = nil;
//static NSMutableArray * _conns = nil;

// The folder path of the content eing shown in the Master View
// The root is "|"
static NSString * _currentPath = @"|";

// Contains the folder path needed plus the request string
// e.g.: "|Folder|SubFolder/DirectoryInfo" or "|MyFolder|MyModel.rvt/history"
static NSString * _currentDetailRequestWithPath = @"";

@synthesize requestId = _requestId;
@synthesize conn = _conn;
@synthesize requestHandler = _requestHandler;

+ (NSString *)generateUuidString
{
    // Create a new UUID
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    
    // Create a new CFStringRef 
    NSString *uuidString = (__bridge NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    
    // release the UUID
    CFRelease(uuid);
    
    return uuidString;
}

+ (void)showError:(NSString *)text
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Server Connection Error" message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil ];
    
    [alert show];
}

+ (void)setIp:(NSString *)ip
{
    _ipWithSvc = [NSString stringWithFormat:@"%@%@%@", @"http://", ip, @"/RevitServerAdminRESTService2013/AdminRESTService.svc"];
    
    _currentPath = @"|";
    _currentDetailRequestWithPath = @"";
    
    //_conns = [[NSMutableArray alloc] init];
}

+ (NSString *)getPath
{
    return _currentPath;
}

+ (void)setPath:(NSString *)path
{
    _currentPath = path;
}

+ (NSString *)getDetailRequest
{
    return _currentDetailRequestWithPath;
}

+ (void)setDetailRequest:(NSString *)request
{
    _currentDetailRequestWithPath = request;
}
 
static char * colors[] = {"#ffffff", "#000000", "#000000"};
static char * bgcolors[] = {"#3366cc", "#dddddd", "#ffffff"};

+ (NSString *)getHtmlString:(NSString *)str withIndent:(int)indent
{
    assert(indent < 3);
    
    if ([str rangeOfString:@"/Date("].location != NSNotFound)
    {
        NSRange range;
        range.location = 6;
        range.length = [str length] - 8;
        str = [str substringWithRange:range];  
        long long i = [str longLongValue];
        i = i / 1000; // Milliseconds to seconds
        NSDate * date = [NSDate dateWithTimeIntervalSince1970:i];
        str = [date description];
    }
    
    NSString * newString = [NSString stringWithFormat:
    @"<div style=\"padding:2px 10px; background-color:%s; color:%s; margin:0px; text-indent:%dpx; font-size:%d%%; font-weight:%d\">%@</div>",
        bgcolors[indent % 3], 
        colors[indent % 3],
        (indent * 10),
        120 - (indent * 5),
        650 - (indent * 25),                    
        str];
    
    return newString;
}

+ (NSMutableArray *)getDataAsList:(NSDictionary *)content forItem:(NSString *)item andSubItem:(NSString *)subItem 
{
    NSMutableArray * list = [[NSMutableArray alloc] init];
    
    for (NSString * key in content)
    {
        if ([key isEqualToString:item])
        {
            //NSLog(@"Main key = %@", key);
            NSArray * value = [content valueForKey:key];
            for (NSDictionary * dict in value)
            {
                for (NSString * subKey in dict)
                {                
                    //NSLog(@"Sub key = %@", subKey);
                    //NSLog(@"Sub value = %@", [dict valueForKey:subKey]);
                    if ([subKey isEqualToString:subItem])
                        [list addObject:[dict valueForKey:subKey]];
                }
            }
        }
        //NSLog(@"Key = %@\n", key);
    }
    
    return list;
}

// Just a local, non public function to help getDataAsHtmlString function
+ (void)getDataAsHtmlStringRecursive:(NSObject *)content withIndent:(int)indent asHtmlString:(NSMutableString **)text
{
    if ([content isKindOfClass:[NSDictionary class]])
    {
        NSDictionary * dict = (NSDictionary *)content;
        for (NSString * key in dict)
        {
            [(*text) 
             appendString: [ServerConnection 
                            getHtmlString: key 
                            withIndent: indent]]; 
            
            [ServerConnection 
             getDataAsHtmlStringRecursive: [dict valueForKey:key]
             withIndent: indent + 1 
             asHtmlString: text];
        }
    }  
    else if ([content isKindOfClass:[NSArray class]])
    {
        NSArray * arr = (NSArray *)content;
        for (NSObject * element in arr)
        {
            [ServerConnection 
             getDataAsHtmlStringRecursive: element
             withIndent: indent 
             asHtmlString: text];
        }        
    }
    else 
    {
        [(*text) 
         appendString: [ServerConnection 
                        getHtmlString: [content description] 
                        withIndent: indent]]; 
    }        
}

+ (NSString *)getDataAsHtmlString:(NSObject *)content withIndent:(int)indent 
{
    assert(indent < 3);
    
    NSMutableString * text = [[NSMutableString alloc] init];
    
    [ServerConnection getDataAsHtmlStringRecursive:content withIndent:indent asHtmlString:&text];
    
    return text;
}

+ (ServerConnection *)getData:(id<ServerConnectionDataReadyDelegate>)handler ofRequestType:(NSString *)requestType withRequest:(NSString *)request withRequestId:(int)requestId
{
    // If we have no path to the Server then no point
    // of trying to send a request
    if (_ipWithSvc == nil)
        return nil;
 
    //[ServerConnection cancelData:handler];
    
    NSString * fullIP = [NSString stringWithFormat:@"%@%@%@", _ipWithSvc, @"/", [request stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL * url = [NSURL URLWithString:fullIP];
    NSMutableURLRequest * fullRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    
    [fullRequest setHTTPMethod:requestType];
    
    [fullRequest addValue:@"Adam" forHTTPHeaderField:@"User-Name"];
    [fullRequest addValue:@"AdamPC" forHTTPHeaderField:@"User-Machine-Name"];
    [fullRequest addValue:[ServerConnection generateUuidString] forHTTPHeaderField:@"Operation-GUID"];
    
    ServerConnection * server = [ServerConnection connectionWithRequestId:requestId];
    server.requestHandler = handler;
    server.conn = [[NSURLConnection alloc] initWithRequest:fullRequest delegate:server];
    
    return server;
}

- (void)cancelData
{
    [self.conn cancel];
}

+ (ServerConnection *)connectionWithRequestId:(int)requestId
{
    ServerConnection * newConnection = [[ServerConnection alloc] init];
    
    newConnection.requestId = requestId;
    
    return newConnection;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.requestHandler responseReady:response withRequestId:self.requestId];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSError * error = nil;
    NSDictionary * jsonArray = 
    [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error: &error]; 
    
    [ServerConnection dumpDictionary:jsonArray];
    
    [self.requestHandler dataReady:jsonArray withRequestId:self.requestId];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [ServerConnection showError:[error localizedDescription]];
    
    [self.requestHandler dataReady:nil withRequestId:self.requestId];
}

# pragma mark - For Testing

+ (void)dumpDictionary:(NSDictionary *)content
{
    for (NSString * key in content) 
    {
        printf("%s\n", [key UTF8String]);
        NSObject * value = [content objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]])
        {
            [ServerConnection dumpDictionary:(NSDictionary *)value];
        }  
        else if ([value isKindOfClass:[NSArray class]])
        {
            [ServerConnection dumpArray:(NSArray *)value];
        }
        else 
        {
            NSString * valueString = [value description];
            printf("  %s\n", [valueString UTF8String]);
        }        
    }
}

+ (void)dumpArray:(NSArray *)content
{
    for (NSObject * item in content) 
    {
        if ([item isKindOfClass:[NSDictionary class]])
        {
            [ServerConnection dumpDictionary:(NSDictionary *)item];
        }
        else 
        {
            NSString * valueString = [item description];
            printf("  %s\n", [valueString UTF8String]);
        }
    }    
}

@end
