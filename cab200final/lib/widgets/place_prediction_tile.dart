import 'package:cab200final/Assistants/request_asstant.dart';
import 'package:cab200final/global/global.dart';
import 'package:cab200final/global/map_key.dart';
import 'package:cab200final/infoHandler/app_info.dart';
import 'package:cab200final/models/directions.dart';
import 'package:cab200final/models/predicted_places.dart';
import 'package:cab200final/widgets/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlacePredictionTileDesign extends StatefulWidget {
  

  final PredictedPlaces? predictedPlaces;

  PlacePredictionTileDesign({this.predictedPlaces});

  @override
  State<PlacePredictionTileDesign> createState() => _PlacePredictionTileDesignState();
}

class _PlacePredictionTileDesignState extends State<PlacePredictionTileDesign> {

  getPlaceDirectionDetails(String ? placeId, context) async {
    showDialog(
      context: context, 
      builder: (BuildContext context) => ProgressDialog(
        message: "Setting up Drop-off, Hold on a sec...",
        
      )
      );

      String placeDirectionDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapkey";

      var responseApi = await RequestAssistant.receiveRequest(placeDirectionDetailsUrl);

      Navigator.pop(context);

      if(responseApi == "Error Occured. Failed. No Reponse."){
        return;
      }

      if(responseApi["status"] == "OK"){
        Directions directions = Directions();
        directions.locationName = responseApi["result"]["name"];
        directions.locationId = placeId;
        directions.locationLatitude = responseApi["result"]["geometry"]["location"]["lat"];
        directions.locationLongitude = responseApi["result"]["geometry"]["location"]["lng"];

        Provider.of<AppInfo>(context, listen: false).updateDropOffLocationAddress(directions);

        setState(() {
          userDroffOffAddress = directions.locationName!;
        });

        Navigator.pop(context, "obtainedDropoff");
      }

  }
  
  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return ElevatedButton(
      onPressed: () {
        getPlaceDirectionDetails(widget.predictedPlaces!.place_id, context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: darkTheme ? Colors.black : Colors.white,

      ),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              Icons.add_location,
              color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green
            ),

            SizedBox(width: 10,),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.predictedPlaces!.main_text!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green
                    ),
                  ),

                  Text(
                    widget.predictedPlaces!.secondary_text!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: darkTheme ? Color.fromARGB(255, 126, 161, 88) : Colors.green
                    ),
                  ),
                ],

              )
              ),
          ],
        ),
        ),
    );
  }
}