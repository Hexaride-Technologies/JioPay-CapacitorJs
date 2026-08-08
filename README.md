# jiopay-capacitorjs

Capacitorjs wrapper for JioPay's Hosted Checkout. Works on Web, Android, and iOS.

The plugin has a single method, **`openHostedCheckout()`**: it opens JioPay's browser-hosted
checkout page for a `checkoutUrl` your own backend already obtained from JioPay's `initiateSale`
API. It has no native SDK dependency — no proprietary `.aar` to source or wire into your build.

- **Android/iOS**: loads the page in an embedded WebView (`WebView` on Android, `WKWebView` on
  iOS). Any non-http(s) navigation (e.g. `upi://pay?...`) is handed off via an `ACTION_VIEW`
  Intent (Android) / `UIApplication.open` (iOS), so installed UPI apps still get invoked the way
  they would in a real browser. The Promise resolves once the page navigates to a URL starting
  with `returnUrlPrefix` (the same `returnURL` your backend passed to `initiateSale`), with that
  URL and its parsed query params. Trying to close the checkout screen before reaching it (back
  button, swipe-away, etc.) shows a "Cancel payment?" confirmation dialog first — only actually
  closing (and rejecting the Promise) once the user confirms.
  - Android also accepts `showAppBar` (default `false`): an optional app bar with a Back/Close
    button, in addition to the always-available system back button/gesture. iOS always shows
    this bar (there's no OS back gesture to fall back on there — the screen is presented
    full-screen specifically to prevent an accidental swipe-dismiss mid-payment).
- **Web**: a plain full-page redirect (`window.location.assign`), which unloads the current page
  immediately — there's no separate "closed" step to detect there, so `returnUrlPrefix` is
  ignored and the Promise resolves right away with empty `params`.

It does **not** return a final payment status even when it resolves — per JioPay's own docs, the
browser-redirect path is UX-only; your backend's S2S webhook (configured on the JioPay merchant
dashboard) is the source of truth for the actual transaction result. Your backend must call
`initiateSale` itself and hand this plugin the resulting `checkoutUrl` — the `secureHash` that
call requires (computed from your Secret Key) must never be computed in app/browser JS.

## Install

To use npm

```bash
npm install jiopay-capacitorjs
````

To use yarn

```bash
yarn add jiopay-capacitorjs
```

Sync native files

```bash
npx cap sync
```

## API

<docgen-index>

* [`openHostedCheckout(...)`](#openhostedcheckout)
* [`addListener('success', ...)`](#addlistenersuccess-)
* [`addListener('fail', ...)`](#addlistenerfail-)
* [`addListener('cancelled', ...)`](#addlistenercancelled-)
* [`addListener('complete', ...)`](#addlistenercomplete-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### openHostedCheckout(...)

```typescript
openHostedCheckout(options: JioPayOpenHostedCheckoutOptions) => Promise<JioPayHostedCheckoutResult>
```

Opens JioPay's Hosted Checkout page for a `checkoutUrl` your backend
already obtained from JioPay's `initiateSale` API.

On Android/iOS, this loads the page in an embedded WebView (`WebView` /
`WKWebView`). Any non-http(s) navigation (e.g. `upi://pay?...`) is
handed off via an `ACTION_VIEW` Intent (Android) or `UIApplication.open`
(iOS) so installed UPI apps still get invoked the way they would in a
real browser. Trying to close the checkout screen before reaching
`returnUrlPrefix` (back button, swipe-away, etc.) shows a "Cancel
payment?" confirmation dialog first — only actually closing (and
rejecting the Promise) once the user confirms. See the `success`/`fail`/
`cancelled`/`complete` listeners below for a status-aware alternative to
awaiting this Promise directly.

On Web, it's a full-page redirect (`window.location.assign`), which
unloads the current page immediately — there is no separate "closed"
signal there, so `returnUrlPrefix` is ignored and the returned Promise
resolves right away with empty `params`. No `success`/`fail`/`cancelled`/
`complete` events fire on Web for the same reason.

| Param         | Type                                                                                        |
| ------------- | ------------------------------------------------------------------------------------------- |
| **`options`** | <code><a href="#jiopayopenhostedcheckoutoptions">JioPayOpenHostedCheckoutOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#jiopayhostedcheckoutresult">JioPayHostedCheckoutResult</a>&gt;</code>

--------------------


### addListener('success', ...)

```typescript
addListener(eventName: 'success', listenerFunc: (event: JioPayCheckoutEvent) => void) => Promise<PluginListenerHandle>
```

Fired on Android/iOS when the checkout page reaches `returnUrlPrefix`
with a `responseCode` of `"0000"`.

| Param              | Type                                                                                    |
| ------------------ | --------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'success'</code>                                                                  |
| **`listenerFunc`** | <code>(event: <a href="#jiopaycheckoutevent">JioPayCheckoutEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('fail', ...)

```typescript
addListener(eventName: 'fail', listenerFunc: (event: JioPayCheckoutEvent) => void) => Promise<PluginListenerHandle>
```

Fired on Android/iOS when the checkout page reaches `returnUrlPrefix`
with a non-success `responseCode` — an actual gateway response, just
not a successful one.

| Param              | Type                                                                                    |
| ------------------ | --------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'fail'</code>                                                                     |
| **`listenerFunc`** | <code>(event: <a href="#jiopaycheckoutevent">JioPayCheckoutEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('cancelled', ...)

```typescript
addListener(eventName: 'cancelled', listenerFunc: (event: JioPayCheckoutEvent) => void) => Promise<PluginListenerHandle>
```

Fired on Android/iOS when the checkout screen closes before ever
reaching `returnUrlPrefix` (e.g. the user backed/swiped out, or
confirmed "Leave" on the "Cancel payment?" dialog). No gateway response
was received, so there's typically nothing to check with your backend
for this case — unlike `fail`.

| Param              | Type                                                                                    |
| ------------------ | --------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'cancelled'</code>                                                                |
| **`listenerFunc`** | <code>(event: <a href="#jiopaycheckoutevent">JioPayCheckoutEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('complete', ...)

```typescript
addListener(eventName: 'complete', listenerFunc: (event: JioPayCheckoutEvent) => void) => Promise<PluginListenerHandle>
```

Fired on Android/iOS after every checkout attempt — always paired with
a `success`, `fail`, or `cancelled` event carrying the same data.

| Param              | Type                                                                                    |
| ------------------ | --------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'complete'</code>                                                                 |
| **`listenerFunc`** | <code>(event: <a href="#jiopaycheckoutevent">JioPayCheckoutEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

Removes all listeners registered on this plugin.

--------------------


### Interfaces


#### JioPayHostedCheckoutResult

| Prop         | Type                                                            | Description                                                                                                                                                                                                                                                                                        |
| ------------ | --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`url`**    | <code>string</code>                                             | The full URL the checkout page redirected to once it matched `returnUrlPrefix`.                                                                                                                                                                                                                    |
| **`params`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Parsed query parameters from that URL — JioPay's B2B callback fields (e.g. `responseCode`, `merchantTxnNo`, `txnID`). Per JioPay's own docs this browser-redirect path is UX-only and not authoritative; your backend's S2S webhook remains the source of truth for the actual transaction result. |


#### JioPayOpenHostedCheckoutOptions

| Prop                  | Type                 | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| --------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`checkoutUrl`**     | <code>string</code>  | The `redirectURI` your backend obtained by calling JioPay's `initiateSale` API. Must be produced server-side — never compute the request's `secureHash` (which requires your Secret Key) in app/browser JS.                                                                                                                                                                                                                                                                                                                                             |
| **`returnUrlPrefix`** | <code>string</code>  | The same `returnURL` your backend passed to JioPay's `initiateSale` API. On Android/iOS, once the checkout page navigates to a URL starting with this prefix, the native checkout screen closes and the Promise resolves with that URL and its parsed query params. Ignored on Web, where the page just does a full redirect and there's no separate "closed" step to detect — your returnURL page itself must read `window.location.search`.                                                                                                           |
| **`showAppBar`**      | <code>boolean</code> | Android only. Shows an app bar with a Close button above the checkout WebView. Defaults to `false` — the system back button/gesture already shows the same "Cancel payment?" confirmation, so this is opt-in for apps that want a visible affordance too. Ignored on iOS, which always shows this bar (there's no OS-level back gesture there to fall back on — the checkout screen is presented `.fullScreen` specifically to prevent an accidental swipe-to-dismiss mid-payment, so the bar's Close button is the only way to leave). Ignored on Web. |
| **`headerColor`**     | <code>string</code>  | Hex color (e.g. `"#F9A000"`) used to tint the status bar (and the app bar, when `showAppBar` is `true`) so the native chrome matches the checkout page's own branding. Defaults to JioPay's own brand orange. Status-bar icon contrast (light/dark) is chosen automatically based on this color. Android/iOS only — has no effect on Web.                                                                                                                                                                                                               |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### JioPayCheckoutEvent

| Prop         | Type                                                            | Description                                                                                                                                                                                                                                                                                                                         |
| ------------ | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`status`** | <code>'success' \| 'fail' \| 'cancelled'</code>                 | `'success'`/`'fail'` mean the checkout page actually reached `returnUrlPrefix` with a gateway response. `'cancelled'` means the checkout screen closed before that ever happened (e.g. the user backed/swiped out) — no gateway response was received, so unlike `'fail'` there's typically nothing to reconcile with your backend. |
| **`url`**    | <code>string</code>                                             | Present for `success`/`fail` — the URL that matched `returnUrlPrefix`. Absent for `cancelled`.                                                                                                                                                                                                                                      |
| **`params`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Present for `success`/`fail` — parsed query params from that URL. Absent for `cancelled`.                                                                                                                                                                                                                                           |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>
