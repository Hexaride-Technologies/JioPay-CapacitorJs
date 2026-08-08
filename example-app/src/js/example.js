import { JioPayCapacitorJs } from 'jiopay-capacitorjs';
import { jioPayConfig } from './jiopay.config.js';

function showResult(message) {
  document.getElementById('result').textContent = message;
}

JioPayCapacitorJs.addListener('success', (event) => {
  console.log('[JioPay] success', event);
});

JioPayCapacitorJs.addListener('fail', (event) => {
  console.log('[JioPay] fail', event);
});

JioPayCapacitorJs.addListener('cancelled', (event) => {
  console.log('[JioPay] cancelled', event);
});

JioPayCapacitorJs.addListener('complete', (event) => {
  console.log('[JioPay] complete', event);
});

window.payViaHostedCheckout = async () => {
  try {
    const checkoutUrl = document.getElementById('checkoutUrl').value;
    const result = await JioPayCapacitorJs.openHostedCheckout({
      checkoutUrl: checkoutUrl,
      returnUrlPrefix: jioPayConfig.returnUrlPrefix,
    });
    showResult(`Landed on: ${result.url}\nParams: ${JSON.stringify(result.params)}`);
  } catch (err) {
    showResult(`Failed to open hosted checkout: ${err.message}`);
  }
};
