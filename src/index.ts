import { registerPlugin } from '@capacitor/core';

import type { JioPayCapacitorJsPlugin } from './definitions';

const JioPayCapacitorJs = registerPlugin<JioPayCapacitorJsPlugin>('JioPayCapacitorJs', {
  web: () => import('./web').then((m) => new m.JioPayCapacitorJsWeb()),
});

export * from './definitions';
export { JioPayCapacitorJs };
