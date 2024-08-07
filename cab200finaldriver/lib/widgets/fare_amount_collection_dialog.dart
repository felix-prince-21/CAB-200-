import 'package:cab200finaldriver/screens/main_screen.dart';
import 'package:flutter/material.dart';

class FareAmountCollectionDialog extends StatefulWidget {
  double totalFareAmount;

  FareAmountCollectionDialog({required this.totalFareAmount});

  @override
  State<FareAmountCollectionDialog> createState() => _FareAmountCollectionDialogState();
}

class _FareAmountCollectionDialogState extends State<FareAmountCollectionDialog> {
  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(6),
        width: double.infinity,
        decoration: BoxDecoration(
          color: darkTheme ? Colors.black : Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20,),

            Text(
              "Trip Fare Amount",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.lightGreen : Colors.black,
                fontSize: 20,
              ),
            ),

            Text(
              "GH₵" + widget.totalFareAmount.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.lightGreen : Colors.black,
                fontSize: 50,
              ),
            ),
            SizedBox(height: 10,),

            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Amount due from customer",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkTheme ? Colors.lightGreen : Colors.white,
                ),
              ),
              ),
              SizedBox(height: 10,),

              Padding(
                padding: EdgeInsets.all(8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.lightGreen : Colors.green,
                ),
                onPressed : (){
                  Future.delayed(Duration(milliseconds: 2000), (){
                    Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Collect Cash",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkTheme ? Colors.black : Colors.green,
                      ),
                    ),
                    Text(
                      "GH₵ " + widget.totalFareAmount.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        color: darkTheme ? Colors.black : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
                )
                )

          ],
        ),
      ),
    );
  }
}