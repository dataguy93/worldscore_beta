# Tournament Registration Deep Link Configuration

Registration links are generated as:

- `https://<your-domain>/tournaments/{tournamentId}/register`

## Flutter runtime domain config

Set `REGISTRATION_BASE_URL` at build time so links use your production domain:

```bash
flutter build web --dart-define=REGISTRATION_BASE_URL=https://your-domain.com
```

## Android App Links stub

`android/app/src/main/AndroidManifest.xml` contains an intent filter stub with `example.com`.
Replace it with your production host.

You must also host an `assetlinks.json` file at:

- `https://<your-domain>/.well-known/assetlinks.json`

## iOS Universal Links stub

Add the Associated Domains capability and include:

- `applinks:your-domain.com`

Host an Apple App Site Association file at:

- `https://<your-domain>/.well-known/apple-app-site-association`

## Web fallback

Ensure your web host rewrites `/tournaments/*/register` to Flutter's `index.html`.
If app links cannot be opened natively, the same URL still loads the registration flow in web.
