import { WebPlugin } from '@capacitor/core';

import type {
  JioPayCapacitorJsPlugin,
  JioPayOpenHostedCheckoutOptions,
  JioPayPaymentResult,
  JioPayStartPaymentOptions,
} from './definitions';

export class JioPayCapacitorJsWeb extends WebPlugin implements JioPayCapacitorJsPlugin {
  async startPayment(_options: JioPayStartPaymentOptions): Promise<JioPayPaymentResult> {
    throw this.unavailable('JioPay native payments are only supported on Android/iOS. Use openHostedCheckout() on web.');
  }

  async openHostedCheckout(options: JioPayOpenHostedCheckoutOptions): Promise<void> {
    window.location.assign(options.checkoutUrl);
  }
}
