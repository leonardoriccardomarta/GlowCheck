import type { IncomingMessage, ServerResponse } from 'http';
import { createApp } from '../src/app';

export const maxDuration = 60;

const app = createApp();

export default function handler(req: IncomingMessage, res: ServerResponse) {
  return app(req, res);
}
