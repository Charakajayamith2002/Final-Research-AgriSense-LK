class ApiConfig {
  // ============================================================
  // CHANGE THIS TO YOUR LAPTOP'S IP ADDRESS WHEN RUNNING DEMO
  // Find your IP: run "ipconfig" in cmd → look for IPv4 Address
  // Example: static const String baseUrl = 'http://192.168.1.5:5000';
  // For Android Emulator use: http://10.0.2.2:5000
  // ============================================================
  // For Chrome/Web testing: use localhost
  // For Android phone over WiFi: change to 'http://192.168.1.4:5001'
  static const String baseUrl = 'http://localhost:5001';
  // static const String baseUrl = 'http://10.203.163.84:5001';


  // Auth endpoints (mobile JSON API)
  static const String login = '$baseUrl/api/mobile/login';
  static const String register = '$baseUrl/api/mobile/register';
  static const String logout = '$baseUrl/api/mobile/logout';
  static const String profile = '$baseUrl/profile';
  static const String updateProfile = '$baseUrl/update-profile';
  static const String getProfile = '$baseUrl/api/mobile/get-profile';
  static const String uploadProfilePhoto = '$baseUrl/api/mobile/upload-profile-photo';
  static const String resolveUser = '$baseUrl/api/mobile/resolve-user';

  // Feature endpoints
  static const String priceDemand = '$baseUrl/price-demand';
  static const String marketRanking = '$baseUrl/market-ranking';
  static const String cultivationTargeting = '$baseUrl/cultivation-targeting';
  static const String yieldQuality = '$baseUrl/yield-quality';
  static const String profitableStrategy = '$baseUrl/profitable-strategy';
  static const String history = '$baseUrl/history';

  // API endpoints
  static const String getDistricts = '$baseUrl/api/get-districts';
  static const String getDsDivisions = '$baseUrl/api/get-ds-divisions';
  static const String getItems = '$baseUrl/api/get-items';
  static const String businessPredict = '$baseUrl/api/business-predict';
  static const String mobileProfitableStrategy = '$baseUrl/api/mobile/profitable-strategy';
  static const String mobileMarketRanking = '$baseUrl/api/mobile/market-ranking';
  static const String mobileCultivationTargeting = '$baseUrl/api/mobile/cultivation-targeting';
  static const String mobileYieldQuality = '$baseUrl/api/mobile/yield-quality';
  static const String cultivationPredict = '$baseUrl/api/cultivation-predict';
  static const String marketPredict = '$baseUrl/api/market-predict';
  static const String exportCsv = '$baseUrl/api/export-history/csv';
  static const String exportJson = '$baseUrl/api/export-history/json';
}
