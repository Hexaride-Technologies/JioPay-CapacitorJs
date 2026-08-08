import { WebPlugin } from '@capacitor/core';

import type { JioPayCapacitorJsPlugin, JioPayHostedCheckoutResult, JioPayOpenHostedCheckoutOptions } from './definitions';

export class JioPayCapacitorJsWeb extends WebPlugin implements JioPayCapacitorJsPlugin {
  async openHostedCheckout(options: JioPayOpenHostedCheckoutOptions): Promise<JioPayHostedCheckoutResult> {
    if (!/^https?:\/\//i.test(options.checkoutUrl)) {
      throw new Error('Invalid checkoutUrl: must be an http(s) URL');
    }
    window.location.assign(options.checkoutUrl);
    return { url: options.checkoutUrl, params: {} };
  }
}
