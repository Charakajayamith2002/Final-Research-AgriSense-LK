/// Simple in-memory cache that stores the last submitted form data
/// from each prediction component so other screens can "fetch" it.
class AppCache {
  AppCache._();

  /// Last data submitted from Cultivation Targeting (Component 3)
  static Map<String, String> lastCultivationData = {};

  /// Last data submitted from Market Ranking (Component 2)
  static Map<String, String> lastMarketData = {};
}
