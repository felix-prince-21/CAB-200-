import 'package:cab200finaldriver/global/global.dart';
import 'package:cab200finaldriver/screens/profile_screen.dart';
import 'package:cab200finaldriver/splashScreen/splash_screen.dart';
import 'package:flutter/material.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      child: Drawer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(30, 50, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen, 
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20,),
                  Text(
                    userModelCurrentInfo!.name!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  SizedBox(height: 10,),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => ProfileScreen()));
                    },
                    child: Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    )
                  ),

                  SizedBox(height: 30,),

                  Text("Your trips",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 15,),

                  Text("Payment",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 15,),

                  Text("Notification",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 15,),

                  Text("Promos",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 15,),

                  Text("Help",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 15,),

                  Text("Free trips",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 15,),
                ],
              ), 

              GestureDetector(
                onTap: () {
                  firebaseAuth.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c) => SplashScreen()));


                },child: Text(
                  "Logout",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              )
            ],
            ),
          ),
      )
    );
  }
}