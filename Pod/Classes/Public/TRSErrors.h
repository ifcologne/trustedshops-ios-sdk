#import <Foundation/Foundation.h>

/**
 The custom error domain used by the Trustbadge SDK.
 */

FOUNDATION_EXPORT NSString * const TRSErrorDomain;

/**	
 The type for error codes that are used in the Trustbadge SDK.
 */
typedef NS_ENUM(NSUInteger, TRSErrorCode) {
	/** An unknown error in the cintext of the Trustbadge SDK */
    TRSErrorDomainUnknownError = 1000,
	/** The provided Trusted Shops shop ID was rejected as invalid by the API. */
    TRSErrorDomainInvalidTSID,
	/** The provided Trusted Shops shop ID does not exist in the Trusted Shop database. */
    TRSErrorDomainTSIDNotFound,
	/** The data returned for the trustbadge is corrupted or has an unknown format */
    TRSErrorDomainInvalidData,
	/** The client token for the API is not valid. Currently this cannot happen, as no token is needed. */
	TRSErrorDomainInvalidAPIToken,
	/** The TRSTrustbadgeView instance was set up without a Trusted Shops shop ID or without any client token (or both). */
	TRSErrorDomainMissingTSIDOrAPIToken,
	/** A product grade view was set up without an SKU. */
	TRSErrorDomainMissingSKU,
	/** The processOrder:onCompletion: method could not find a root view controller to present its popup */
	TRSErrorDomainProcessOrderNeedsRootViewController,
	/** The TRSCheckoutViewController did not finish processing the last call of processOrder:onCompletion: yet.
	 Only one order can be processed at a time. */
	TRSErrorDomainProcessOrderLastOrderNotFinished,
	/** The TRSOrder object passed to processOrder:onCompletion: is invalid or corrupted */
	TRSErrorDomainProcessOrderInvalidData
};
