import 'package:cab200finaldriver/global/global.dart';
import 'package:cab200finaldriver/splashScreen/splash_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CarInfoScreen extends StatefulWidget {
  const CarInfoScreen({super.key});

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {

  final carModelTextEditingContoller = TextEditingController();
  final carNumberTextEditingController = TextEditingController();
  final carColorTextEditingController = TextEditingController();

  List<String> carTypes = ["Car", "TookTook", "Bike"];
  String? selectedCarType;

  final _formKey = GlobalKey<FormState>();

  _submit(){
    if(_formKey.currentState!.validate()){
      Map driverCarInfoMap = {
        "car_model": carModelTextEditingContoller.text.trim(),
        "car_number": carNumberTextEditingController.text.trim(),
        "car_color": carColorTextEditingController.text.trim(),
      };

      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("drivers");
            userRef.child(currentUser!.uid).child("car_details").set(driverCarInfoMap);

      Fluttertoast.showToast(msg: "Car details has been saved. Good job driver!");
          Navigator.push(context, MaterialPageRoute(builder: (c) => SplashScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.all(0),
          children: [
            Column(
              children: [
                Image.asset(darkTheme ? 'images/city_dark.png' : 'images/city.png'),

                SizedBox(height: 20,),
                Text(
                  "Add Car Details",
                  style: TextStyle(
                    color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50)
                              ],
                              decoration: InputDecoration(
                                hintText: "Car Model",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  borderSide: BorderSide(
                                    width: 0,
                                    style: BorderStyle.none
                                  )
                                ),
                                prefixIcon: Icon(Icons.person, color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.grey),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text){
                                if(text == null || text.isEmpty){
                                  return "Name can't be empty";
                                }
                                if(text.length < 2){
                                  return "Please enter a valid name";
                                }
                                if(text.length > 40){
                                  return " Name can't be more than 40";
                                }
                              },
                              onChanged: (text) => setState(() {
                                carModelTextEditingContoller.text = text;
                                
                              }),
                            ),
                            SizedBox(height: 20,),

                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50)
                              ],
                              decoration: InputDecoration(
                                hintText: "Car Number",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  borderSide: BorderSide(
                                    width: 0,
                                    style: BorderStyle.none
                                  )
                                ),
                                prefixIcon: Icon(Icons.person, color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.grey),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text){
                                if(text == null || text.isEmpty){
                                  return "Name can't be empty";
                                }
                                if(text.length < 2){
                                  return "Please enter a valid name";
                                }
                                if(text.length > 40){
                                  return " Name can't be more than 40";
                                }
                              },
                              onChanged: (text) => setState(() {
                                carNumberTextEditingController.text = text;
                                
                              }),
                            ),
                            
                            SizedBox(height: 20,),

                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50)
                              ],
                              decoration: InputDecoration(
                                hintText: "Car Color",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  borderSide: BorderSide(
                                    width: 0,
                                    style: BorderStyle.none
                                  )
                                ),
                                prefixIcon: Icon(Icons.person, color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.grey),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text){
                                if(text == null || text.isEmpty){
                                  return "Name can't be empty";
                                }
                                if(text.length < 2){
                                  return "Please enter a valid name";
                                }
                                if(text.length > 40){
                                  return " Name can't be more than 40";
                                }
                              },
                              onChanged: (text) => setState(() {
                                carColorTextEditingController.text = text;
                                
                              }),
                            ),

                            SizedBox(height: 20,),

                            DropdownButtonFormField(
                              decoration: InputDecoration(
                                hintText: "Please Choose Car type",
                                prefixIcon: Icon(Icons.car_crash, color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,),
                                filled: true,
                                fillColor: darkTheme? Colors.black45 : Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  borderSide: BorderSide(
                                    width: 0,
                                    style: BorderStyle.none,
                                  )
                                )
                              ),
                              items: carTypes.map((car){
                                return DropdownMenuItem(
                                  child: Text(
                                    car,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  value: car,
                                  );
                              }).toList(),
                              onChanged: (newValue){
                                setState(() {
                                  selectedCarType = newValue.toString();
                                });
                              }
                              ),

                              SizedBox(height: 20,),

                            ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: darkTheme ? Colors.black : Colors.white, 
                                    backgroundColor: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                              onPressed: () {
                                _submit();
                              }, 
                              child: Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              )
                              ),
                              SizedBox(height: 20,),

                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,
                                  ),

                                ),
                              ),

                              SizedBox(height: 20,),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already Have an Account?",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 5,),

                                  GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      "Sign In",
                                      style:TextStyle(
                                        fontSize: 15,
                                        color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green,
                                      ),
                                    ),
                                  )
                                ],
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      )
    );
  }
}