# GlowCheck (Flutter)

Same UI as the Fitness template you picked: Poppins, lilac gradients, pager onboarding, center camera button. Product is INCI scan vs your skin, talking to the existing `backend/` on port 4000.

Flutter is not on this PC yet. Install the SDK, then run this folder — do not keep polishing the Expo `mobile/` app.

## Once

1. Install Flutter: https://docs.flutter.dev/get-started/install/windows
2. `flutter doctor`
3. In this folder: `flutter pub get`

## Run

Terminal 1:

```powershell
cd backend
npm run dev
```

Terminal 2 (emulator):

```powershell
cd glowcheck
flutter pub get
flutter run
```

Physical phone: same Wi-Fi as the PC, then:

```powershell
flutter run --dart-define=API_URL=http://YOUR_LAN_IP:4000
```

## Flow

Start → 4 pager slides → skin type + spend → goal carousel → home. Pink camera button or Scan INCI tab → photo of the ingredient list → score screen.

First successful read is free. Not medical advice.
