import 'package:cab200final/global/global.dart';
import 'package:cab200final/screens/main_screen.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field/intl_phone_field.dart';



class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final nameTextEditingController = TextEditingController();
  final emailTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();
  final passwordTextEditingController = TextEditingController();
  final confirmTextEditingController = TextEditingController();

  bool _passwordVisible = false;

  //declare a Globakey
  final _formKey = GlobalKey<FormState>();

  void _submit() async{
    //validate all the form fields
    if(_formKey.currentState!.validate()){
      await firebaseAuth.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(), 
        password: passwordTextEditingController.text.trim()
        ).then((auth)async {
          currentUser = auth.user;

          if(currentUser != null){
            Map userMap = {
              "id": currentUser!.uid,
              "name": nameTextEditingController.text.trim(),
              "email": emailTextEditingController.text.trim(),
              "address": addressTextEditingController.text.trim(),
              "phone": phoneTextEditingController.text.trim(),
            };
            DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
            userRef.child(currentUser!.uid).set(userMap);
          }
          await Fluttertoast.showToast(msg: "Successfully Registered");
          Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
          }).catchError((errorMessage){
            Fluttertoast.showToast(msg: "Error occured: \n $errorMessage");
          });
    }else{
      Fluttertoast.showToast(msg: "Not all fields are valid");
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
                Image.asset(darkTheme ? 'image/city_dark.png' : 'images/city.jpg'),

                SizedBox(height: 20,),
                Text(
                  'Register',
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
                                hintText: "Name",
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
                                nameTextEditingController.text = text;
                                
                              }),
                            ),
                            SizedBox(height: 10,),

                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(100)
                              ],
                              decoration: InputDecoration(
                                hintText: "Email",
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
                                  return "Email can't be empty";
                                }
                                if(EmailValidator.validate(text) == true){
                                  return null;
                                }
                                if(text.length < 2){
                                  return "Please enter a valid Email";
                                }
                                if(text.length > 89){
                                  return " Email can't be more than 40";
                                }
                              },
                              onChanged: (text) => setState(() {
                                emailTextEditingController.text = text;
                              }),
                            ),
                            SizedBox(height: 10,),

                            IntlPhoneField(
                                  showCountryFlag: false,
                                  dropdownIcon: Icon(
                                    Icons.arrow_drop_down,
                                    color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.grey,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Phone",
                                    hintStyle: TextStyle(
                                      color: Colors.grey
                                    ),
                                    filled: true,
                                    fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                    border: OutlineInputBorder(
                                      borderRadius:BorderRadius.circular(40),
                                      borderSide: BorderSide(
                                        width: 0,
                                        style: BorderStyle.none
                                      )
                                    ),
                                  ),
                                  initialCountryCode: 'GH',
                                  onChanged: (text) => setState(() {
                                    phoneTextEditingController.text = text.completeNumber;
                                  }),
                              ),
                              TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(100)
                              ],
                              decoration: InputDecoration(
                                hintText: "Address",
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
                                  return "Address can't be empty";
                                }
                                
                                if(text.length < 2){
                                  return "Please enter a valid address";
                                }
                                if(text.length > 89){
                                  return " Address can't be more than 40";
                                }
                              },
                              onChanged: (text) => setState(() {
                                addressTextEditingController.text = text;
                              }),
                            ),

                            SizedBox(height: 20,),

                            TextFormField(
                              obscureText: !_passwordVisible,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50)
                              ],
                              decoration: InputDecoration(
                                hintText: "Password",
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
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.grey,
                                  ),
                                  onPressed: () {
                                    //update the state i.e toggle the state of the passwordVisible variable
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                  ),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text){
                                if(text == null || text.isEmpty){
                                  return "Password can't be empty";
                                }
                                
                                if(text.length < 2){
                                  return "Please enter a valid Password";
                                }
                                if(text.length > 39){
                                  return " Password can't be more than 39";
                                }
                                return null;
                              },
                              onChanged: (text) => setState(() {
                                passwordTextEditingController.text = text;
                              }),
                            ),

                            SizedBox(height: 20,),

                            TextFormField(
                              obscureText: !_passwordVisible,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50)
                              ],
                              decoration: InputDecoration(
                                hintText: "Confirm Password",
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
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.grey,
                                  ),
                                  onPressed: () {
                                    //update the state i.e toggle the state of the passwordVisible variable
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                  ),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text){
                                if(text == null || text.isEmpty){
                                  return "Confirm Password can't be empty";
                                }
                                if(text != passwordTextEditingController.text){
                                  return "Password don't match";
                                }
                                if(text.length < 2){
                                  return "Please enter a valid Password";
                                }
                                if(text.length > 39){
                                  return " Password can't be more than 39";
                                }
                                return null;
                              },
                              onChanged: (text) => setState(() {
                                confirmTextEditingController.text = text;
                              }),
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
                                'Register',
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
        )

      ),
      );
  }
}