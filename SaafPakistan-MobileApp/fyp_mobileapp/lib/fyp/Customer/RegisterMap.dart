import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';
import 'package:http/http.dart' as http;

class Maps extends StatefulWidget {
  final Function(String, String, String) onAddressSelected;

  const Maps({required this.onAddressSelected, Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

late TplMapsViewController _controller;
double zoomLevel = 8;

class _MyAppState extends State<Maps> {
  String textValue = "";
  Timer timeHandle = Timer(Duration(seconds: 3), () {});
  int markerCount = 0;
  String myKey = "\$2a\$10\$MprokxALtkDrv5YSG8iDqOB7SJ6QAuVItHxA8kqXLdMC4cgwTOL6a";
  String address = '';

  void textChanged(String val) {
    textValue = val;
    if (timeHandle != null) {
      timeHandle.cancel();
    }
    timeHandle = Timer(Duration(seconds: 3), () {
      if (textValue != "") {
        print("Calling API Here: $textValue");
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    timeHandle.cancel();
  }

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
          GestureDetector(
            onTap: () {
              zoomLevel += 1;
              _controller.setZoomFixedCenter(zoomLevel);
            },
            child: Center(
              child: Container(
                child: Image.asset(
                  'assets/droppin.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 5,
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Address: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              // Your style for the address text goes here
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: TextField(
                  onSubmitted: (String value) {
                    getSearchItemsbyName(value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _markerCallback(String callback) {
    print(callback);

    int latLngIndex = callback.indexOf("LatLng:");

    if (latLngIndex != -1) {
      String latLngSubstring = callback.substring(latLngIndex + "LatLng:".length).trim();
      List<String> values = latLngSubstring.split(',');

      if (values.length >= 2) {
        String latitude = values[0].trim();
        String longitude = values[1].trim();

        print("Latitude: $latitude, Longitude: $longitude");

        postData(latitude + ";" + longitude.split("}")[0]);
      }
    }
  }

  void _callback(TplMapsViewController controller) {
    controller.setZoomEnabled(false);
    controller.showBuildings(false);
    controller.setTrafficEnabled(false);
    controller.enablePOIs(false);
    controller.setMyLocationEnabled(true);
    controller.myLocationButtonEnabled(true);
    controller.showsCompass(false);

    controller.setMapMode(MapMode.DEFAULT);
    bool isBuildingsEnabled = controller.isBuildingEnabled;
    print("isBuildingsEnabled: $isBuildingsEnabled");
    bool isTrafficEnabled = controller.isTrafficEnabled;
    print("isTrafficEnabled: $isTrafficEnabled");
    bool isPOIsEnabled = controller.isPOIsEnabled;
    print("isPOIsEnabled: $isPOIsEnabled");

    _controller = controller;

    _controller.removeAllMarker();
  }

  void addCircle() {
    _controller.addCircle(23.23, 23.23, 23.23);
  }

  void removeCircles() {
    _controller.removeAllCircles();
  }

  void getSearchItemsbyName(String text) {
    TPlSearchViewController tPlSearchViewController = TPlSearchViewController(
      text,
      24.8607,
      67.0011,
          (retrieveItemsCallback) {
        print(retrieveItemsCallback);

        List<dynamic> decodedResponse = json.decode(retrieveItemsCallback);

        var responseData = decodedResponse[0]['compound_address_parents'];
        setState(() {
          print(decodedResponse[0]['lat']);
          print(decodedResponse[0]['lng']);
          address = responseData;
          _controller.setCameraPositionAnimated(
              double.parse(decodedResponse[0]['lat']),
              double.parse(decodedResponse[0]['lng']),
              14.0);
        });
      },
    );

    tPlSearchViewController.getSearchItems();
  }

  Future<void> postData(String latlng) async {
    final apiUrl = 'https://api1.tplmaps.com:8888/search/rgeocodebulk?addressCount=1&apikey=${myKey}';
    List<Map<String, dynamic>> dataArray = [
      {'point': latlng},
    ];
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(dataArray),
      );

      if (response.statusCode == 200) {
        List<dynamic> decodedResponse = json.decode(response.body);
        var responseData = decodedResponse[0]['responseData'];
        String compoundAddressParents = responseData['1']['compound_address_parents'];

        setState(() {
          address = compoundAddressParents;
        });

        widget.onAddressSelected(address, latlng.split(';')[0], latlng.split(';')[1]);
      } else {
        print('Failed to post data: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }
}
