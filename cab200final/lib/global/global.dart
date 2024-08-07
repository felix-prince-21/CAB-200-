import 'package:cab200final/models/direction_details_info.dart';
import 'package:cab200final/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;

UserModel? userModelCurrentInfo;

String cloudMessagingServerToken = "key=AAAABtiQZP4:APA91bFTLZNNnLGIU6Cdl-75HQLFHUOP70LGJbCN_7kzGbzh3mFmS1F241dWxhdih3P02ih4k60mdxZdcq_m6lCX7YgqsnfAxUpic2oFGapKriffda3m4ebpOnJwFUVSQsqnkkBwArz_";
List driversList = [];
DirectionDetailsInfo? tripDirectionDetailsInfo;
String userDroffOffAddress = "";
String driverCarDetails = "";
String driverName = "";
String driverPhone= "";

double countRatingsStars = 0.0;
String titlesStarsRating = "";