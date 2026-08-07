enum MusicPlatform { spotify, amazonMusic, youtubeMusic, youtube, unknown }
enum LinkType { track, album, playlist, unknown }

class ParsedLink {
  final MusicPlatform platform;
  final LinkType type;
  final String id;
  final String originalUrl;

  const ParsedLink({
    required this.platform,
    required this.type,
    required this.id,
    required this.originalUrl,
  });
}

class LinkParser {
  static final _spotifyTrack = RegExp(
    r'open\.spotify\.com/track/([a-zA-Z0-9]+)',
  );
  static final _spotifyAlbum = RegExp(
    r'open\.spotify\.com/album/([a-zA-Z0-9]+)',
  );
  static final _spotifyPlaylist = RegExp(
    r'open\.spotify\.com/playlist/([a-zA-Z0-9]+)',
  );
  static final _spotifyUri = RegExp(
    r'spotify:(track|album|playlist):([a-zA-Z0-9]+)',
  );

  static final _amazonTrack = RegExp(
    r'music\.amazon\.[a-z.]+/albums/([A-Z0-9]+)\?trackAsin=([A-Z0-9]+)',
  );
  static final _amazonDirectTrack = RegExp(
    r'music\.amazon\.[a-z.]+/tracks/([A-Z0-9]+)',
  );
  static final _amazonAlbum = RegExp(
    r'music\.amazon\.[a-z.]+/albums/([A-Z0-9]+)',
  );
  static final _amazonPlaylist = RegExp(
    r'music\.amazon\.[a-z.]+/playlists/([A-Z0-9]+)',
  );

  static final _ytMusicWatch = RegExp(
    r'music\.youtube\.com/watch\?v=([a-zA-Z0-9_-]+)',
  );
  static final _ytMusicPlaylist = RegExp(
    r'music\.youtube\.com/playlist\?list=([a-zA-Z0-9_-]+)',
  );
  static final _youtubeWatch = RegExp(
    r'(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]+)',
  );
  static final _youtubePlaylist = RegExp(
    r'youtube\.com/playlist\?list=([a-zA-Z0-9_-]+)',
  );

  static ParsedLink? parse(String url) {
    // Spotify URI scheme
    final uriMatch = _spotifyUri.firstMatch(url);
    if (uriMatch != null) {
      final typeStr = uriMatch.group(1)!;
      return ParsedLink(
        platform: MusicPlatform.spotify,
        type: _parseLinkType(typeStr),
        id: uriMatch.group(2)!,
        originalUrl: url,
      );
    }

    // Spotify web links
    var match = _spotifyTrack.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.spotify,
        type: LinkType.track,
        id: match.group(1)!,
        originalUrl: url,
      );
    }
    match = _spotifyPlaylist.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.spotify,
        type: LinkType.playlist,
        id: match.group(1)!,
        originalUrl: url,
      );
    }
    match = _spotifyAlbum.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.spotify,
        type: LinkType.album,
        id: match.group(1)!,
        originalUrl: url,
      );
    }

    // Amazon Music
    match = _amazonTrack.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.amazonMusic,
        type: LinkType.track,
        id: '${match.group(1)}:${match.group(2)}',
        originalUrl: url,
      );
    }
    match = _amazonDirectTrack.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.amazonMusic,
        type: LinkType.track,
        id: match.group(1)!,
        originalUrl: url,
      );
    }
    match = _amazonPlaylist.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.amazonMusic,
        type: LinkType.playlist,
        id: match.group(1)!,
        originalUrl: url,
      );
    }
    match = _amazonAlbum.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.amazonMusic,
        type: LinkType.album,
        id: match.group(1)!,
        originalUrl: url,
      );
    }

    // YouTube Music
    match = _ytMusicWatch.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.youtubeMusic,
        type: LinkType.track,
        id: match.group(1)!,
        originalUrl: url,
      );
    }
    match = _ytMusicPlaylist.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.youtubeMusic,
        type: LinkType.playlist,
        id: match.group(1)!,
        originalUrl: url,
      );
    }

    // Regular YouTube
    match = _youtubeWatch.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.youtube,
        type: LinkType.track,
        id: match.group(1)!,
        originalUrl: url,
      );
    }
    match = _youtubePlaylist.firstMatch(url);
    if (match != null) {
      return ParsedLink(
        platform: MusicPlatform.youtube,
        type: LinkType.playlist,
        id: match.group(1)!,
        originalUrl: url,
      );
    }

    return null;
  }

  static LinkType _parseLinkType(String type) {
    switch (type) {
      case 'track':
        return LinkType.track;
      case 'album':
        return LinkType.album;
      case 'playlist':
        return LinkType.playlist;
      default:
        return LinkType.unknown;
    }
  }
}
