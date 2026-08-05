import { WebPlugin } from '@capacitor/core';

import type { JioPayCapacitorJsPlugin } from './definitions';

export class JioPayCapacitorJsWeb extends WebPlugin implements JioPayCapacitorJsPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
