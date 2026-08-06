import { WebPlugin } from '@capacitor/core';

import type { JioPayCapacitorJsPlugin, JioPayHostedCheckoutResult, JioPayOpenHostedCheckoutOptions } from './definitions';

export class JioPayCapacitorJsWeb extends WebPlugin implements JioPayCapacitorJsPlugin {
  async openHostedCheckout(options: JioPayOpenHostedCheckoutOptions): Promise<JioPayHostedCheckoutResult> {
    window.location.assign(options.checkoutUrl);
    return { url: options.checkoutUrl, params: {} };
  }
}
