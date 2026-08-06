# Android Cleartext Traffic Block

## Problem
`java.io.IOException: Cleartext HTTP traffic to 127.0.0.1 not permitted`

When `just_audio` receives custom `headers` in `AudioSource.uri()`, it spins up
a local HTTP proxy on `127.0.0.1` and routes audio through it. Android 9+ blocks
cleartext (non-HTTPS) traffic by default, so ExoPlayer cannot reach the proxy.

## Fix
Add `android:usesCleartextTraffic="true"` to `<application>` in
`android/app/src/main/AndroidManifest.xml`.

## Why this is safe
The cleartext traffic only happens on localhost between ExoPlayer and the
just_audio proxy. All external requests to YouTube still use HTTPS.

## Lesson
Any Flutter audio plugin that proxies streams locally will hit this on modern
Android. Always enable cleartext if the plugin docs mention a local proxy or if
you pass HTTP headers to the audio source.
