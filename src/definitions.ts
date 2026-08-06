/**
 * `UAT` targets JioPay's test environment (https://uat.jiopay.co.in), `PRODUCTION`
 * targets the live environment. Verified against the JioPay Java SDK's actual
 * constants once the AAR is available for inspection.
 */
export type JioPayEnvironment = 'UAT' | 'PRODUCTION';

/** Payment methods the checkout UI is allowed to offer — matches the SDK's `PaymentMode` enum. */
export type JioPayPaymentMode =
  | 'CARD'
  | 'CARD_CC'
  | 'CARD_DC'
  | 'NB'
  | 'UPI'
  | 'UPI_QR'
  | 'UPI_INTENT'
  | 'UPI_VPA'
  | 'PLUXEE'
  | 'PAYTM'
  | 'AMAZON'
  | 'GOOGLE_PAY'
  | 'PHONE_PE'
  | 'BHIM'
  | 'CRED'
  | 'TRUECALLER_PAY';

export interface JioPayStartPaymentOptions {
  environment: JioPayEnvironment;
  aggregatorId: string;
  merchantId: string;
  /** Merchant secret key, used by the native SDK for hash-based validation. */
  secret: string;
  /** Transaction amount, e.g. "100.00". */
  amount: string;
  customerName: string;
  customerEmailId: string;
  merchantName: string;
  /** URL of the merchant logo shown on the payment UI. */
  merchantImage?: string;
  /** Unique merchant transaction number for this payment attempt. */
  merchantTxnNo: string;
  /** Payment timeout in seconds. */
  timeout?: number;
  paymentModesAllowed: JioPayPaymentMode[];
}

export interface JioPayPaymentResult {
  status: string;
  /** Raw JSON response string returned by the JioPay SDK. */
  rawJsonResponse: string;
}

export interface JioPayOpenHostedCheckoutOptions {
  /**
   * The `redirectURI` your backend obtained by calling JioPay's `initiateSale`
   * API. Must be produced server-side — never compute the request's
   * `secureHash` (which requires your Secret Key) in app/browser JS.
   */
  checkoutUrl: string;
}

export interface JioPayCapacitorJsPlugin {
  /**
   * Launches JioPay's native in-app payment UI (Card/UPI/Net Banking) and
   * resolves with the final payment result. Rejects if the user cancels or
   * the SDK reports a failure. Android/iOS only.
   */
  startPayment(options: JioPayStartPaymentOptions): Promise<JioPayPaymentResult>;

  /**
   * Opens JioPay's Hosted Checkout page for a `checkoutUrl` your backend
   * already obtained from JioPay's `initiateSale` API. Resolves as soon as
   * the page has been launched — it does NOT return a final payment status.
   * Use this as a secondary path (e.g. while native SDK integration isn't
   * ready yet). Your backend's S2S webhook remains the source of truth for
   * the actual transaction result. Available on Web, Android, and iOS.
   */
  openHostedCheckout(options: JioPayOpenHostedCheckoutOptions): Promise<void>;
}
