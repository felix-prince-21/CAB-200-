import 'dart:async';
import 'dart:convert';
//import 'dart:math';

import 'package:cab200final/Assistants/assistant_methods.dart';
import 'package:cab200final/Assistants/geofire_assistant.dart';
import 'package:cab200final/global/global.dart';
import 'package:cab200final/global/map_key.dart';
import 'package:cab200final/infoHandler/app_info.dart';
import 'package:cab200final/models/active_nearby_available_drivers.dart';
import 'package:cab200final/screens/drawer_Screen.dart';
import 'package:cab200final/screens/precise_pickup_location.dart';
import 'package:cab200final/screens/search_places_screen.dart';
import 'package:cab200final/widgets/pay_fare_amount_dialog.dart';
import 'package:cab200final/widgets/progress_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
//import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/directions.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(45.521563, -122.677433),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight = 220;
  double waitingResponsefromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;
  double showSuggestedRidesContainerHeight = 0;
  double searchingForDriverContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocation = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoOrdinatesList = [];
  Set<Polyline> polylineSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  String userName = "";
  String userEmail = "";

  bool openNavigationDrawer = true;

  bool activeNearbyDriverKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

  DatabaseReference? referenceRideRequest;

  String selectedVehicleType = "";

  String driverRideStatus = "Driver is on the way!";
  StreamSubscription<DatabaseEvent>? tripRidesRequestInfoStreamSubscription;

  List<ActiveNearbyAvailableDrivers> onlineNearByAvailableDriversList = [];

  String userRideRequestStatus = "";
  bool requestPositionInfo = true;


  void locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng LatLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: LatLngPosition, zoom: 15);

    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoOdinates(userCurrentPosition!, context);
    print("This is your address = " + humanReadableAddress);

    userName = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;

    initializeGeoFireListener();

    //AssistantMethods.readTripsKeysForOnlineUser(context);
  }

  void initializeGeoFireListener() {
    Geofire.initialize("activeDrivers");

    Geofire.queryAtLocation(userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!
    .listen((map) {
      print(map);

      if(map != null) {
        var callBack = map["callBack"];

        switch(callBack) {
          //whenever any drivercomes online
          case Geofire.onKeyEntered:
            ActiveNearbyAvailableDrivers activeNearbyAvailableDrivers = ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDrivers.locationLatitude = map["latitude"];
            activeNearbyAvailableDrivers.locationLongitude = map["longitude"];
            activeNearbyAvailableDrivers.driverId = map["key"];
            GeofireAssistant.activeNearByAvailableDriversList.add(activeNearbyAvailableDrivers);
            if(activeNearbyDriverKeysLoaded == true){
            
            }
            break;
          
          //when any driver goes non-active/online
          case Geofire.onKeyExited:
            GeofireAssistant.deleteOfflineDriverFromList(map["key"]);
          
            break;

          //update driver location whenevr driver moves
          case Geofire.onKeyMoved:
            ActiveNearbyAvailableDrivers activeNearbyAvailableDrivers = ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDrivers.locationLatitude = map["latitude"];
            activeNearbyAvailableDrivers.locationLongitude = map["longitude"];
            activeNearbyAvailableDrivers.driverId = map["key"];
            GeofireAssistant.updateActiveNearByAvailableDriverLocation(activeNearbyAvailableDrivers);
          
            break;

          //display online active drivers
          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
          
            break;
        }
      }

      setState(() {
        displayActiveDriversonUsersMap();
      });
    });
  }

  void displayActiveDriversonUsersMap(){
    setState(() {
      markersSet.clear();
      circlesSet.clear();

      Set<Marker> driversMarketSet = Set<Marker>();

      for(ActiveNearbyAvailableDrivers eachDriver in GeofireAssistant.activeNearByAvailableDriversList){
        LatLng eachDriverActivePosition = LatLng(eachDriver.locationLatitude!, eachDriver.locationLatitude!);

        Marker marker = Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );

        driversMarketSet.add(marker);
      }

      setState(() {
        markersSet = driversMarketSet;
      });
    });
  }

  void createActiveNearByDriverIconMarker(){
    if(activeNearbyIcon == null){
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png").then((value){
        activeNearbyIcon = value;
      });
    }
  }
  Future<void> sendRideRequestNotification(String driverId) async {
    final serverKey = 'YOUR_SERVER_KEY_HERE';  // Replace with your FCM server key

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(<String, dynamic>{
        'to': '/topics/$driverId',
        'notification': <String, dynamic>{
          'title': 'New Ride Request',
          'body': 'You have a new ride request. Please check the app.',
          'sound': 'default',
        },
        'data': <String, dynamic>{
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'id': '1',
          'status': 'done',
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }

  void onRequestRide(String driverId) {
    sendRideRequestNotification(driverId);
  }

  Future<void> drawPolyLineFromOriginToDestination(bool darkTheme) async {
    var originPosition = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!, destinationPosition.locationLongitude!);

    showDialog(
      context: context, 
      builder: (BuildContext context) => ProgressDialog(message: "Please wait...",),
      );

    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
    });

    Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodePolyLinePointsResultList = pPoints.decodePolyline(directionDetailsInfo.e_points!);

    pLineCoOrdinatesList.clear();

    if(decodePolyLinePointsResultList.isNotEmpty){
      decodePolyLinePointsResultList.forEach((PointLatLng pointLatLng){
        pLineCoOrdinatesList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();
    
    setState(() {
      Polyline polyline = Polyline(
        color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
        );

        polylineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    }
    else if(originLatLng.latitude > destinationLatLng.latitude){
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        );
    }
    else{
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: MarkerId("originID"),
      infoWindow: InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen) 
      );

    Marker destinationMarker = Marker(
      markerId: MarkerId("destinationID"),
      infoWindow: InfoWindow(title: destinationPosition.locationName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed) 
      );
 
    setState(() {
      markersSet.add(originMarker);
      markersSet.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
      );

    Circle destinationCircle = Circle(
      circleId: CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
      );

    setState(() {
      circlesSet.add(originCircle);
      circlesSet.add(destinationCircle);
    });
    
  }

  void showSearchingForDriversContainer(){
    setState(() {
      searchingForDriverContainerHeight = 200;
    });
  }

  void showSuggestedRidesContainer(){
    setState(() {
      showSuggestedRidesContainerHeight = 400;
      bottomPaddingOfMap = 400;
    });
  }


  getAddressFromLatLng() async{
    try {
      GeoData data = await Geocoder2.getDataFromCoordinates(
        latitude: pickLocation!.latitude, 
        longitude: pickLocation!.longitude, 
        googleMapApiKey: mapkey
        );
        setState(() {
          Directions userPickUpAddress = Directions();
          userPickUpAddress.locationLatitude = pickLocation!.latitude;
          userPickUpAddress.locationLongitude = pickLocation!.longitude;
          userPickUpAddress.locationName = data.address;

          Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);


          //_address = data.address;
        });
    } catch (e) {
      print(e); 
    }
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }


  saveRideRequestInformation(String selectedVehicleType){
    //save the riderequest info
    referenceRideRequest = FirebaseDatabase.instance.ref().child("All Ride Requests").push();

    var originLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map originLocationMap = {
      //key: value
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };

    Map destinationLocationMap = {
      //key: value
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };

    Map userInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "username": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInformationMap);

    tripRidesRequestInfoStreamSubscription = referenceRideRequest!.onValue.listen((eventSnap) async{
      if(eventSnap.snapshot.value == null){
        return;
      }

      if((eventSnap.snapshot.value as Map)["car_details"] != null ){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["car_details"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverPhone"] != null ){
        setState(() {
          driverPhone = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverName"] != null ){
        setState(() {
          driverName = (eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["status"] != null ){
        setState(() {
          userRideRequestStatus = (eventSnap.snapshot.value as Map)["status"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverLocation"] != null ){
        double driverCurrentPositionLat = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["latitude"].toString());
        double driverCurrentPositionLng = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["longitude"].toString());

        LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

        //when the status changes to accepted
        if(userRideRequestStatus == "accepted"){
          updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
        }
        //status = arrived
        if(userRideRequestStatus == "arrived"){
          setState(() {
            driverRideStatus = "Driver has arrived";
          });
        }

        //status = ontrip
        if(userRideRequestStatus =="ontrip"){
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }

        if(userRideRequestStatus == "ended"){
          if((eventSnap.snapshot.value as Map)["fareAmount"] != null) {
            double fareAmount = double.parse((eventSnap.snapshot.value as Map)["fareAmount"].toString());

            var response = await showDialog(
              context: context, 
              builder: (BuildContext context) => PayFarAmountDialog(
                fareAmount : fareAmount,
              ),
              );

              if(response == "Cash Paid"){
                //user can now rate the driver
                if((eventSnap.snapshot.value as Map)["driverId"] != null){
                  String assignedDriverId = (eventSnap.snapshot.value as Map)["driverId"].toString();
                  //Navigator.push(context, MaterialPageRoute(builder: (c) => RateDriverScreen()));

                  referenceRideRequest!.onDisconnect();
                  tripRidesRequestInfoStreamSubscription!.cancel();
                }
              }
          }
        }
      }
    });

    onlineNearByAvailableDriversList = GeofireAssistant.activeNearByAvailableDriversList;
    searchNearestOnlineDrivers(selectedVehicleType);

  }

  searchNearestOnlineDrivers(selectedVehicleType) async{
    if(onlineNearByAvailableDriversList.length == 0){
      //delete the ride request information
      referenceRideRequest!.remove();

      setState(() {
        polylineSet.clear();
        markersSet.clear();
        circlesSet.clear();
        pLineCoOrdinatesList.clear();
      });

      Fluttertoast.showToast(msg: "No online nearest Drivers Available");
      Fluttertoast.showToast(msg: "Search Again...");

      Future.delayed(Duration(milliseconds: 4000), () { 
        referenceRideRequest!.remove();
        Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
      });
      return;
    }

    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    print("Driver List: " + driversList.toString());

    for(int i = 0; i< driversList.length; i++){
      if(driversList[i]["car_details"]["type"] == selectedVehicleType){
        AssistantMethods.sendNotificationToDriverNow(driversList[i]["token"], referenceRideRequest!.key!, context);
      }
    }

    Fluttertoast.showToast(msg: "Looking for a driver for you now...");

    showSearchingForDriversContainer();

    await FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).child("driverId").onValue.listen((eventRideRequestSnapshot) {
      print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
      if(eventRideRequestSnapshot.snapshot.value != null){
        if(eventRideRequestSnapshot.snapshot.value != "waiting"){
          showUIForAssignedDriverInfo();
        }

      }
    });
  }

  updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng) async {
    if(requestPositionInfo == true){
      requestPositionInfo = false;
      LatLng userPickUpPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng, userPickUpPosition,
        );

      if(directionDetailsInfo == null){
        return;
      }
      setState(() {
        driverRideStatus = "Driver is on the way: " + directionDetailsInfo.duration_text.toString();
      });

      requestPositionInfo = true;
    }
  }

  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
    if(requestPositionInfo == true){
      requestPositionInfo = false;

      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
        dropOffLocation!.locationLatitude!, 
        dropOffLocation.locationLongitude!,
        );

        var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
          driverCurrentPositionLatLng, 
          userDestinationPosition
        );

        if(directionDetailsInfo == null){
          return;
        }
        setState(() {
          driverRideStatus = "Approaching Destination: " + directionDetailsInfo.duration_text.toString();
        });

        requestPositionInfo = true;


    }
  }

  showUIForAssignedDriverInfo(){
    setState(() {
      waitingResponsefromDriverContainerHeight = 0;
      searchLocationContainerHeight = 0;
      assignedDriverInfoContainerHeight = 0;
      showSuggestedRidesContainerHeight = 0;
      bottomPaddingOfMap = 200;
    });
  }

  retrieveOnlineDriversInformation(List onlineNearestDriversList) async {
    driversList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");

    for(int i = 0; i < onlineNearestDriversList.length; i++){
      await ref.child(onlineNearestDriversList[i].driverId.toString()).once().then((dataSnapshot){
        var driverKeyInfo = dataSnapshot.snapshot.value;

        driversList.add(driverKeyInfo);
        print("driver key information = " + driversList.toString());
      });
    }
  }

  

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }
  

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    createActiveNearByDriverIconMarker();
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: _scaffoldState,
        drawer: DrawerScreen(),
        body: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(top: 30, bottom: bottomPaddingOfMap),
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              initialCameraPosition: _kGooglePlex,
              polylines: polylineSet,
              markers: markersSet,
              circles: circlesSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;

                setState(() {});

                // _requestPermissions();
                locateUserPosition();
              },
              onCameraMove: (CameraPosition? position) {
                if (pickLocation != position!.target) {
                  setState(() {
                    pickLocation = position.target;
                  });
                }
              },
              onCameraIdle: () {
                getAddressFromLatLng();
              },
            ),
            // Align(
            //   alignment: Alignment.center,
            //   child: Padding(
            //     padding: const EdgeInsets.only(bottom: 35.0),
            //     child: Image.asset("images/pick.png", height: 45, width: 45),
            //     ),
            // ),

            //custom hamburger button for drawer
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                child: GestureDetector(
                  onTap: () {
                    _scaffoldState.currentState!.openDrawer();
                  },
                  child: CircleAvatar(
                    backgroundColor: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.white,
                    child: Icon(
                      Icons.menu,
                      color: darkTheme ? Colors.black : Colors.lightGreen,
                    ),
                  ),
                ),
              )
              ),

            //ui for searching location
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.black : Colors. white,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,),
                                      SizedBox(width: 10,),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("From",
                                              style: TextStyle(
                                                color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors. green,
                                                fontSize: 12, 
                                                fontWeight: FontWeight.bold
                                              ),
                                              ),
                                              Text(Provider.of<AppInfo>(context).userPickUpLocation != null 
                                                ? Provider.of<AppInfo>(context).userPickUpLocation!.locationName! 
                                                : "Unable to get Address",
                                                style: TextStyle(color: Colors.grey, fontSize: 14),
                                                )
                                          ],
                                        ),
                                      )
                                    ],
                                    ),
                                  ),
                                  SizedBox(height: 5,),

                                  Divider(
                                    height: 1,
                                    thickness: 2,
                                    color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,
                                  ),
                                  SizedBox(height: 5,),

                                  Padding(
                                    padding: EdgeInsets.all(5),
                                    child: GestureDetector(
                                      onTap: () async {
                                        //go to search places screen
                                        var responseFromSearchScreen = await Navigator.push(context, MaterialPageRoute(builder: (c) => SearchPlacesScreen()));

                                        if(responseFromSearchScreen == "obtainedDropoff"){
                                          setState(() {
                                            openNavigationDrawer = false;
                                          });
                                        }

                                        await drawPolyLineFromOriginToDestination(darkTheme);
                                      }, 
                                      child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,),
                                      SizedBox(width: 10,),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("To",
                                            style: TextStyle(
                                              color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors. green,
                                              fontSize: 12, 
                                              fontWeight: FontWeight.bold
                                            ),
                                            ),
                                            Text(Provider.of<AppInfo>(context).userDropOffLocation != null 
                                              ? Provider.of<AppInfo>(context).userDropOffLocation!.locationName!
                                              : "Where to today?",
                                              style: TextStyle(color: Colors.grey, fontSize: 14),
                                              )
                                        ],
                                      )
                                    ],
                                    ),
                                    ),
                                    )
                              ],
                            ),
                          ),
                          SizedBox(height: 5,),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => PrecisePickUpScreen()));

                                }, 
                                child: Text(
                                  "Change Pick Up Address",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  )
                                ),
                                ),

                                SizedBox(width: 10,),

                                ElevatedButton(
                                onPressed: () {
                                  if(Provider.of<AppInfo>(context,listen: false).userDropOffLocation != null){
                                    showSuggestedRidesContainer();
                                  }
                                  else{
                                    Fluttertoast.showToast(msg: "Please Select where you want to go");
                                  }

                                }, 
                                child: Text(
                                  "Show Fare",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  )
                                ),
                                ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
                ),
            ),

            //ui for suggested rides
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: showSuggestedRidesContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    topLeft: Radius.circular(20),
                  )
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.lightGreen : Colors.green,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),
                      
                          SizedBox(width: 15,),
                      
                          Text(
                            Provider.of<AppInfo>(context).userPickUpLocation != null 
                              ? Provider.of<AppInfo>(context).userPickUpLocation!.locationName! 
                              : "Unable to get Address",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                        ),

                      SizedBox(height: 20,),

                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),
                      
                          SizedBox(width: 15,),
                      
                          Text(
                            Provider.of<AppInfo>(context).userDropOffLocation != null 
                              ? Provider.of<AppInfo>(context).userDropOffLocation!.locationName! 
                              : "Unable to get Address",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                        ),

                        SizedBox(height: 20,),

                        Text("Suggested Rides",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        ),

                        SizedBox(height: 1,),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVehicleType = "Car";
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedVehicleType == "Car" ? (darkTheme ? Colors.lightGreen : Colors.green) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(25.0),
                                    child: Column(
                                      children: [
                                        Image.asset("images/car2.png", scale: 5,),
                                
                                        SizedBox(height: 2.5,),
                                
                                        Text(
                                          "Car",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selectedVehicleType == "Car" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white : Colors.black),
                                          ),
                                          ),
                                          SizedBox(height: 2,),
                                
                                          Text(
                                            tripDirectionDetailsInfo != null ? "GH₵ ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 2) * 15).toStringAsFixed(1)}"
                                              : "null",
                                            style: TextStyle(
                                              color: Colors.grey
                                            ),
                                
                                          )
                                      ],
                                    ),
                                    )
                                ),
                              ),
                              
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVehicleType = "TookTook";
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedVehicleType == "TookTook" ? (darkTheme ? Colors.lightGreen : Colors.green) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(25.0),
                                    child: Column(
                                      children: [
                                        Image.asset("images/TookTook.png", scale: 18,),
                                
                                        SizedBox(height: 3.5,),
                                
                                        Text(
                                          "TookTook",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selectedVehicleType == "TookTook" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white : Colors.black),
                                          ),
                                          ),
                                          SizedBox(height: 2,),
                                
                                          Text(
                                            tripDirectionDetailsInfo != null ? "GH₵ ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 1) * 15).toStringAsFixed(1)}"
                                              : "null",
                                            style: TextStyle(
                                              color: Colors.grey
                                            ),
                                
                                          )
                                      ],
                                    ),
                                    )
                                ),
                              ),
                          
                          
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVehicleType = "Bike";
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedVehicleType == "Bike" ? (darkTheme ? Colors.lightGreen : Colors.green) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(25.0),
                                    child: Column(
                                      children: [
                                        Image.asset("images/Bike.png", scale: 18,),
                                
                                        SizedBox(height: 0.5,),
                                
                                        Text(
                                          "Bike",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selectedVehicleType == "Bike" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white : Colors.black),
                                          ),
                                          ),
                                          SizedBox(height: 2,),
                                
                                          Text(
                                            tripDirectionDetailsInfo != null ? "GH₵ ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 1.3) * 15).toStringAsFixed(1)}"
                                              : "null",
                                            style: TextStyle(
                                              color: Colors.grey
                                            ),
                                
                                          )
                                      ],
                                    ),
                                    )
                                ),
                              )
                            ],
                          ),
                        ),

                        SizedBox(height: 20,),

                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if(selectedVehicleType != ""){
                                saveRideRequestInformation(selectedVehicleType);
                              }
                              else{
                                Fluttertoast.showToast(msg: "Please Select a Vehicle from \n suggested rides...");
                              }

                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: darkTheme ? Colors.lightGreen : Colors.green,
                                borderRadius: BorderRadius.circular(10)
                              ),
                              child: Center(
                                child: Text(
                                  "Request a Ride",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                )
                              ),
                            ),
                          )
                          )
                    ],
                  ),
              )
              )
              ),

              //request a ride
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: searchingForDriverContainerHeight,
                  decoration: BoxDecoration(
                    color: darkTheme ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LinearProgressIndicator(
                          color: darkTheme ? Colors.lightGreen: Colors.green,
                        ),

                        Center(
                          child: Text(
                            "Searching For a Driver...",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 22,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),

                        SizedBox(height: 10,),

                        GestureDetector(
                          onTap: (){
                            referenceRideRequest!.remove();
                            setState(() {
                              searchingForDriverContainerHeight = 0;
                              showSuggestedRidesContainerHeight = 0;
                            });

                          },
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(width: 1, color: Colors.grey)
                            ),
                            child: Icon(Icons.close, size: 25,),
                          ),
                        ),

                        SizedBox(height: 15,),

                        Container(
                          width: double.infinity,
                          child: Text(
                            "Cancel",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                              ),
                          ),
                        )


                      ],
                    )
                    ),
                ),
                ),

              

            // Positioned(
            //   top: 40,
            //   right: 20,
            //   left: 20,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       border: Border.all(color: Colors.white),
            //       borderRadius: BorderRadius.all(Radius.circular(20.0)),
            //       color: Colors.green,
            //     ),
            //     padding: EdgeInsets.all(20),
            //     child: Text(
            //       Provider.of<AppInfo>(context).userPickUpLocation != null 
                //       ? (Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 24) + "..." 
                //       : "Unable to get Address",
            //         :(_address!).substring(0,24) + "...",
            //       overflow: TextOverflow.visible, softWrap: true,
            //     ),
            //   ), 
            // ),


        
        ],
        ),

      ),
    );
  }
}
