import 'package:cab200final/models/active_nearby_available_drivers.dart';

class GeofireAssistant {
  static List<ActiveNearbyAvailableDrivers> activeNearByAvailableDriversList = [];

  static void deleteOfflineDriverFromList(String driverId) {
    int indexNumber = activeNearByAvailableDriversList.indexWhere((element) => element.driverId == driverId);

    activeNearByAvailableDriversList.removeAt(indexNumber);
  }

  static void updateActiveNearByAvailableDriverLocation(ActiveNearbyAvailableDrivers driverWhoMove){
    int indexNumber = activeNearByAvailableDriversList.indexWhere((element) => element.driverId == driverWhoMove.driverId);

    activeNearByAvailableDriversList[indexNumber].locationLatitude = driverWhoMove.locationLatitude;
    activeNearByAvailableDriversList[indexNumber].locationLongitude = driverWhoMove.locationLongitude;
  }
}