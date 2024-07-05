import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';
import 'package:http/http.dart' as http;

class RegisterMaps extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;

  RegisterMaps({required this.destinationLat, required this.destinationLng});

  @override
  _RegisterMapsState createState() => _RegisterMapsState();
}

class _RegisterMapsState extends State<RegisterMaps> {
  late TplMapsViewController _controller;
  double zoomLevel = 8;
  String textValue = "";
  Timer? timeHandle;
  int markerCount = 0;
  final String myKey = "\$2a\$10\$MprokxALtkDrv5YSG8iDqOB7SJ6QAuVItHxA8kqXLdMC4cgwTOL6a";
  double? currentLat;
  double? currentLng;

  // Variables to manage visibility of buttons
  bool isDroppinVisible = true;
  bool isMyLocationVisible = true;

  @override
  void dispose() {
    timeHandle?.cancel();
    super.dispose();
  }

  void textChanged(String val) {
    setState(() {
      textValue = val;
    });
    timeHandle?.cancel();
    timeHandle = Timer(Duration(seconds: 3), () {
      if (textValue.isNotEmpty) {
        print("Calling API Here: $textValue");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const String viewType = 'map';
    const Map<String, dynamic> creationParams = <String, dynamic>{};

    return Scaffold(
      body: Stack(
        children: [
          Container(
            child: TplMapsView(
              isShowBuildings: true,
              isZoomEnabled: true,
              showZoomControls: false,
              isTrafficEnabled: true,
              longClickMarkerEnable: false,
              mapMode: MapMode.NIGHT,
              enablePOIs: false,
              setMyLocationEnabled: true,
              myLocationButtonEnabled: true,
              showsCompass: true,
              allGesturesEnabled: true,
              tplMapsViewCreatedCallback: _callback,
              tPlMapsViewMarkerCallBack: _markerCallback,
            ),
          ),
          if (isDroppinVisible)
            GestureDetector(
              onTap: () {
                setState(() {
                  zoomLevel += 1;
                  isDroppinVisible = false;
                });
                _controller.setZoomFixedCenter(zoomLevel);
              },
              child: Center(
                child: Image.asset(
                  'assets/droppin.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          if (isMyLocationVisible)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (currentLat != null && currentLng != null) {
                          addPolyline(
                              currentLat!, currentLng!, widget.destinationLat,
                              widget.destinationLng);
                        }
                        setState(() {
                          isMyLocationVisible = false;
                          isDroppinVisible = false;
                        });
                      },
                      child: Image.asset(
                        'assets/mylocation.png',
                        width: 70,
                        height: 70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _markerCallback(String callback) {
    print(callback);
    final latLngIndex = callback.indexOf("LatLng:");
    if (latLngIndex != -1) {
      final latLngSubstring = callback.substring(latLngIndex + "LatLng:".length)
          .trim();
      final values = latLngSubstring.split(',');
      if (values.length >= 2) {
        final latitude = values[0].trim();
        final longitude = values[1].trim().split("}")[0];
        setState(() {
          currentLat = double.parse(latitude);
          currentLng = double.parse(longitude);
        });
        print("Latitude: $latitude, Longitude: $longitude");
      }
    }
  }

  void _callback(TplMapsViewController controller) {
    _controller = controller;
    _controller.setZoomEnabled(false);
    _controller.showBuildings(false);
    _controller.setTrafficEnabled(false);
    _controller.enablePOIs(false);
    _controller.setMyLocationEnabled(true);
    _controller.myLocationButtonEnabled(true);
    _controller.showsCompass(false);
    _controller.setMapMode(MapMode.DEFAULT);
    _controller.removeAllMarker();
  }

  void addPolyline(double currentLat, double currentLng, double destLat,
      double destLng) {
    final currentLatLng = "$currentLat;$currentLng";
    final destinationLatLng = ["$destLat;$destLng"];
    _controller.setPolyLines(
        currentLatLng, destinationLatLng, "#0000FF", 2, myKey);
  }

  void getSearchItemsbyName(String text) {
    final tPlSearchViewController = TPlSearchViewController(
      text,
      24.8607,
      67.0011,
          (retrieveItemsCallback) {
        final decodedResponse = json.decode(retrieveItemsCallback);
        final responseData = decodedResponse[0]['compound_address_parents'];
        setState(() {
          final lat = double.parse(decodedResponse[0]['lat']);
          final lng = double.parse(decodedResponse[0]['lng']);
          _controller.setCameraPositionAnimated(lat, lng, 14.0);
        });
      },
    );
    tPlSearchViewController.getSearchItems();
  }
}
