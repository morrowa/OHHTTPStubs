//
//  RedirectTests.m
//  OHHTTPStubs
//
//  Created by Andrew Morrow on 4/3/18.
//  Copyright © 2018 AliSoftware. All rights reserved.
//

#import <XCTest/XCTest.h>
@import OHHTTPStubs;

static NSString * const RedirectedURL = @"http://not.a.real.host/redirect_me.txt";
static NSString * const RedirectedBody = @"RedirectedBody";

static NSString * const FinalURL = @"http://some.other.fake.host/final.txt";
static NSString * const FinalBody = @"FinalBody";

@interface RedirectTests : XCTestCase

@end

@implementation RedirectTests

- (void)setUp {
    [super setUp];
    
    // 1. Configure a stub to redirect (302) and return a body.
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.absoluteString isEqualToString:RedirectedURL];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:[RedirectedBody dataUsingEncoding:NSUTF8StringEncoding] statusCode:302 headers:@{@"Content-Type": @"text/plain; charset=utf-8", @"Location": FinalURL}];
    }];
    
    // 2. Configure a second stub to return a body (200).
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.absoluteString isEqualToString:FinalURL];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:[FinalBody dataUsingEncoding:NSUTF8StringEncoding] statusCode:200 headers:@{@"Content-Type": @"text/plain; charset=utf-8"}];
    }];
}

- (void)tearDown {
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (void)testRedirection {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Redirected network request should finish."];
    // 3. Make a request to the first stub.
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:RedirectedURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        XCTAssertEqualObjects(response.URL.absoluteString, FinalURL);
        XCTAssertNil(error);
        NSString *decodedBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects(decodedBody, FinalBody);
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
            XCTAssertEqual(httpResponse.statusCode, 200);
        }
        else {
            XCTFail(@"Response was of class %@ (expected NSHTTPURLResponse)", [response class]);
        }
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

- (void)testRedirection1000Times {
    for (NSUInteger i = 0; i < 1000; i++) {
        [self testRedirection];
    }
}

@end
