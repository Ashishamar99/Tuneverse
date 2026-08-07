# Amazon Music Link Formats

## Problem
Amazon Music track links pasted by users didn't resolve — the app fell through to a raw YouTube search of the entire URL, returning irrelevant results.

## Root Cause
The link parser only handled three Amazon Music URL patterns:

| Pattern | Example |
|---------|---------|
| Album with track param | `music.amazon.com/albums/B0X.../B0Y...?trackAsin=B0Z...` |
| Album page | `music.amazon.com/albums/B0X...` |
| Playlist page | `music.amazon.com/playlists/B0X...` |

The most common share format — **direct track URLs** — was missing:
```
music.amazon.com/tracks/B0DJLMYSNR
```

## Fix
Added a fourth regex for `/tracks/ASIN` and inserted it in the parse chain before the album pattern (since `/albums/` and `/tracks/` are distinct paths).

## Amazon Music URL Reference (2026)
- **Track (direct)**: `music.amazon.com/tracks/{ASIN}` — most common share format
- **Track (in album)**: `music.amazon.com/albums/{albumASIN}?trackAsin={trackASIN}`
- **Album**: `music.amazon.com/albums/{ASIN}`
- **Playlist**: `music.amazon.com/playlists/{ASIN}`
- **Artist**: `music.amazon.com/artists/{ASIN}` (not yet supported)

Country TLDs vary: `.com`, `.co.uk`, `.co.jp`, `.in`, etc. — all handled by `[a-z.]+` in the regex.
