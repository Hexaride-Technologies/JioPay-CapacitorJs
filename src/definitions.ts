export interface JioPayOpenHostedCheckoutOptions {
  /**
   * The `redirectURI` your backend obtained by calling JioPay's `initiateSale`
   * API. Must be produced server-side — never compute the request's
   * `secureHash` (which requires your Secret Key) in app/browser JS.
   */
  checkoutUrl: string;
  /**
   * The same `returnURL` your backend passed to JioPay's `initiateSale` API.
   * On Android/iOS, once the checkout page navigates to a URL starting with
   * this prefix, the native checkout screen closes and the Promise resolves
   * with that URL and its parsed query params. Ignored on Web, where the
   * page just does a full redirect and there's no separate "closed" step to
   * detect — your returnURL page itself must read `window.location.search`.
   */
  returnUrlPrefix: string;
}

export interface JioPayHostedCheckoutResult {
  /** The full URL the checkout page redirected to once it matched `returnUrlPrefix`. */
  url: string;
  /**
   * Parsed query parameters from that URL — JioPay's B2B callback fields
   * (e.g. `responseCode`, `merchantTxnNo`, `txnID`). Per JioPay's own docs
   * this browser-redirect path is UX-only and not authoritative; your
   * backend's S2S webhook remains the source of truth for the actual
   * transaction result.
   */
  params: Record<string, string>;
}

export interface JioPayCapacitorJsPlugin {
  /**
   * Opens JioPay's Hosted Checkout page for a `checkoutUrl` your backend
   * already obtained from JioPay's `initiateSale` API.
   *
   * On Android/iOS, this loads the page in an embedded WebView (`WebView` /
   * `WKWebView`). Any non-http(s) navigation (e.g. `upi://pay?...`) is
   * handed off via an `ACTION_VIEW` Intent (Android) or `UIApplication.open`
   * (iOS) so installed UPI apps still get invoked the way they would in a
   * real browser. The Promise resolves once the page navigates to a URL
   * starting with `returnUrlPrefix` — whether the user gets there normally
   * or backs/swipes out beforehand, the checkout screen closing without
   * reaching that URL instead rejects the Promise.
   *
   * On Web, it's a full-page redirect (`window.location.assign`), which
   * unloads the current page immediately — there is no separate "closed"
   * signal there, so `returnUrlPrefix` is ignored and the returned Promise
   * resolves right away with empty `params`.
   */
  openHostedCheckout(options: JioPayOpenHostedCheckoutOptions): Promise<JioPayHostedCheckoutResult>;
}
