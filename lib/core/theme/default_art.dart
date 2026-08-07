// Animated GIF placeholders from https://www.svgator.com/svg-to-gif
import 'package:flutter/material.dart';

class DefaultArtEntry {
  final String asset;
  final Color bg;
  const DefaultArtEntry(this.asset, this.bg);
}

class DefaultArt {
  DefaultArt._();

  static const _entries = [
    DefaultArtEntry('assets/default_art/ping-pong.gif', Color(0xFF622944)),
    DefaultArtEntry('assets/default_art/basketball.gif', Color(0xFFFFDBA7)),
    DefaultArtEntry('assets/default_art/frenchie.gif', Color(0xFF020917)),
    DefaultArtEntry('assets/default_art/bird.gif', Color(0xFFFFFFFF)),
    DefaultArtEntry('assets/default_art/cloud.gif', Color(0xFF323680)),
    DefaultArtEntry('assets/default_art/hamburger.gif', Color(0xFF000000)),
    DefaultArtEntry('assets/default_art/cat-loader.gif', Color(0xFF5BA7FF)),
    DefaultArtEntry('assets/default_art/emoji-set.gif', Color(0xFF000000)),
    DefaultArtEntry('assets/default_art/cactus.webp', Color(0xFFFFFFFF)),
    DefaultArtEntry('assets/default_art/star.gif', Color(0xFF6357AC)),
    DefaultArtEntry('assets/default_art/chat-hearts.gif', Color(0xFF000000)),
    DefaultArtEntry('assets/default_art/lego.gif', Color(0xFF6357AC)),
  ];

  static DefaultArtEntry forId(String id) {
    return _entries[id.hashCode.abs() % _entries.length];
  }

  static Widget image(String id, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final entry = forId(id);
    return Container(
      width: width,
      height: height,
      color: entry.bg,
      child: Image.asset(
        entry.asset,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
