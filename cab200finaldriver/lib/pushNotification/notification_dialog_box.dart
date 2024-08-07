import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cab200finaldriver/Assistants/assistant_methods.dart';
import 'package:cab200finaldriver/global/global.dart';
import 'package:cab200finaldriver/models/user_ride_request_information.dart';
import 'package:cab200finaldriver/screens/new_trip_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NotificationDialogBox extends StatefulWidget {
  
  UserRideRequestInformation? userRideRequestDetails;

  NotificationDialogBox({this.userRideRequestDetails});


  @override
  State<NotificationDialogBox> createState() => _NotificationDialogBoxState();
}

class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        margin: EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: darkTheme ? Colors.black : Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              onlineDriverData.car_type == "Car" ? "images/car.png"
                : onlineDriverData.car_type == "TookTook" ? "images/TookTook.png"
                : "images/Bike.png",
            ),

            SizedBox(height: 10,),

            //title
            Text("New Ride Request",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: darkTheme ? Colors.lightGreen : Colors.green,
            ),
            ),

            SizedBox(height: 14,),

            Divider(
              height: 2,
              thickness: 2,
              color: darkTheme ? Colors.lightGreen : Colors.green,
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset("images/origin.png",
                      width: 30,
                      height: 30,
                      ),

                      SizedBox(width: 10,),

                      Expanded(
                        child: Container(
                          child: Text(
                            widget.userRideRequestDetails!.originAddress!,
                            style: TextStyle(
                              fontSize: 16,
                              color: darkTheme ? Colors.lightGreen : Colors.green,
                            ),
                          ),
                        ),
                        ),
                    ],
                  ),
                  SizedBox(height: 20,),

                  Row(
                    children: [
                      Image.asset("images/destination.png",
                        width: 30,
                        height: 30,
                      ),

                      SizedBox(width: 10,),

                      Expanded(
                        child: Container(
                          child: Text(
                            widget.userRideRequestDetails!.destinationAddress!,
                            style: TextStyle(
                              fontSize: 16,
                              color: darkTheme ? Colors.lightGreen : Colors.green,
                            ),
                          ),
                        )
                        )
                    ],
                  )

                ],
              ),
              ),
              Divider(
                height: 2,
                thickness: 2,
                color: darkTheme ? Colors.lightGreen : Colors.green,
              ),

              //button for cancelling and accepting the ride request
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        audioPlayer.pause();
                        audioPlayer.stop();
                        audioPlayer = AssetsAudioPlayer();

                        Navigator.pop(context);
                      }, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        "cancel".toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      )
                      ),
                      SizedBox(width: 20,),

                      ElevatedButton(
                        onPressed: () {
                          audioPlayer.pause();
                          audioPlayer.stop();
                          audioPlayer = AssetsAudioPlayer();

                          acceptRideRequest(context);
                        }, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          "accept".toUpperCase(),
                          style: TextStyle(
                          fontSize: 15,
                          )
                        )
                        )
                  ],

                ),
                )
          ],
        ),
      ),
    );
  }

  acceptRideRequest(BuildContext context){
    FirebaseDatabase.instance.ref()
    .child("drivers")
    .child(firebaseAuth.currentUser!.uid)
    .child("newRideStatus")
    .once()
    .then((snap)
    {
      if(snap.snapshot.value == "idle"){
        FirebaseDatabase.instance.ref().child("drivers").child(firebaseAuth.currentUser!.uid).child("newRideStatus").set("accepted");

        AssistantMethods.pauseLiveLocationUpdates();

        //
        Navigator.push(context, MaterialPageRoute(builder: (c) => NewTripScreen(
          userRideRequestDetails: widget.userRideRequestDetails,
        )));
      }
      else{
        Fluttertoast.showToast(msg: "This Ride Request doesn't exist");
      }

    });
  }
}