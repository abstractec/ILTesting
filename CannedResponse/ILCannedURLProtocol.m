//
//  ILCannedURLProtocol.m
//
//  Created by Claus Broch on 10/09/11.
//  Copyright 2011 Infinite Loop. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted
//  provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice, this list of conditions 
//    and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright notice, this list of 
//    conditions and the following disclaimer in the documentation and/or other materials provided 
//    with the distribution.
//  - Neither the name of Infinite Loop nor the names of its contributors may be used to endorse or 
//    promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ILCannedURLProtocol.h"

NSData *_data;
NSDictionary *_headers;
NSInteger _statusCode;
NSError *_error2;

Answer _answer;

@implementation CannedResponse

- (id)initWithStatusCode:(NSInteger)statusCode headers:(NSDictionary *)headers data:(NSData *)data {
    self = [super init];
    if (self) {
        self.statusCode = statusCode;
        self.headers = headers;
        self.data = data;
    }

    return self;
}

+ (id)responseWithStatusCode:(NSInteger)statusCode headers:(NSDictionary *)headers data:(NSData *)data {
    return [[self alloc] initWithStatusCode:statusCode headers:headers data:data];
}

+ (id)responseWithStatusCode:(NSInteger)statusCode headers:(NSDictionary *)headers {
    return [[self alloc] initWithStatusCode:statusCode headers:headers data:nil];
}

+ (id)responseWithStatusCode:(NSInteger)statusCode {
    return [[self alloc] initWithStatusCode:statusCode headers:nil data:nil];
}

@end


@implementation ILCannedURLProtocol

+ (void)setCannedStatusCode:(NSInteger)statusCode responseData:(NSData *)data headers:(NSDictionary *)headers {
    _data = data;
    _statusCode = statusCode;
    _headers = headers;
    _answer = nil;
}

+(void) setCannedAnswer:(Answer)answer {
    _answer = answer;
}

+ (void) reset {
    _data = nil;
    _statusCode = 0;
    _headers = nil;
    _answer = nil;
    _ILCannedURLProtocol_requestHeaders = nil;
    _ILCannedURLProtocol_request = nil;
}


+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // For now only supporting http GET
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSURLRequest *request = [self request];
    id client = [self client];

    _ILCannedURLProtocol_requestHeaders = [request allHTTPHeaderFields];
    _ILCannedURLProtocol_request = [[NSString alloc] initWithBytes:[[request HTTPBody] bytes] length:[[request HTTPBody] length] encoding:NSUTF8StringEncoding];
    _ILCannedURLProtocol_method = request.HTTPMethod;
    _ILCannedURLProtocol_url = [request.URL absoluteString];

    if (_answer != nil){
        CannedResponse *answer = _answer(request);
        // array of elements: NSNumber * statusCode, NSDictionary *headers, NSData * data
        _statusCode = answer.statusCode;
        _headers = answer.headers;
        _data = answer.data;
    }

    if(_data) {
        // Send the canned data
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                                  statusCode:_statusCode
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:_headers];

        [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [client URLProtocol:self didLoadData:_data];

        [client URLProtocolDidFinishLoading:self];

    } else if(_error2) {
        // Send the canned error
        [client URLProtocol:self didFailWithError:_error2];
    } else {
        // Send the canned data
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                                  statusCode:_statusCode
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:_headers];

        [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];

        [client URLProtocolDidFinishLoading:self];
    }
}


- (void)stopLoading {

}

@end
