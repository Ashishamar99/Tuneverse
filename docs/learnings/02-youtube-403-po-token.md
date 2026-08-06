# YouTube 403 — PO Token Requirement

## Problem
ExoPlayer gets HTTP 403 when downloading audio streams from YouTube, even though
the stream URL was obtained successfully.

## Root Cause
`youtube_explode_dart` <=2.x uses the `android` API client by default, which
includes `androidSdkVersion: 30` in its payload. YouTube now requires a PO
(Proof of Origin) Token for requests from clients that declare an SDK version.
Audio-only streams are gated behind this check.

The stream URL is returned successfully (YouTube's player endpoint doesn't reject
the request), but when ExoPlayer actually tries to download audio data from the
URL, YouTube's CDN returns 403.

## Fix
Update `youtube_explode_dart` to `^3.1.0`. Version 3.x defaults `getManifest()`
to `YoutubeApiClient.androidSdkless`, which is identical to the `android` client
but **omits** `androidSdkVersion`. This bypasses the PO Token gate.

```yaml
# pubspec.yaml
youtube_explode_dart: ^3.1.0  # was ^2.3.4
```

No code changes needed — `getManifest()` defaults to `androidSdkless`.

## What Didn't Work
- Adding Chrome browser User-Agent headers: creates a client-type mismatch
  (URL says `c=ANDROID` but headers claim to be Chrome)
- Removing headers entirely: doesn't help because the root issue is the API
  client type used when *requesting* the stream URL, not the headers used when
  *downloading* it

## Related
- PR #371 in youtube_explode_dart: added `androidSdkless` client
- yt-dlp uses the same approach (`android_sdkless` extractor)
- YouTube is migrating to SABR protocol; `androidSdkless` is a stopgap
