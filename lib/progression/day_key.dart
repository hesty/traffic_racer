/// Calendar-day helpers shared by the date-driven progression features.
///
/// A day key is `yyyymmdd` as an int: cheap to persist, compare and use as a
/// random seed.
int dayKeyOf(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

DateTime dateOfDayKey(int key) =>
    DateTime(key ~/ 10000, (key ~/ 100) % 100, key % 100);
