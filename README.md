# PMS Pro Flutter client

The client talks to the Express API mounted at `/api`. Start `backend-node` with
its `.env` file and matching `PORT` before signing in.

## API configuration

The default development URLs are `http://127.0.0.1:3005/api` for desktop and
web, and `http://10.0.2.2:3005/api` for an Android emulator. Override the API
for staging or production at build time:

```text
flutter run --dart-define=API_BASE_URL=https://staging.example.com/api
flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api
```

Use the host machine's LAN address instead of `10.0.2.2` for a physical Android
device. iOS Simulator can use `127.0.0.1` when the backend runs on the Mac.

The backend currently has no refresh endpoint. The client stores the issued
refresh token for session completeness but does not send it anywhere; an expired
access token requires signing in again. Finance uses the server's actual mounts:
invoices are under `/api/invoices` and payments under `/api/finance/payments`.

Unsupported capabilities such as M-Pesa STK, vendor authentication, upload
fields on maintenance requests, and tenant search remain disabled until the
backend exposes contracts for them.
