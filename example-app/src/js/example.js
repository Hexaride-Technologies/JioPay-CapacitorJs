import { JioPayCapacitorJs } from 'jiopay-capacitorjs';
import { jioPayConfig } from './jiopay.config.js';

function showResult(message) {
  document.getElementById('result').textContent = message;
}

window.payNow = async () => {
  try {
    const result = await JioPayCapacitorJs.startPayment({
      environment: 'UAT',
      aggregatorId: jioPayConfig.aggregatorId,
      merchantId: jioPayConfig.merchantId,
      secret: jioPayConfig.secret,
      amount: document.getElementById('amount').value,
      customerName: 'Test Customer',
      customerEmailId: 'test@jiopay.in',
      merchantName: 'JioPay Capacitor Example',
      merchantImage: jioPayConfig.merchantImage,
      merchantTxnNo: `TEST${Date.now()}`,
      paymentModesAllowed: ['CARD', 'NB', 'UPI'],
    });
    showResult(`Payment status: ${result.status}\n${result.rawJsonResponse}`);
  } catch (err) {
    showResult(`Payment failed: ${err.message}`);
  }
};

window.payViaHostedCheckout = async () => {
  try {
    await JioPayCapacitorJs.openHostedCheckout({ checkoutUrl: jioPayConfig.checkoutUrl });
    showResult('Hosted checkout opened. Check your backend for the S2S webhook result.');
  } catch (err) {
    showResult(`Failed to open hosted checkout: ${err.message}`);
  }
};
