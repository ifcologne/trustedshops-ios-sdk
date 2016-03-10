#import <Foundation/Foundation.h>

/**
 *  @c TRSNetworkAgent is used to handle network requests.
 */
@interface TRSNetworkAgent : NSObject

/**
 *  The base URL for the agent.
 */
@property (nonatomic, readonly, copy) NSURL *baseURL;

/**
 * @name Creating an Agent
 */

/**
 *  Creates and returns a singleton instance of @c TRSNetworkAgent.
 *
 *  @return A @c TRSNetworkAgent singleton
 */
+ (instancetype)sharedAgent;

/**
 *  Initializes an `TRSNetworkAgent` with the specified base URL.
 *
 *  @param baseURL The base URL for the agent
 *
 *  @return An initialized agent
 */
- (instancetype)initWithBaseURL:(NSURL *)baseURL;

/**
 * @name Making HTTP Requests
 */

// This method is deprecated and will no longer be called.
// - (NSURLSessionDataTask *)GET:(NSString *)path success:(void (^)(NSData *data))success failure:(void (^)(NSData *data, NSHTTPURLResponse *response, NSError *error))failure;

/**
 *	Creates and runs an @c NSURLSesseionDataTaks with a @c GET request and returns the task.
 *
 *	@param path    The path of the URL
 *	@param success A block object which will be executed when request finishes successfully. The block has a data argument.
 *	@param failure A block object which will be executed when request finishes successfully. 
 *						The block has a data, a response, and an error argument.
 *
 *	@return Initialized @c NSURLSessionDataTaks object or @c nil if the @c authToken is missing (i.e. also  <tt>nil</tt>).
 */
- (NSURLSessionDataTask *)GET:(NSString *)path
					authToken:(NSString *)token
					  success:(void (^)(NSData *data))success
					  failure:(void (^)(NSData *data, NSHTTPURLResponse *response, NSError *error))failure;

@end
