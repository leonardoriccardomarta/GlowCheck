# GlowCheck

Photograph a skincare INCI list. Get a compatibility score vs the skin profile you set, plus a cheaper swap from the formula. Any brand. Not medical advice.

## Local

```powershell
cd backend
cp .env.example .env
npm install
npm run dev
```

```powershell
cd glowcheck
flutter pub get
flutter run -d web-server --release --web-hostname 0.0.0.0 --web-port 5175 --dart-define=API_URL=http://127.0.0.1:4000
```

Open http://127.0.0.1:5175

Keys stay in `backend/.env` (`GROQ_API_KEY`). Never commit that file.

## Vercel

Two projects on this repo:

1. **API** — Root Directory `backend`. Env: `GROQ_API_KEY`, `AUTH_JWT_SECRET`, `FRONTEND_ORIGIN` (the app URL).
2. **App** — Root Directory `glowcheck`. Env: `API_URL` (the API URL). Optional: `GOOGLE_CLIENT_ID`, `APPLE_SERVICE_ID`, `STRIPE_CHECKOUT_URL`.

Hobby functions timeout is short. If a scan dies mid-read, raise the API project to Pro.
