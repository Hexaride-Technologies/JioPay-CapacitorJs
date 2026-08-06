// Copy this file to jiopay.config.js (gitignored) and fill in your own
// UAT test credentials. jiopay.config.js is never committed.
export const jioPayConfig = {
  // Used by the native startPayment() flow.
  aggregatorId: '',
  merchantId: '',
  secret: '',
  // URL of the merchant logo shown on the payment UI — required by the SDK.
  merchantImage: '',

  // Used by the openHostedCheckout() flow. Your own backend must call
  // JioPay's initiateSale API and give you this redirectURI — the plugin
  // never computes the secureHash itself. Paste a fresh one here for testing.
  checkoutUrl: '',
};
