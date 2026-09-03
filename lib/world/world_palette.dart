import 'dart:ui';

/// Colour set for one time of day. The renderer blends between these as the
/// run progresses, giving a day → dusk → night → dawn cycle.
class WorldPalette {
  const WorldPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.horizonGlow,
    required this.sun,
    required this.mountainFar,
    required this.mountainNear,
    required this.grassLight,
    required this.grassDark,
    required this.roadLight,
    required this.roadDark,
    required this.rumbleLight,
    required this.rumbleDark,
    required this.laneLine,
    required this.fog,
    required this.starAlpha,
    required this.headlightAlpha,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color horizonGlow;
  final Color sun;
  final Color mountainFar;
  final Color mountainNear;
  final Color grassLight;
  final Color grassDark;
  final Color roadLight;
  final Color roadDark;
  final Color rumbleLight;
  final Color rumbleDark;
  final Color laneLine;
  final Color fog;
  final double starAlpha;
  final double headlightAlpha;

  static const day = WorldPalette(
    skyTop: Color(0xFF1E6FD9),
    skyBottom: Color(0xFF9DD5FF),
    horizonGlow: Color(0x66FFFFFF),
    sun: Color(0xFFFFF4C2),
    mountainFar: Color(0xFF6F93C4),
    mountainNear: Color(0xFF3F6A8E),
    grassLight: Color(0xFF3E9E3F),
    grassDark: Color(0xFF32873A),
    roadLight: Color(0xFF6B6B70),
    roadDark: Color(0xFF616166),
    rumbleLight: Color(0xFFF2F2F2),
    rumbleDark: Color(0xFFD83B3B),
    laneLine: Color(0xFFF5F5F5),
    fog: Color(0xFF9DD5FF),
    starAlpha: 0,
    headlightAlpha: 0,
  );

  static const dusk = WorldPalette(
    skyTop: Color(0xFF2B1B5E),
    skyBottom: Color(0xFFFF8C4B),
    horizonGlow: Color(0x99FFC46B),
    sun: Color(0xFFFF6B3D),
    mountainFar: Color(0xFF5B3A6E),
    mountainNear: Color(0xFF34213F),
    grassLight: Color(0xFF3A6A3A),
    grassDark: Color(0xFF2E5A32),
    roadLight: Color(0xFF55525C),
    roadDark: Color(0xFF4B4853),
    rumbleLight: Color(0xFFE7D9CF),
    rumbleDark: Color(0xFFB53434),
    laneLine: Color(0xFFF0E4D0),
    fog: Color(0xFFCB7A57),
    starAlpha: 0.25,
    headlightAlpha: 0.5,
  );

  static const night = WorldPalette(
    skyTop: Color(0xFF05071A),
    skyBottom: Color(0xFF1B2450),
    horizonGlow: Color(0x33889CFF),
    sun: Color(0xFFE6ECFF),
    mountainFar: Color(0xFF1A2140),
    mountainNear: Color(0xFF0E1330),
    grassLight: Color(0xFF15361F),
    grassDark: Color(0xFF112C1A),
    roadLight: Color(0xFF2E2F3A),
    roadDark: Color(0xFF282933),
    rumbleLight: Color(0xFFB8BCCB),
    rumbleDark: Color(0xFF7A2B2B),
    laneLine: Color(0xFFD5D8E6),
    fog: Color(0xFF141A3A),
    starAlpha: 1,
    headlightAlpha: 1,
  );

  static const dawn = WorldPalette(
    skyTop: Color(0xFF3B4A8C),
    skyBottom: Color(0xFFFFB78A),
    horizonGlow: Color(0x88FFD9A8),
    sun: Color(0xFFFFD27F),
    mountainFar: Color(0xFF7A6C9E),
    mountainNear: Color(0xFF4C3F6A),
    grassLight: Color(0xFF3B8A45),
    grassDark: Color(0xFF30763B),
    roadLight: Color(0xFF5E5C66),
    roadDark: Color(0xFF54525C),
    rumbleLight: Color(0xFFF0E8E0),
    rumbleDark: Color(0xFFC93C3C),
    laneLine: Color(0xFFF7F0E6),
    fog: Color(0xFFE0A98A),
    starAlpha: 0.2,
    headlightAlpha: 0.4,
  );

  static const _cycle = [day, dusk, night, dawn];

  /// Samples the day cycle at [phase] in `[0, 1)`.
  static WorldPalette at(double phase) {
    final p = (phase % 1 + 1) % 1;
    final scaled = p * _cycle.length;
    final i = scaled.floor() % _cycle.length;
    final t = scaled - scaled.floor();
    // Hold each palette for a while and ease through the transition.
    final eased = _smooth(((t - 0.55) / 0.45).clamp(0.0, 1.0));
    return lerp(_cycle[i], _cycle[(i + 1) % _cycle.length], eased);
  }

  static double _smooth(double t) => t * t * (3 - 2 * t);

  static WorldPalette lerp(WorldPalette a, WorldPalette b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return WorldPalette(
      skyTop: c(a.skyTop, b.skyTop),
      skyBottom: c(a.skyBottom, b.skyBottom),
      horizonGlow: c(a.horizonGlow, b.horizonGlow),
      sun: c(a.sun, b.sun),
      mountainFar: c(a.mountainFar, b.mountainFar),
      mountainNear: c(a.mountainNear, b.mountainNear),
      grassLight: c(a.grassLight, b.grassLight),
      grassDark: c(a.grassDark, b.grassDark),
      roadLight: c(a.roadLight, b.roadLight),
      roadDark: c(a.roadDark, b.roadDark),
      rumbleLight: c(a.rumbleLight, b.rumbleLight),
      rumbleDark: c(a.rumbleDark, b.rumbleDark),
      laneLine: c(a.laneLine, b.laneLine),
      fog: c(a.fog, b.fog),
      starAlpha: a.starAlpha + (b.starAlpha - a.starAlpha) * t,
      headlightAlpha:
          a.headlightAlpha + (b.headlightAlpha - a.headlightAlpha) * t,
    );
  }
}
