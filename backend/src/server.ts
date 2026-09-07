import express from 'express';
import { env } from './config/env';
import { createApp } from './app';

const app = createApp();

void express;
module.exports = app;

if (!process.env.VERCEL) {
  app.listen(Number(env.PORT), () => {
    console.log(`GlowCheck API running on port ${env.PORT}`);
  });
}
