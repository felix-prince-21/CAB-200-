import 'package:cab200final/screens/main_screen.dart';
import 'package:flutter/material.dart';

class PayFarAmountDialog extends StatefulWidget {

  double? fareAmount;

  PayFarAmountDialog({this.fareAmount});

  @override
  State<PayFarAmountDialog> createState() => _PayFarAmountDialogState();
}

class _PayFarAmountDialogState extends State<PayFarAmountDialog> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: darkTheme ? Colors.lightGreen : Colors.green,
          borderRadius: BorderRadius.circular(10)
        ),
        child: Column(
          children: [

            SizedBox(height: 20,),

            Text("Fare Amount".toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 15,
            ),
            ),
            SizedBox(height: 20,),

            Divider(
              thickness: 2,
              color: Colors.black54
            ),

            SizedBox(height: 10,),

            Text(
              "GH₵"+widget.fareAmount.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 50,
              ),
            ),

            SizedBox(height: 10,),

            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "This is the total trip fare amount. Please pay it to the driver",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black
                ),
              ),
              ),

              SizedBox(height: 10,),

              Padding(
                padding: EdgeInsets.all(20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87
                  ),
                  onPressed: () {
                    Future.delayed(Duration(milliseconds: 10000), (){
                      Navigator.pop(context, "Cash Paid");
                      Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
                    });
                  }, 
                  child: Row(
                    children: [
                      Text(
                        "Pay Cash  ",
                        style: TextStyle(
                          fontSize: 20,
                          color: darkTheme ? Colors.green : Colors. white ,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                      Text(
                        "  GH₵"+widget.fareAmount.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 20,
                          color: darkTheme ? Colors.green : Colors. white ,
                        ),
                      )
                    ],
                  )
                  
                  ),
                )


          ],
        ),
      ),


    );
  }
}