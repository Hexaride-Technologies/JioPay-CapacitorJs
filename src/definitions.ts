import type { PluginListenerHandle } from '@capacitor/core';

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
  /**
   * Android only. Shows an app bar with a Close button above the checkout
   * WebView. Defaults to `false` — the system back button/gesture already
   * shows the same "Cancel payment?" confirmation, so this is opt-in for
   * apps that want a visible affordance too. Ignored on iOS, which always
   * shows this bar (there's no OS-level back gesture there to fall back on
   * — the checkout screen is presented `.fullScreen` specifically to
   * prevent an accidental swipe-to-dismiss mid-payment, so the bar's Close
   * button is the only way to leave). Ignored on Web.
   */
  showAppBar?: boolean;
  /**
   * Hex color (e.g. `"#F9A000"`) used to tint the status bar (and the app
   * bar, when `showAppBar` is `true`) so the native chrome matches the
   * checkout page's own branding. Defaults to JioPay's own brand orange.
   * Status-bar icon contrast (light/dark) is chosen automatically based on
   * this color. Android/iOS only — has no effect on Web.
   */
  headerColor?: string;
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

export interface JioPayCheckoutEvent {
  /**
   * `'success'`/`'fail'` mean the checkout page actually reached
   * `returnUrlPrefix` with a gateway response. `'cancelled'` means the
   * checkout screen closed before that ever happened (e.g. the user
   * backed/swiped out) — no gateway response was received, so unlike
   * `'fail'` there's typically nothing to reconcile with your backend.
   */
  status: 'success' | 'fail' | 'cancelled';
  /** Present for `success`/`fail` — the URL that matched `returnUrlPrefix`. Absent for `cancelled`. */
  url?: string;
  /** Present for `success`/`fail` — parsed query params from that URL. Absent for `cancelled`. */
  params?: Record<string, string>;
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
   * real browser. Trying to close the checkout screen before reaching
   * `returnUrlPrefix` (back button, swipe-away, etc.) shows a "Cancel
   * payment?" confirmation dialog first — only actually closing (and
   * rejecting the Promise) once the user confirms. See the `success`/`fail`/
   * `cancelled`/`complete` listeners below for a status-aware alternative to
   * awaiting this Promise directly.
   *
   * On Web, it's a full-page redirect (`window.location.assign`), which
   * unloads the current page immediately — there is no separate "closed"
   * signal there, so `returnUrlPrefix` is ignored and the returned Promise
   * resolves right away with empty `params`. No `success`/`fail`/`cancelled`/
   * `complete` events fire on Web for the same reason.
   */
  openHostedCheckout(options: JioPayOpenHostedCheckoutOptions): Promise<JioPayHostedCheckoutResult>;

  /**
   * Fired on Android/iOS when the checkout page reaches `returnUrlPrefix`
   * with a `responseCode` of `"0000"`.
   */
  addListener(eventName: 'success', listenerFunc: (event: JioPayCheckoutEvent) => void): Promise<PluginListenerHandle>;

  /**
   * Fired on Android/iOS when the checkout page reaches `returnUrlPrefix`
   * with a non-success `responseCode` — an actual gateway response, just
   * not a successful one.
   */
  addListener(eventName: 'fail', listenerFunc: (event: JioPayCheckoutEvent) => void): Promise<PluginListenerHandle>;

  /**
   * Fired on Android/iOS when the checkout screen closes before ever
   * reaching `returnUrlPrefix` (e.g. the user backed/swiped out, or
   * confirmed "Leave" on the "Cancel payment?" dialog). No gateway response
   * was received, so there's typically nothing to check with your backend
   * for this case — unlike `fail`.
   */
  addListener(eventName: 'cancelled', listenerFunc: (event: JioPayCheckoutEvent) => void): Promise<PluginListenerHandle>;

  /**
   * Fired on Android/iOS after every checkout attempt — always paired with
   * a `success`, `fail`, or `cancelled` event carrying the same data.
   */
  addListener(eventName: 'complete', listenerFunc: (event: JioPayCheckoutEvent) => void): Promise<PluginListenerHandle>;

  /** Removes all listeners registered on this plugin. */
  removeAllListeners(): Promise<void>;
}
