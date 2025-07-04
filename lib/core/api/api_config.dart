class ApiConfig {
  static const String baseUrl = 'http://rnd3.satnetcom.com:8069/api';
  static const String baseUrlTraccar = 'http://203.80.13.234:8099/api';
  static const String loginEndpoint = '/auth/login';
  static const String connectionEndpoint =
      'http://rnd3.satnetcom.com:8069/web/session/authenticate';
  static const String getRoutes = '/route/list';
  static const String getFleets = '/fleet/list';
  static const String getBusPoints = '/bus-point/list';
  static const String routeCreate = '/route/create';
  static const String updateBusTripState = '/bus_trip';
}
