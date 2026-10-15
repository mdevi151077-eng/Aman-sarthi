# Aman Sarthi AI

One Flutter codebase builds the Android app and web app. The study dashboard,
notes, practice screens, photo picker, and chat UI live in `lib/`; the chat
calls a Flutter service backed by an Express API using Google's official
`@google/genai` SDK.

## Current AI setup and privacy

`AI_API_BASE_URL` is a Flutter compile-time setting, not an Android runtime
setting. It defaults to the verified Render service
`https://aman-sarthi.onrender.com`; set `--dart-define=AI_API_BASE_URL=...` to
override it for another backend. Changing this default or the define affects
new builds, not already-installed APKs. The URL must be the public HTTPS base
URL (not `/api/chat` itself). The app appends `/api/chat` and uses `/readyz`
for its **Test AI connection** action.

The Render health endpoint `/health` and readiness endpoint `/readyz` were
verified at `https://aman-sarthi.onrender.com`. `/readyz` confirms that the
backend sees its Gemini configuration; it does not prove that a real generation
will succeed. Create the API key in Google AI Studio and set `GEMINI_API_KEY`
in Render's Environment settings as a secret. Never put it in Flutter, a
`--dart-define`, the APK, or this repository.

For Android releases, the preflight script checks HTTPS, backend readiness, and
one real Gemini streamed answer before compiling. This makes a small live
Gemini request and will stop if the key or model is invalid. The script
defaults to the verified Render URL; set `AI_API_BASE_URL` only to override it.
Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release_android.ps1
```

The script stops unless the backend returns a real Gemini response.
`AI_API_BASE_URL` is an address, not a secret. The policy override applies
only to that process and does not change the machine's persistent setting.
Chat turns are sent to
your configured backend, which forwards them to Gemini. Google may process
submitted message content under its own terms and retention policy. Up to 20
conversations (50 text messages each) are saved on this device using local
preferences; this storage is not encrypted or synced.
Photos can be selected and previewed, but are not uploaded or understood by the
current text-only chat flow. No end-to-end encryption is claimed.

With no backend URL, the app shows a configuration message when a text prompt
is sent; it does not silently switch to local Ollama or a fake model.

## Private practice tests

The Practice Tests screen supports manually authored multiple-choice tests and
validated JSON imports with up to 100 questions per test. Each question can
include 2–8 options, a zero-based `answerIndex`, explanation, difficulty,
marks, and negative marks. A test can include course, subject, chapter, and a
duration in minutes (`0` means untimed). For example:

```json
{
  "title": "My chapter test",
  "course": "Class 10",
  "subject": "Maths",
  "chapter": "Algebra",
  "durationMinutes": 30,
  "questions": [
    {
      "prompt": "Question text",
      "options": ["First", "Second"],
      "answerIndex": 1,
      "explanation": "Solution text",
      "difficulty": "Medium",
      "marks": 1,
      "negativeMarks": 0.25
    }
  ]
}
```

Questions, answer keys, in-progress answers, and attempt results are stored in
the device's app preferences. This is a private practice tool, not secure
publishing: answer keys are not protected from the device owner, attempts are
not server-verified, and content does not sync across devices. No Firebase
project, Firebase Auth/Firestore/Storage integration, or trusted admin service
is configured in this repository. Do not use this local question bank to
publish paid or confidential exams.

## Backend: local Windows setup

Requirements: Node.js 20 or later. The backend uses Express and Google's
official GenAI SDK.

In `backend/.env`, replace `GEMINI_API_KEY` with a key created in Google AI
Studio. `GEMINI_MODEL` defaults to `gemini-flash-latest`; change it only to a
model available to your key. `.env` and `.env.*` are excluded by the root
`.gitignore`; `.env.example` is the safe template. The key is read only by the
Node process and is never sent to Flutter.

```powershell
cd backend
Copy-Item .env.example .env
notepad .env
npm.cmd ci
node --env-file=.env server.mjs
```

In another terminal, check readiness and run backend tests:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
Invoke-RestMethod http://127.0.0.1:8080/readyz
npm.cmd test
curl.exe -N -H "Content-Type: application/json" --data-raw '{"messages":[{"role":"user","content":"Reply with READY."}]}' http://127.0.0.1:8080/api/chat
```

`/readyz` confirms the key is present, not that Gemini accepts it. The real
chat smoke test above verifies key access, model access, and generated output.
The API
validates message roles, lengths, and conversation size; streams actual Gemini
output; uses Helmet, CORS allowlisting, and per-IP rate limiting; and does not
log chat content, provider errors, or keys. The limiter uses in-memory state,
so public multi-instance deployments need shared rate limiting and
authentication before broad release.

### Android emulator

Use the host-loopback alias from the Android emulator. Run Flutter in debug
mode so local HTTP is permitted:

```powershell
flutter run -d <emulator-id> --dart-define=AI_API_BASE_URL=http://10.0.2.2:8080
```

### Physical Android phone

Connect the phone and computer to the same trusted Wi-Fi. Run `ipconfig` on the
computer and use its Wi-Fi IPv4 address, for example `192.168.1.20` below;
replace that example with the actual address. Keep `HOST=0.0.0.0` in
`backend/.env`, and allow Node.js or inbound TCP port 8080 on the Windows
Private network firewall profile if prompted. Do not add a router port-forward.

```powershell
flutter run -d <phone-id> --dart-define=AI_API_BASE_URL=http://192.168.1.20:8080
```

Private-LAN HTTP URLs are accepted only in Flutter debug builds. Release APKs
must use a deployed HTTPS backend URL.

## Backend deployment

Deploy the Node service to a trusted Node 20+ host with HTTPS. For example,
Cloud Run can build from the `backend` source directory. Configure secrets in
Google Secret Manager and grant the Cloud Run service identity permission to
read them; do not place keys in a shell command, image, repository, or build
argument.

### Render Free (testing and hobby use)

The root `render.yaml` defines a Node web service using the `backend` directory,
the existing start command, and `/health` health checks. Create a Render
account, connect a Git repository containing this project, and create a service
from the Blueprint. Set `GEMINI_API_KEY` in the service's Environment settings
as a secret; do not add it to the repository. Render shows the actual HTTPS
service URL after deployment.

Render Free services spin down after 15 minutes without inbound traffic and
can take about a minute to wake. Free service limits and availability can
change; review Render's current terms before choosing a plan. Do not select a
paid plan without approval.

Configure these server environment variables:

- `NODE_ENV=production`
- `HOST=0.0.0.0` (required by container hosts such as Cloud Run; local default
  is also `0.0.0.0`)
- `GEMINI_MODEL=gemini-flash-latest` (or another model available to your key)
- `GEMINI_API_KEY` from Google AI Studio, stored as a Render secret
- `CORS_ORIGINS=https://amansarthi-175ef.web.app` for the configured Firebase
  Hosting origin; add any custom web domains as exact comma-separated origins
- `RATE_LIMIT_WINDOW_MS` and `RATE_LIMIT_MAX_REQUESTS` as appropriate

The host must bind the supplied `PORT`, allow outbound HTTPS to Google,
set `HOST=0.0.0.0` when required by its container network, and terminate
inbound TLS. Check `/health` for process liveness and `/readyz` for backend
configuration. `/healthz` remains available as a compatibility alias.
Gemini requests have a 90-second timeout. For Flutter Web, set `CORS_ORIGINS`
to the exact deployed origin; the configured Firebase Hosting origin is shown
above. The live API currently rejects the web origin until this Render
environment setting is applied. CORS is not authentication. The backend
currently has no user authentication, and its rate limiter is in-memory, so
do not treat it as production abuse protection for a public service.
Deployment has not been performed from this workspace; no Gemini key or
deployment credentials are available here.

To override the default, set `AI_API_BASE_URL` to another HTTPS base URL without
adding `/api/chat`, then build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release_android.ps1
flutter build appbundle --release "--dart-define=AI_API_BASE_URL=$env:AI_API_BASE_URL"
flutter build web --dart-define="AI_API_BASE_URL=$env:AI_API_BASE_URL"
```

The chat screen's network icon runs the backend `/readyz` check. To verify the
credential and model before release, use the real chat smoke test or send a
prompt from the app. The APK preflight performs one real request before
building.

For web development, run the local backend on port 8080, set
`CORS_ORIGINS=http://127.0.0.1:8081`, then start Flutter:

```powershell
flutter run -d edge --web-port 8081 --dart-define=AI_API_BASE_URL=http://127.0.0.1:8080
```

HTTP backend URLs are accepted only in debug builds for loopback, the emulator
host alias, or RFC1918 private IPv4 addresses; release builds require HTTPS.

## Optional direct Ollama development mode

Direct Flutter-to-Ollama mode is allowed only in debug builds. The Android
emulator uses `10.0.2.2`; web and desktop use loopback. It is not suitable for
a released Android app or a physical phone, and web requests need Ollama CORS
configuration.

```powershell
flutter run -d edge --dart-define=AI_PROVIDER=ollama
flutter run -d <android-emulator-id> --dart-define=AI_PROVIDER=ollama
```

The model remains `llama3.2:1b` in this mode. It is text-only.

## Android build and installation

The Android application ID is `com.amansarthi.ai`; change it to an identifier
you own before publishing if this namespace is not yours. A change to the
application ID also means Android treats the app as a different installed app.

```powershell
flutter pub get
flutter analyze
flutter test
powershell -ExecutionPolicy Bypass -File .\scripts\build_release_android.ps1
flutter build appbundle --release "--dart-define=AI_API_BASE_URL=$env:AI_API_BASE_URL"
```

The APK is written to
`build\app\outputs\flutter-apk\app-release.apk`; transfer it to an Android
phone and open it to install (allow installation from that file source when
Android asks). For Play Store distribution use a private release keystore and
the matching signing configuration, verify app ownership, complete the Play
Console privacy/data-safety and content declarations, and upload the AAB.
Never publish an APK signed with the current debug signing configuration.
Private APK sharing and Google Play publishing are separate release paths.

## Android Dart-code updates

This project does not currently have an OTA updater configured. Shorebird is
the supported option for shipping compatible Dart-code patches to an installed
Android app; it does not remove the need for a Play Store/APK release when
native Android code, permissions, Flutter engine, or plugin binaries change.
Shorebird also requires your account and the app ID created by its one-time
project registration, so no Shorebird configuration or release is fabricated
in this project.

After creating/logging in to your Shorebird account, install its CLI and run
`shorebird init` from the project root. Keep the generated `shorebird.yaml`
and app ID in the project. Then use:

```powershell
shorebird release android
shorebird patch android
```

The initial Shorebird release must be installed/distributed as an Android
release first. Subsequent patches can update supported Dart changes without
reinstalling the APK. Backend-only fixes do not require an app update.

## Web build and existing Firebase Hosting

```powershell
flutter build web --dart-define="AI_API_BASE_URL=$env:AI_API_BASE_URL"
```

`firebase.json` already points Hosting at `build/web`, and `.firebaserc`
references a Firebase project. This does not prove that the account has deploy
permission or that the backend is deployed. If authorized and logged in with
Firebase CLI, deploy the built web assets with `firebase deploy --only hosting`.

## Tests and known limitations

Backend tests run with `node --test backend/server.test.mjs`. Flutter checks
run with `flutter analyze` and `flutter test`. The Flutter client streams text
and supports a debug-only direct Ollama option. Online AI requires a deployed,
configured HTTPS backend and a valid provider account/model. Photo selection
does not currently mean photo understanding. Release signing and production
authentication/shared rate limiting still require owner configuration.
