# jiopay-capacitorjs

Capacitorjs wrapper for JioPay's Hosted Checkout. Works on Web and Android (iOS not implemented yet).

The plugin has a single method, **`openHostedCheckout()`**: it opens JioPay's browser-hosted
checkout page for a `checkoutUrl` your own backend already obtained from JioPay's `initiateSale`
API. It has no native SDK dependency — no proprietary `.aar` to source or wire into your build.

- **Android**: loads the page in an embedded WebView. Any non-http(s) navigation (e.g.
  `upi://pay?...`) is handed off via an `ACTION_VIEW` Intent, so installed UPI apps still get
  invoked the way they would in a real browser. The Promise resolves once the page navigates to
  a URL starting with `returnUrlPrefix` (the same `returnURL` your backend passed to
  `initiateSale`), with that URL and its parsed query params — closing the checkout screen
  without reaching it (back button, swipe-away, etc.) instead rejects the Promise.
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

On Android, this loads the page in an embedded WebView. Any non-http(s)
navigation (e.g. `upi://pay?...`) is handed off via an Android
`ACTION_VIEW` Intent so installed UPI apps still get invoked the way
they would in a real browser. The Promise resolves once the page
navigates to a URL starting with `returnUrlPrefix` — whether the user
gets there normally or backs/swipes out beforehand, the checkout screen
closing without reaching that URL instead rejects the Promise.

On Web, it's a full-page redirect (`window.location.assign`), which
unloads the current page immediately — there is no separate "closed"
signal there, so `returnUrlPrefix` is ignored and the returned Promise
resolves right away with empty `params`.

| Param         | Type                                                                                        |
| ------------- | ------------------------------------------------------------------------------------------- |
| **`options`** | <code><a href="#jiopayopenhostedcheckoutoptions">JioPayOpenHostedCheckoutOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#jiopayhostedcheckoutresult">JioPayHostedCheckoutResult</a>&gt;</code>

--------------------


### Interfaces


#### JioPayHostedCheckoutResult

| Prop         | Type                                                            | Description                                                                                                                                                                                                                                                                                        |
| ------------ | --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`url`**    | <code>string</code>                                             | The full URL the checkout page redirected to once it matched `returnUrlPrefix`.                                                                                                                                                                                                                    |
| **`params`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> | Parsed query parameters from that URL — JioPay's B2B callback fields (e.g. `responseCode`, `merchantTxnNo`, `txnID`). Per JioPay's own docs this browser-redirect path is UX-only and not authoritative; your backend's S2S webhook remains the source of truth for the actual transaction result. |


#### JioPayOpenHostedCheckoutOptions

| Prop                  | Type                | Description                                                                                                                                                                                                                                                                                                                                                                                                                               |
| --------------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`checkoutUrl`**     | <code>string</code> | The `redirectURI` your backend obtained by calling JioPay's `initiateSale` API. Must be produced server-side — never compute the request's `secureHash` (which requires your Secret Key) in app/browser JS.                                                                                                                                                                                                                               |
| **`returnUrlPrefix`** | <code>string</code> | The same `returnURL` your backend passed to JioPay's `initiateSale` API. On Android, once the checkout page navigates to a URL starting with this prefix, the native checkout screen closes and the Promise resolves with that URL and its parsed query params. Ignored on Web, where the page just does a full redirect and there's no separate "closed" step to detect — your returnURL page itself must read `window.location.search`. |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>
