import 'dart:convert';

import 'package:cab200finaldriver/Assistants/request_asstant.dart';
import 'package:cab200finaldriver/global/global.dart';
import 'package:cab200finaldriver/global/map_key.dart';
import 'package:cab200finaldriver/models/direction_details_info.dart';
import 'package:cab200finaldriver/models/directions.dart';
import 'package:cab200finaldriver/models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../infoHandler/app_info.dart';

class AssistantMethods{
  static void readCurrentOnlineUserInfo() async {
    currentUser = firebaseAuth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
    .ref()
    .child("users")
    .child(currentUser!.uid);

    userRef.once().then((snap){
      if(snap.snapshot.value != null){
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
      }
    });
  }

  static Future<String> searchAddressForGeographicCoOdinates(Position position, context) async {
    
    String apiUrl = "https://maps.googleapis.com/maps/api/geocode/json?LatLng=${position.latitude},${position.longitude}&key=$mapkey";
    String humanReadableAddress = "";

    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

    if(requestResponse != "Error Occured. Failed. No Response."){
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;
      userPickUpAddress.locationName = humanReadableAddress;

      Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress); 
    }

    return humanReadableAddress; 
  }

  static Future<DirectionDetailsInfo> obtainOriginToDestinationDirectionDetails(LatLng originPosition, LatLng destinationPosition) async{

    String urlOriginToDestinationDirectionDetails = "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapkey";
    var responseDirectionApi = await RequestAssistant.receiveRequest(urlOriginToDestinationDirectionDetails);

    try {
    final response = await http.get(Uri.parse(urlOriginToDestinationDirectionDetails));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print(data);
    } else {
      print("Failed to get directions. Status code: ${response.statusCode}");
      print("Response: ${response.body}");
    }
  } catch (e) {
    print("Error: $e");
  }

    // if(responseDirectionApi == "Error Occured. Failed. No Reponse."){
    //     return null;
    //   }

    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    directionDetailsInfo.e_points = responseDirectionApi["routes"][0]["overview_polyline"]["points"];

    directionDetailsInfo.distance_text = responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distance_value = responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];

    directionDetailsInfo.duration_text = responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.duration_value = responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetailsInfo;
  }

  static pauseLiveLocationUpdates() {
    streamSubscriptionPosition!.pause();
    Geofire.removeLocation(firebaseAuth.currentUser!.uid);
  }

  static double calculateFareAmountFromOriginToDestination(DirectionDetailsInfo directioDetailsInfo){
    double timeTravelledFareAmountPerMinute = (directioDetailsInfo.duration_value! /60) * 0.1;
    double distanceTravelledFareAmountPerKilometer = (directioDetailsInfo.duration_value! / 1000) * 0.1;

    double totalFareAmount = timeTravelledFareAmountPerMinute + distanceTravelledFareAmountPerKilometer;
    double localCurrencyTotalFare = totalFareAmount * 15;

    if(driverVehicleType == "Bike"){
      double resultFareAmount = ((localCurrencyTotalFare.truncate()) * 0.8);
      resultFareAmount;
    }
    else if(driverVehicleType == "TookTook"){
      double resultFareAmount = ((localCurrencyTotalFare.truncate()) * 1.5);
      resultFareAmount;
    }
    else if(driverVehicleType == "Car"){
      double resultFareAmount = ((localCurrencyTotalFare.truncate()) * 2);
      resultFareAmount;
    }
    else{
      return localCurrencyTotalFare.truncate().toDouble();
    }
    return localCurrencyTotalFare.truncate().toDouble();
  }
}