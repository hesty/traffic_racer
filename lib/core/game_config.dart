/// Tunable constants for the pseudo-3D world and gameplay balance.
///
/// World units are arbitrary: the road is `roadWidth` wide (half-width from
/// the centre line), and the track is made of segments of `segmentLength`.
class GameConfig {
  GameConfig._();

  // --- World geometry ---------------------------------------------------
  static const double segmentLength = 200;
  static const double roadWidth = 2000;
  static const double cameraHeight = 1100;
  static const double fieldOfViewDegrees = 100;
  static const int drawDistance = 200;
  static const int rumbleLength = 3;
  static const int laneCount = 3;

  /// Normalised lane width, road spans -1..1.
  static const double laneWidth = 2 / laneCount;

  /// Normalised vehicle width (fraction of the half road width).
  static const double vehicleWidth = 0.42;

  /// Normalised centre offset of a lane index.
  static double laneCenter(int lane) => -1 + laneWidth * (lane + 0.5);

  // --- Speeds (world units / second) -----------------------------------
  static const double baseSpeed = 5200;
  static const double speedPerLevel = 450;
  static const double maxSpeed = 11500;
  static const double nitroMultiplier = 1.55;
  static const double slowMotionScale = 0.5;
  static const double trafficSpeedMin = 0.32;
  static const double trafficSpeedMax = 0.58;

  // --- Gameplay ---------------------------------------------------------
  static const double laneChangeDuration = 0.22;
  static const int scorePerLevel = 1500;
  static const double distanceScoreDivisor = 55;
  static const int nearMissBonus = 120;
  static const double comboWindow = 2.6;
  static const double powerUpDuration = 6;
  static const double powerUpSpawnInterval = 9;
  static const double crashDuration = 1.4;

  /// Seconds after a run starts during which the player's lane stays clear.
  static const double startGraceSeconds = 3;

  /// Distance (world units) at which a rear-end counts as a collision.
  static const double collisionLength = segmentLength * 1.1;

  /// Distance window around the player in which a lane-adjacent pass counts
  /// as a near miss.
  static const double nearMissLength = segmentLength * 1.6;

  /// Minimum z gap between two traffic vehicles in the same lane.
  static const double sameLaneGap = segmentLength * 14;

  /// Stretch of road (world units) within which traffic must leave at least
  /// one lane open.
  static const double blockWindow = segmentLength * 10;

  /// Base traffic density per level (vehicles alive at once).
  static int trafficCountForLevel(int level) => (5 + level).clamp(5, 14);

  /// Traffic never spawns closer than this in front of the player.
  static const double minSpawnAhead = segmentLength * 60;
  static const double maxSpawnAhead = segmentLength * (drawDistance - 10);
  static const double despawnBehind = segmentLength * 8;

  // --- Progression: daily missions --------------------------------------
  static const int missionsPerDay = 3;

  /// Target tiers per mission kind; the daily roll picks one tier for each
  /// mission and pays the matching entry of [missionRewards].
  static const List<int> missionNearMissTargets = [10, 15, 25];
  static const List<int> missionDistanceTargets = [1500, 2500, 4000];
  static const List<int> missionComboTargets = [4, 5, 7];
  static const List<int> missionOvertakeTargets = [15, 25, 40];
  static const List<int> missionPowerUpTargets = [4, 6, 9];
  static const List<int> missionLevelTargets = [3, 4, 5];
  static const List<int> missionSurviveTargets = [60, 90, 120];
  static const List<int> missionRewards = [40, 60, 90];
  static const int missionAllCompleteBonus = 75;

  // --- Progression: coins & streak ---------------------------------------
  static const double coinsPerMeter = 0.05;
  static const int coinsPerNearMiss = 2;
  static const int ghostBeatenBonus = 40;

  /// Extra coin fraction per consecutive day played, capped at [streakBonusCap].
  static const double streakBonusPerDay = 0.1;
  static const double streakBonusCap = 0.5;

  // --- Progression: ghost -----------------------------------------------
  static const double ghostSampleInterval = 0.5;
  static const double ghostAlpha = 0.42;

  /// The ghost sprite is only placed on the track within this gap (metres).
  static const double ghostVisibleMeters = 300;
}
