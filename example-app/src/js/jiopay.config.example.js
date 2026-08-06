// Copy this file to jiopay.config.js (gitignored) and fill in a real
// checkoutUrl. jiopay.config.js is never committed.
export const jioPayConfig = {
  // Your backend must call JioPay's initiateSale API and give you this
  // redirectURI — the plugin never calls initiateSale itself.
  checkoutUrl: '',
  // The same returnURL your backend passed to initiateSale.
  returnUrlPrefix: '',
};
