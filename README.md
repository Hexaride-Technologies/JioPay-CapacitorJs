# jiopay-capacitorjs

Capacitorjs wrapper for JioPay. Currently supports Android (iOS is not implemented yet).

Two ways to take a payment:

- **`startPayment()`** — launches JioPay's native in-app UI (Card/UPI/Net Banking) via the
  JioPay Java SDK and resolves with the final result. Android/iOS only (throws
  `unavailable` on web).
- **`openHostedCheckout()`** — opens JioPay's browser-hosted checkout page for a `checkoutUrl`
  your own backend already obtained from JioPay's `initiateSale` API. Works on Web, Android,
  and iOS. Useful as a fallback while native SDK integration is still being set up, since it
  has no native dependency. It only launches the page and resolves — it does **not** return a
  final payment status. Per JioPay's own docs, the browser-redirect path is UX-only; your
  backend's S2S webhook (configured on the JioPay merchant dashboard) is the source of truth
  for the actual transaction result.

### Android setup: the JioPay SDK AAR

The native `startPayment()` flow depends on JioPay's proprietary `jio_payments_sdk.aar`,
which is licensed per-merchant and is **not published to Maven or bundled with this package**.
Before building an app that uses `startPayment()`:

1. Obtain `jio_payments_sdk.aar` from JioPay for your merchant account.
2. Place it at `android/libs/jio_payments_sdk.aar` in this plugin's source (see
   `android/libs/README.md`). If you only need `openHostedCheckout()`, this step isn't required.

`openHostedCheckout()` has no such dependency and works out of the box.

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

* [`startPayment(...)`](#startpayment)
* [`openHostedCheckout(...)`](#openhostedcheckout)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### startPayment(...)

```typescript
startPayment(options: JioPayStartPaymentOptions) => Promise<JioPayPaymentResult>
```

Launches JioPay's native in-app payment UI (Card/UPI/Net Banking) and
resolves with the final payment result. Rejects if the user cancels or
the SDK reports a failure. Android/iOS only.

| Param         | Type                                                                            |
| ------------- | ------------------------------------------------------------------------------- |
| **`options`** | <code><a href="#jiopaystartpaymentoptions">JioPayStartPaymentOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#jiopaypaymentresult">JioPayPaymentResult</a>&gt;</code>

--------------------


### openHostedCheckout(...)

```typescript
openHostedCheckout(options: JioPayOpenHostedCheckoutOptions) => Promise<void>
```

Opens JioPay's Hosted Checkout page for a `checkoutUrl` your backend
already obtained from JioPay's `initiateSale` API. Resolves as soon as
the page has been launched — it does NOT return a final payment status.
Use this as a secondary path (e.g. while native SDK integration isn't
ready yet). Your backend's S2S webhook remains the source of truth for
the actual transaction result. Available on Web, Android, and iOS.

| Param         | Type                                                                                        |
| ------------- | ------------------------------------------------------------------------------------------- |
| **`options`** | <code><a href="#jiopayopenhostedcheckoutoptions">JioPayOpenHostedCheckoutOptions</a></code> |

--------------------


### Interfaces


#### JioPayPaymentResult

| Prop                  | Type                | Description                                          |
| --------------------- | ------------------- | ---------------------------------------------------- |
| **`status`**          | <code>string</code> |                                                      |
| **`rawJsonResponse`** | <code>string</code> | Raw JSON response string returned by the JioPay SDK. |


#### JioPayStartPaymentOptions

| Prop                      | Type                                                            | Description                                                            |
| ------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------- |
| **`environment`**         | <code><a href="#jiopayenvironment">JioPayEnvironment</a></code> |                                                                        |
| **`aggregatorId`**        | <code>string</code>                                             |                                                                        |
| **`merchantId`**          | <code>string</code>                                             |                                                                        |
| **`secret`**              | <code>string</code>                                             | Merchant secret key, used by the native SDK for hash-based validation. |
| **`amount`**              | <code>string</code>                                             | Transaction amount, e.g. "100.00".                                     |
| **`customerName`**        | <code>string</code>                                             |                                                                        |
| **`customerEmailId`**     | <code>string</code>                                             |                                                                        |
| **`merchantName`**        | <code>string</code>                                             |                                                                        |
| **`merchantImage`**       | <code>string</code>                                             | URL of the merchant logo shown on the payment UI.                      |
| **`merchantTxnNo`**       | <code>string</code>                                             | Unique merchant transaction number for this payment attempt.           |
| **`timeout`**             | <code>number</code>                                             | Payment timeout in seconds.                                            |
| **`paymentModesAllowed`** | <code>JioPayPaymentMode[]</code>                                |                                                                        |


#### JioPayOpenHostedCheckoutOptions

| Prop              | Type                | Description                                                                                                                                                                                                 |
| ----------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`checkoutUrl`** | <code>string</code> | The `redirectURI` your backend obtained by calling JioPay's `initiateSale` API. Must be produced server-side — never compute the request's `secureHash` (which requires your Secret Key) in app/browser JS. |


### Type Aliases


#### JioPayEnvironment

`UAT` targets JioPay's test environment (https://uat.jiopay.co.in), `PRODUCTION`
targets the live environment. Verified against the JioPay Java SDK's actual
constants once the AAR is available for inspection.

<code>'UAT' | 'PRODUCTION'</code>


#### JioPayPaymentMode

Payment methods the checkout UI is allowed to offer — matches the SDK's `PaymentMode` enum.

<code>'CARD' | 'CARD_CC' | 'CARD_DC' | 'NB' | 'UPI' | 'UPI_QR' | 'UPI_INTENT' | 'UPI_VPA' | 'PLUXEE' | 'PAYTM' | 'AMAZON' | 'GOOGLE_PAY' | 'PHONE_PE' | 'BHIM' | 'CRED' | 'TRUECALLER_PAY'</code>

</docgen-api>
