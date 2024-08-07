import 'dart:async';
import 'dart:ffi';

import 'package:cab200finaldriver/Assistants/assistant_methods.dart';
import 'package:cab200finaldriver/global/global.dart';
import 'package:cab200finaldriver/models/user_ride_request_information.dart';
import 'package:cab200finaldriver/screens/main_screen.dart';
import 'package:cab200finaldriver/widgets/fare_amount_collection_dialog.dart';
import 'package:cab200finaldriver/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

class NewTripScreen extends StatefulWidget {
  
  UserRideRequestInformation? userRideRequestDetails;

  NewTripScreen({
    this.userRideRequestDetails
  });

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {

  GoogleMapController? newTripGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(45.521563, -122.677433),
    zoom: 14.4746,
  );

  String? buttonTitle = "Arrived";
  Color? buttonColor = Colors.green;

  Set<Marker> setOfMarkers = Set<Marker>();
  Set<Circle> setOfCircle = Set<Circle>();
  Set<Polyline> setOfPolyline = Set<Polyline>();
  List<LatLng> polyLinePositionCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  double mapPadding = 0;
  BitmapDescriptor? iconAnimatedMarker;
  var geoLocator = Geolocator();
  Position? onlineDriverCurrentPosition;

  String rideRequestStatus = "accepted";

  String durationFromOriginToDestination = "";

  bool isRequestDirectionDetails = false;

  //Step1: When driver accepts the user ride request
  //originLatlng = drivercurrent location
  //destinationLatlng = user pickup location


  //Step2: When driver picks up the user in his car
  //originLatlng = user current location which will also be the current drivers location at that point in time
  //then the destinationLatlng now changes to the users dropoff location
  Future<void> drawPolyLineFromOriginToDestination(LatLng originLatLng, LatLng destinationLatLng, bool darkTheme) async {
    showDialog(
      context: context, 
      builder: (BuildContext context) => ProgressDialog(message: "Please wait...",),
      );
    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);

    Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList = pPoints.decodePolyline(directionDetailsInfo.e_points!);

    polyLinePositionCoordinates.clear();

    if(decodedPolyLinePointsResultList.isNotEmpty){
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng){
        polyLinePositionCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    setOfPolyline.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: darkTheme ? Colors.lightGreen : Colors.green,
        polylineId: PolylineId("PolyLineID"),
        jointType: JointType.round,
        points: polyLinePositionCoordinates,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
        );

      setOfPolyline.add(polyline);
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

    newTripGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: MarkerId("originID"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

    Marker destinationMarker = Marker(
      markerId: MarkerId("destinationID"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

    setState(() {
      setOfMarkers.add(originMarker);
      setOfMarkers.add(destinationMarker);
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
      setOfCircle.add(originCircle);
      setOfCircle.add(destinationCircle);

    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    saveAssignedDriverDetailsToUserRideRequest();
  }

  getDriverLocationUpdatesAtRealTime(){

    LatLng oldLatLng = LatLng(0, 0);

    streamSubscriptionDriverLivePosition = Geolocator.getPositionStream().listen((Position position) {
      driverCurrentPosition = position;
      onlineDriverCurrentPosition = position;

      LatLng latLngliveDriverPosition = LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude);

      Marker animatingMarker = Marker(
        markerId: MarkerId("AnimatedMarker"),
        position: latLngliveDriverPosition,
        icon: iconAnimatedMarker!,
        infoWindow: InfoWindow(title: "This is your position: ")
        );

      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: latLngliveDriverPosition, zoom: 18);
        newTripGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        setOfMarkers.removeWhere((element) => element.markerId.value == "AnimatedMarker");
        setOfMarkers.add(animatingMarker);
      });

      oldLatLng = latLngliveDriverPosition;
      updateDurationTimeAtRealTime();

      //updating realtime driver location in database
      Map driverLatLngDataMap = {
        "latitude": onlineDriverCurrentPosition!.latitude.toString(),
        "longitude": onlineDriverCurrentPosition!.longitude.toString(),
      };
      FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!).child("driverLocation").set(driverLatLngDataMap);
    });
    
  }

  updateDurationTimeAtRealTime() async {
    if(isRequestDirectionDetails == false){
      isRequestDirectionDetails = true; 

      if(onlineDriverCurrentPosition == null){
        return;
      }

      var originLatLng = LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude);

      var destinationLaLng;

      if(rideRequestStatus == "accepted"){
        destinationLaLng = widget.userRideRequestDetails!.originLatLng;
      }
      else{
        destinationLaLng = widget.userRideRequestDetails!.destinationLatLng;
      }

      var directionInformation = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLaLng);

      if(directionInformation != null){
        setState(() {
          durationFromOriginToDestination = directionInformation.duration_text!;
        });
      }

      isRequestDirectionDetails = false;
    }

  }

  createDriverIconMarker(){
    if(iconAnimatedMarker == null){
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: ui.Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png").then((value){
        iconAnimatedMarker = value;
      });
    }
  }

  saveAssignedDriverDetailsToUserRideRequest(){

    DatabaseReference databaseReference = FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!);

    Map driverLocationDataMap = {
      "latitude": driverCurrentPosition!.latitude.toString(),
      "longitude": driverCurrentPosition!.longitude.toString(),
    };

    if(databaseReference.child("driverId") != "waiting"){
      databaseReference.child("driverLocation").set(driverLocationDataMap);

      databaseReference.child("status").set("accepted");
      databaseReference.child("driverId").set(onlineDriverData.id);
      databaseReference.child("driverName").set(onlineDriverData.name);
      databaseReference.child("driverPhone").set(onlineDriverData.phone);
      databaseReference.child("ratings").set(onlineDriverData.ratings);
      databaseReference.child("car_details").set(onlineDriverData.car_model.toString() + "" + onlineDriverData.car_number.toString() + "(" + onlineDriverData.car_color.toString() + ")" );

      saveRideRequestIdToDriverHistory();
    }
    else{
      Fluttertoast.showToast(msg: "This ride is already accepted by another driver");
      Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
    }
  }

  saveRideRequestIdToDriverHistory(){
    DatabaseReference tripsHistoryRef = FirebaseDatabase.instance.ref().child("drivers").child(firebaseAuth.currentUser!.uid).child("tripsHistory");

    tripsHistoryRef.child(widget.userRideRequestDetails!.rideRequestId!).set(true);
  }

  endTripNow() async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (BuildContext context) => ProgressDialog(message: "Please wait...",)
      );

      //get the tripdirectiondetails = distance travelled
      var currentDriverPositionLatLng = LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude);

      var tripDirectionDetails = await AssistantMethods.obtainOriginToDestinationDirectionDetails(currentDriverPositionLatLng, widget.userRideRequestDetails!.originLatLng!);


      //fare amount
      double totalFareAmount = AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetails);

      FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!).child("fareAmount").set(totalFareAmount.toString());

      FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!).child("status").set("ended");

      Navigator.pop(context);

      //display the fare amount in the dialog box
      showDialog(
        context: context, 
        builder: (BuildContext context) => FareAmountCollectionDialog(
          totalFareAmount: totalFareAmount,
          )
        );

        //save fareamount to drivers total earnings
        saveFareAmountToDriverEarnings(totalFareAmount);
  }

  saveFareAmountToDriverEarnings(totalFareAmount){
    FirebaseDatabase.instance.ref().child("drivers").child(firebaseAuth.currentUser!.uid).child("earnings").once().then((DatabaseEvent event){
      if(event.snapshot.value != null){
        double oldEarnings = double.parse(event.snapshot.value.toString());
        double driverTotalEarnings = oldEarnings + totalFareAmount;

        // Save the new earnings back to the database
      FirebaseDatabase.instance.ref()
          .child("drivers")
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child("earnings")
          .set(driverTotalEarnings.toString());
      }
      else{
        FirebaseDatabase.instance.ref()
          .child("drivers")
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child("earnings")
          .set(totalFareAmount.toString());
      }
    });
  }

  
  @override
  Widget build(BuildContext context) {

    createDriverIconMarker();

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            markers: setOfMarkers,
            circles: setOfCircle,
            polylines: setOfPolyline,
            onMapCreated: (GoogleMapController controller){
              _controllerGoogleMap.complete(controller);
              newTripGoogleMapController = controller;

              setState(() {
                mapPadding = 350;
              });

              var driverCurrentLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

              var userPickUpLatLng = widget.userRideRequestDetails!.originLatLng;

              drawPolyLineFromOriginToDestination(driverCurrentLatLng, userPickUpLatLng!, darkTheme);

              getDriverLocationUpdatesAtRealTime();

            },
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 18,
                      spreadRadius: 0.5,
                      offset: Offset(0.6, 0.6),
                    )
                  ]
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(
                        durationFromOriginToDestination,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkTheme ? Colors.lightGreen : Colors.black
                        ),
                      ),
                      SizedBox(height: 10,),

                      Divider(thickness: 1, color: darkTheme? Colors.lightGreen : Colors.grey,),

                      SizedBox(height: 10,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.userRideRequestDetails!.userName!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: darkTheme ? Colors.lightGreen : Colors.black,
                          ),
                          ),
                          IconButton(
                            onPressed: () {}, 
                            icon: Icon(Icons.phone,
                            color: darkTheme ? Colors.lightGreen : Colors.black,
                            ),
                            )
                        ],
                      ),
                      SizedBox(height: 10,),

                      Row(
                        children: [
                          Image.asset("images/origin.png",
                          width: 30,
                          height: 30,
                          ),
                          SizedBox(width: 10,),

                          Expanded(child: 
                          Container(
                            child: Text(
                              widget.userRideRequestDetails!.originAddress!,
                              style: TextStyle(
                                fontSize: 16,
                                color: darkTheme ? Colors.lightGreen : Colors.black
                              ),
                            ),
                          )
                          )
                        ],
                      ),
                      SizedBox(height: 10,),

                      Row(
                        children: [
                          Image.asset("images/destination.png",
                          width: 30,
                          height: 30,
                          ),
                          SizedBox(width: 10,),

                          Expanded(child: 
                          Container(
                            child: Text(
                              widget.userRideRequestDetails!.destinationAddress!,
                              style: TextStyle(
                                fontSize: 16,
                                color: darkTheme ? Colors.lightGreen : Colors.black
                              ),
                            ),
                          )
                          )
                        ],
                      ),
                      SizedBox(height: 10,),

                      Divider(
                        thickness: 1,
                        color: darkTheme ? Colors.lightGreen : Colors.green,
                      ),
                      SizedBox(height: 10,),
                      ElevatedButton.icon(
                        onPressed: () async {
                          //[driver has arrived at user pickup point so button changed to arrived button]
                          if(rideRequestStatus == "accepted"){
                            rideRequestStatus = "arrived";

                            FirebaseDatabase.instance.ref().child("All Ride Reqeust").child(widget.userRideRequestDetails!.rideRequestId!).child("status").set(rideRequestStatus);

                            setState(() {
                              buttonTitle = "On our way!";
                              buttonColor = Colors.lightGreen;
                            });

                            showDialog(
                              context: context,
                              barrierDismissible: false, 
                              builder: (BuildContext context) => ProgressDialog(message: "Loading...",)
                              );

                            await drawPolyLineFromOriginToDestination(
                              widget.userRideRequestDetails!.originLatLng!, 
                              widget.userRideRequestDetails!.destinationLatLng!, 
                              darkTheme
                              );
                              Navigator.pop(context);
                          }
                          //assuming the user has now been picked up from their current location, now display the let's go button
                          else if(rideRequestStatus == "arrived"){
                            rideRequestStatus = "ontrip";

                            FirebaseDatabase.instance.ref().child("All Ride Reqeust").child(widget.userRideRequestDetails!.rideRequestId!).child("status").set(rideRequestStatus);

                            setState(() {
                              buttonTitle = "End Trip!";
                              buttonColor = Colors.redAccent;
                            });
                          }
                          else if(rideRequestStatus == "ontrip"){
                            endTripNow();
                          }

                        },
                        icon: Icon(Icons.directions_car,color: darkTheme ? Colors.black : Colors.white, size:25 ,), 
                        label: Text(
                          buttonTitle!,
                          style: TextStyle(
                            color: darkTheme ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),

                        )
                        )
                    ],
                  ),
                  ),
              ),
              ),
            )


        ],
      ),
    );
  }
}