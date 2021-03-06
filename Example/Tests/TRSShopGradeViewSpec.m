//
//  TRSShopGradeViewSpec.m
//  Trustbadge
//
//  Created by Gero Herkenrath on 22/06/16.
//

#import "TRSShopGradeView.h"
#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHHTTPStubsResponse+HTTPMessage.h>
#import "TRSNetworkAgent+Trustbadge.h"
#import "NSURL+TRSURLExtensions.h"
#import "TRSErrors.h"
#import "TRSStarsView.h"
#import "TRSTrustbadgeSDKPrivate.h"
#import "NSString+TRSStringOperations.h"

@interface TRSShopGradeView (PrivateTests)

@property (nonatomic, strong) UIView *starPlaceholder;
@property (nonatomic, strong) TRSStarsView *starsView;
@property (nonatomic, strong) UILabel *gradeAsTextLabel;
@property (nonatomic, strong) UILabel *gradeAsNumbersLabel;

@property (nonatomic, strong) NSNumber *gradeNumber;
@property (nonatomic, strong) NSNumber *reviewCount;
@property (nonatomic, copy) NSString *gradeText;
@property (nonatomic, copy) NSString *targetMarketISO3;
@property (nonatomic, copy) NSString *languageISO2;

- (void)setInactiveStarColor:(UIColor *)inactiveStarColor;
- (void)setActiveStarColor:(UIColor *)activeStarColor;
- (CGRect)frameForStars;
- (NSString *)gradeNumberString;

@end


SpecBegin(TRSShopGradeView)

describe(@"TRSShopGradeView", ^{
	
	// mock outgoing traffic!
	__block TRSNetworkAgent *agent;
	__block id networkMock;
	beforeAll(^{
		agent = [[TRSNetworkAgent alloc] init];
		agent.debugMode = YES;
		networkMock = OCMClassMock([TRSNetworkAgent class]);
		OCMStub([networkMock sharedAgent]).andReturn(agent);
	});
	afterAll(^{
		agent = nil;
		networkMock = nil;
	});
	
	describe(@"-initWithFrame:", ^{
		
		it(@"results in a minimum frame for a zero rect", ^{
			TRSShopGradeView *view = [[TRSShopGradeView alloc] initWithFrame:CGRectZero];
			CGRect minFrame = view.frame;
			expect(minFrame.size.width).to.equal(90.0); // defined in sizeThatFits in class
			expect(minFrame.size.height).to.equal(60.0);
		});
		
		it(@"its minimum size has an aspect ratio of 5 to 1", ^{
			TRSShopGradeView *view = [[TRSShopGradeView alloc] initWithFrame:CGRectZero];
			CGRect minFrame = view.frame;
			expect(minFrame.size.width).to.equal(minFrame.size.height * 1.5); // see sizeThatFits in class
		});
	});
	
	describe(@"-encodeWithCoder: and -initWithCoder:", ^{
		
		it(@"properly encodes all properties", ^{
			UIColor *activeC = [UIColor blueColor];
			UIColor *inactiveC = [UIColor greenColor];
			
			TRSShopGradeView *view = [TRSShopGradeView new];
			view.activeStarColor = activeC;
			view.inactiveStarColor = inactiveC;
			view.tsID = @"testID";
			view.apiToken = @"testToken";
			view.debugMode = YES;
			NSMutableData *storage = [NSMutableData new];
			NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:storage];
			[view encodeWithCoder:archiver];
			[archiver finishEncoding];
			view = nil;
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:storage];
			TRSShopGradeView *unpacked = [[TRSShopGradeView alloc] initWithCoder:unarchiver];
			
			expect(unpacked.activeStarColor).to.equal(activeC);
			expect(unpacked.inactiveStarColor).to.equal(inactiveC);
			expect(unpacked.tsID).to.equal(@"testID");
			expect(unpacked.apiToken).to.equal(@"testToken");
			expect(unpacked.debugMode).to.beTruthy();
		});
	});
	
	describe(@"-loadShopGradeWithFailureBlock:", ^{
		
		it(@"calls loadShopGradeWithSuccessBlock:failureBlock:", ^{
			TRSShopGradeView *view = [TRSShopGradeView new];
			id mockedView = OCMPartialMock(view);
			OCMExpect([mockedView loadShopGradeWithSuccessBlock:nil failureBlock:[OCMArg any]]);
			[mockedView loadShopGradeWithFailureBlock:nil];
			OCMVerifyAll(mockedView);
		});
		
		it(@"calls its error block on missing data", ^{
			TRSShopGradeView *view = [TRSShopGradeView new];
			waitUntil(^(DoneCallback done) {
				[view loadShopGradeWithFailureBlock:^(NSError *error) {
					done();
				}];
			});
		});
	});
	
	describe(@"-loadShopGradeWithSuccessBlock:failureBlock:", ^{
		
		context(@"with valid tsid and token", ^{
			
			it(@"has correct internal data", ^{
				// stub http request
				NSString *validTSID = @"999888777666555444333222111000999";
				NSString *validToken = @"notneededatm";
				id myStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
					NSURL *usedInAgent = [NSURL shopGradeAPIURLForTSID:validTSID debug:YES];
					return [request.URL isEqual:usedInAgent];
				} withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
					NSString *pathToFixture = [[NSBundle bundleForClass:[self class]] pathForResource:@"shopGrade" ofType:@"data"];
					NSData *gradeData = [NSData dataWithContentsOfFile:pathToFixture];
					return [OHHTTPStubsResponse responseWithData:gradeData statusCode:200 headers:nil];
				}];
				
				__block TRSShopGradeView *testView = [TRSShopGradeView new];
				testView.debugMode = YES; // very important!
				testView.tsID = validTSID;
				testView.apiToken = validToken;
				waitUntil(^(DoneCallback done) {
					[testView loadShopGradeWithSuccessBlock:^{
						done();
					} failureBlock:nil];
				});
				// see class for this: we have an artificial delay, so we need to wait before checking for changes!
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					expect(testView.gradeNumber).to.beKindOf([NSNumber class]);
					expect(testView.reviewCount).to.beKindOf([NSNumber class]);
					expect(testView.targetMarketISO3).to.beKindOf([NSString class]);
					expect(testView.gradeText).to.beKindOf([NSString class]);
					expect(testView.languageISO2).to.beKindOf([NSString class]);
					// this data is defined in the file shopGrade.data!
					expect(testView.gradeNumber).to.equal(@4.87);
					expect(testView.reviewCount).to.equal(@5);
					expect(testView.targetMarketISO3).to.equal(@"CHE");
					expect(testView.gradeText).to.equal([@"EXCELLENT" readableMarkDescription]);
					expect(testView.languageISO2).to.equal(@"de");
					
					[OHHTTPStubs removeStub:myStub];
				});
			});
		});
		
		// Note regarding the error handling:
		// These tests look ugly, redundant and huge, but they're not...
		// The actual errors are generated by the network agent, but we need to test whether they're correctly propagated
		// in this view. also, due to the way their child stars view is added (with a small delay) I can't put a lot
		// of the redundant code into beforeEach and afterAll blocks, since this might then free my testViews
		// too soon (I need to call the expect() lines in another dispatch_after block).
		// The HTTPStubs need to be set up individually anyways.
		context(@"error handling", ^{
			
			it(@"recognizes an invalid TSID", ^{
				// stub http request
				NSString *invalidTSID = @"12345";
				NSString *validToken = @"notneededatm";
				id myStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
					NSURL *usedInAgent = [NSURL shopGradeAPIURLForTSID:invalidTSID debug:YES];
					return [request.URL isEqual:usedInAgent];
				} withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
					NSString *pathToFixture = [[NSBundle bundleForClass:[self class]] pathForResource:@"shopGrade-badrequest"
																							   ofType:@"response"];
					NSData *gradeData = [NSData dataWithContentsOfFile:pathToFixture];
					return [OHHTTPStubsResponse responseWithHTTPMessageData:gradeData];
				}];
				
				__block TRSShopGradeView *testView = [TRSShopGradeView new];
				testView.debugMode = YES; // very important!
				testView.tsID = invalidTSID;
				testView.apiToken = validToken;
				waitUntil(^(DoneCallback done) {
					[testView loadShopGradeWithSuccessBlock:nil failureBlock:^(NSError *error) {
						expect(error.code).to.equal(TRSErrorDomainInvalidTSID);
						done();
					}];
				});
				// see class for this: we have an artificial delay, so we need to wait before checking for changes!
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					expect(testView.gradeNumber).to.beNil();
					expect(testView.reviewCount).to.beNil();
					expect(testView.targetMarketISO3).to.beNil();
					expect(testView.gradeText).to.beNil();
					expect(testView.languageISO2).to.beNil();
					[OHHTTPStubs removeStub:myStub];
				});
			});
			
			it(@"recognizes an invalid token", ^{
				// stub http request
				NSString *validTSID = @"999888777666555444333222111000999";
				NSString *invalidToken = @"notneededatmbutinvalid";
				// note: There is no token check atm, so this test completely mocks an error instead of using real sampled data
				id myStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
					NSURL *usedInAgent = [NSURL shopGradeAPIURLForTSID:validTSID debug:YES];
					return [request.URL isEqual:usedInAgent];
				} withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
					NSError *badtoken = [NSError errorWithDomain:TRSErrorDomain	code:TRSErrorDomainInvalidAPIToken userInfo:nil];
					return [OHHTTPStubsResponse responseWithError:badtoken];
				}];
				
				__block TRSShopGradeView *testView = [TRSShopGradeView new];
				testView.debugMode = YES; // very important!
				testView.tsID = validTSID;
				testView.apiToken = invalidToken;
				waitUntil(^(DoneCallback done) {
					[testView loadShopGradeWithSuccessBlock:nil failureBlock:^(NSError *error) {
						expect(error.code).to.equal(TRSErrorDomainInvalidAPIToken);
						done();
					}];
				});
				// see class for this: we have an artificial delay, so we need to wait before checking for changes!
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					expect(testView.gradeNumber).to.beNil();
					expect(testView.reviewCount).to.beNil();
					expect(testView.targetMarketISO3).to.beNil();
					expect(testView.gradeText).to.beNil();
					expect(testView.languageISO2).to.beNil();
					[OHHTTPStubs removeStub:myStub];
				});
			});
			
			it(@"recognizes an TSID not found error", ^{
				// stub http request
				NSString *missingTSID = @"000111222333444555666777888999111";
				NSString *validToken = @"notneededatm";
				id myStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
					NSURL *usedInAgent = [NSURL shopGradeAPIURLForTSID:missingTSID debug:YES];
					return [request.URL isEqual:usedInAgent];
				} withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
					NSString *pathToFixture = [[NSBundle bundleForClass:[self class]] pathForResource:@"shopGrade-notfound"
																							   ofType:@"response"];
					NSData *gradeData = [NSData dataWithContentsOfFile:pathToFixture];
					return [OHHTTPStubsResponse responseWithHTTPMessageData:gradeData];
				}];
				
				__block TRSShopGradeView *testView = [TRSShopGradeView new];
				testView.debugMode = YES; // very important!
				testView.tsID = missingTSID;
				testView.apiToken = validToken;
				waitUntil(^(DoneCallback done) {
					[testView loadShopGradeWithSuccessBlock:nil failureBlock:^(NSError *error) {
						expect(error.code).to.equal(TRSErrorDomainTSIDNotFound);
						done();
					}];
				});
				// see class for this: we have an artificial delay, so we need to wait before checking for changes!
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					expect(testView.gradeNumber).to.beNil();
					expect(testView.reviewCount).to.beNil();
					expect(testView.targetMarketISO3).to.beNil();
					expect(testView.gradeText).to.beNil();
					expect(testView.languageISO2).to.beNil();
					[OHHTTPStubs removeStub:myStub];
				});
			});
			
			it(@"handles invalid data", ^{
				// stub http request
				NSString *validTSID = @"999888777666555444333222111000999";
				NSString *validToken = @"notneededatm";
				id myStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
					NSURL *usedInAgent = [NSURL shopGradeAPIURLForTSID:validTSID debug:YES];
					return [request.URL isEqual:usedInAgent];
				} withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
					NSDictionary *wrongJSON = @{@"response" : @{@"code" : @200,
																@"data" : @{@"shop" : @"wrongtype!",
																			@"wrongfield2" : @"useless"}}};
					NSData *asData = [NSJSONSerialization dataWithJSONObject:wrongJSON options:NSJSONWritingPrettyPrinted error:nil];
					NSString *asString = [[NSString alloc] initWithData:asData encoding:NSUTF8StringEncoding];
					return [OHHTTPStubsResponse responseWithData:[asString dataUsingEncoding:NSUTF8StringEncoding]
													  statusCode:200
														 headers:nil];;
				}];
				
				__block TRSShopGradeView *testView = [TRSShopGradeView new];
				testView.debugMode = YES; // very important!
				testView.tsID = validTSID;
				testView.apiToken = validToken;
				waitUntil(^(DoneCallback done) {
					[testView loadShopGradeWithSuccessBlock:nil failureBlock:^(NSError *error) {
						expect(error.code).to.equal(TRSErrorDomainInvalidData);
						done();
					}];
				});
				// see class for this: we have an artificial delay, so we need to wait before checking for changes!
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					expect(testView.gradeNumber).to.beNil();
					expect(testView.reviewCount).to.beNil();
					expect(testView.targetMarketISO3).to.beNil();
					expect(testView.gradeText).to.beNil();
					expect(testView.languageISO2).to.beNil();
					[OHHTTPStubs removeStub:myStub];
				});
			});
			
			it(@"handles an unknown TRSError", ^{
				// stub http request
				NSString *validTSID = @"999888777666555444333222111000999";
				NSString *validToken = @"notneededatm";
				id myStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
					NSURL *usedInAgent = [NSURL shopGradeAPIURLForTSID:validTSID debug:YES];
					return [request.URL isEqual:usedInAgent];
				} withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
					NSData *baddata = [[NSString stringWithFormat:@"not a HTTP status code"] dataUsingEncoding:NSUTF8StringEncoding];
					return [OHHTTPStubsResponse responseWithData:baddata statusCode:460 headers:nil];
				}];
				
				__block TRSShopGradeView *testView = [TRSShopGradeView new];
				testView.debugMode = YES; // very important!
				testView.tsID = validTSID;
				testView.apiToken = validToken;
				waitUntil(^(DoneCallback done) {
					[testView loadShopGradeWithSuccessBlock:nil failureBlock:^(NSError *error) {
						expect(error.code).to.equal(TRSErrorDomainUnknownError);
						done();
					}];
				});
				// see class for this: we have an artificial delay, so we need to wait before checking for changes!
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					expect(testView.gradeNumber).to.beNil();
					expect(testView.reviewCount).to.beNil();
					expect(testView.targetMarketISO3).to.beNil();
					expect(testView.gradeText).to.beNil();
					expect(testView.languageISO2).to.beNil();
					[OHHTTPStubs removeStub:myStub];
				});
			});
			
			it(@"handles an unknown general error", ^{
				// stub http request
				NSString *validTSID = @"999888777666555444333222111000999";
				NSString *validToken = @"notneededatm";
				id myStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
					NSURL *usedInAgent = [NSURL shopGradeAPIURLForTSID:validTSID debug:YES];
					return [request.URL isEqual:usedInAgent];
				} withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
					NSError *weirderror = [NSError errorWithDomain:@"666" code:666 userInfo:nil];
					return [OHHTTPStubsResponse responseWithError:weirderror];
				}];
				
				__block TRSShopGradeView *testView = [TRSShopGradeView new];
				testView.debugMode = YES; // very important!
				testView.tsID = validTSID;
				testView.apiToken = validToken;
				waitUntil(^(DoneCallback done) {
					[testView loadShopGradeWithSuccessBlock:nil failureBlock:^(NSError *error) {
						expect(error.code).to.equal(666);
						done();
					}];
				});
				// see class for this: we have an artificial delay, so we need to wait before checking for changes!
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					expect(testView.gradeNumber).to.beNil();
					expect(testView.reviewCount).to.beNil();
					expect(testView.targetMarketISO3).to.beNil();
					expect(testView.gradeText).to.beNil();
					expect(testView.languageISO2).to.beNil();
					[OHHTTPStubs removeStub:myStub];
				});
			});
		});
	});
	
	context(@"touch handling when stars are not loaded", ^{
		
		__block id mockView;
		__block TRSShopGradeView *testView;
		beforeEach(^{
			testView = [TRSShopGradeView new];
			mockView = OCMPartialMock(testView);
			OCMExpect([mockView starsView]);
		});
		afterEach(^{
			mockView = nil;
			testView = nil;
		});
		
		describe(@"-touchesBegan:withEvent:", ^{
			it(@"checks whether the stars are set", ^{
				[testView touchesBegan:[NSSet new] withEvent:[UIEvent new]];
				OCMVerifyAll(mockView);
			});
		});
		
		describe(@"-touchesMoved:withEvent:", ^{
			it(@"checks whether the stars are set", ^{
				[testView touchesMoved:[NSSet new] withEvent:[UIEvent new]];
				OCMVerifyAll(mockView);
			});
		});
		
		describe(@"-touchesEnded:withEvent:", ^{
			it(@"checks whether the stars are set", ^{
				[testView touchesEnded:[NSSet new] withEvent:[UIEvent new]];
				OCMVerifyAll(mockView);
			});
		});
		
		describe(@"-touchesCancelled:withEvent:", ^{
			it(@"checks whether the stars are set", ^{
				[testView touchesCancelled:[NSSet new] withEvent:[UIEvent new]];
				OCMVerifyAll(mockView);
			});
		});
	});
	
	context(@"touch handling when stars are loaded", ^{
		
		// this method is the only relevant one in this case
		describe(@"-touchesEnded:withEvent:", ^{
			it(@"checks whether the stars are set and tries to open a URL", ^{
				TRSShopGradeView *testView = [TRSShopGradeView new];
				testView.debugMode = YES;
				
				// simply give the view a fake starsView instead of actually loading
				TRSStarsView *fakeStars = [[TRSStarsView alloc] initWithRating:@5];
				testView.starsView = fakeStars;
				
				id mockApp = OCMPartialMock([UIApplication sharedApplication]);
				id mockURL = OCMClassMock([NSURL class]);
				OCMStub([mockURL profileURLForTSID:[OCMArg any] countryCode:[OCMArg any] language:[OCMArg any]]).andReturn(nil);
				OCMExpect([mockApp openURL:[OCMArg any]]);
				[testView touchesEnded:[NSSet new] withEvent:[UIEvent new]];
				OCMVerify([mockApp openURL:[OCMArg any]]);
			});
		});
	});
	
	describe(@"-setActiveColor: and -setInactiveColor:", ^{
		it(@"checks for starsView on color change", ^{
			TRSShopGradeView *testView = [TRSShopGradeView new];
			testView.debugMode = YES;
			
			// give the testView a starsView without actually loading
			TRSStarsView *fakeStars = [[TRSStarsView alloc] initWithRating:@5];
			
			UIColor *defaultActive = testView.activeStarColor;
			UIColor *defaultInactive = testView.inactiveStarColor;
			id starsMock = OCMPartialMock(fakeStars);
			testView.starsView = starsMock;
			OCMExpect([starsMock setInactiveStarColor:[OCMArg any]]);
			OCMExpect([starsMock setActiveStarColor:[OCMArg any]]);
			[testView setActiveStarColor:[UIColor blueColor]];
			[testView setInactiveStarColor:[UIColor greenColor]];
			
			expect(testView.activeStarColor).toNot.equal(defaultActive);
			expect(testView.inactiveStarColor).toNot.equal(defaultInactive);
			expect(testView.activeStarColor).to.equal([UIColor blueColor]);
			expect(testView.inactiveStarColor).to.equal([UIColor greenColor]);
			
			OCMVerifyAll(starsMock);
		});
	});
	
	describe(@"-sizeThatFits:", ^{
		it(@"won't return a smaller width than its stars placeholder view", ^{
			// note: The other eventualities are covered by the other tests indirectly
			TRSShopGradeView *view = [TRSShopGradeView new];
			view.debugMode = YES;
			// I cheat here to check this:
			view.starPlaceholder.bounds = CGRectMake(0.0, 0.0, 125.0, 25.0);
			CGSize testSize = CGSizeMake(10.0, 60.0);
			testSize = [view sizeThatFits:testSize];
			expect(testSize.width).to.equal(view.starPlaceholder.bounds.size.width);
		});
	});
	
	// note: I know this is not supposed to be called directly, but this is just a test
	// I might rework this in the future and embedd the view in a real view hierarchy, but for now this is enough.
	describe(@"-layoutSubviews", ^{
		it(@"adapts the stars frame", ^{
			TRSShopGradeView *testView = [TRSShopGradeView new];
			testView.debugMode = YES;
			[testView sizeToFit];
			TRSStarsView *fakeStars = [[TRSStarsView alloc] initWithRating:@5];
			id starsMock = OCMPartialMock(fakeStars);
			testView.starsView = starsMock;
			testView.gradeText = @"Test";
			testView.gradeNumber = @4.67;
			OCMExpect([starsMock setFrame:testView.starPlaceholder.bounds]);
			[testView layoutSubviews];
			OCMVerifyAll(starsMock);
		});
	});
	
	describe(@"-gradeNumberString", ^{
		it(@"returns a nicely formatted string for the reviewCount", ^{
			TRSShopGradeView *view = [TRSShopGradeView new];
			view.debugMode = YES;
			view.gradeNumber = @4.78;
			NSString *result = [view gradeNumberString];
			expect(result).to.equal(@"4.78/5.00"); // basically just the separator...
		});
	});
});

SpecEnd
