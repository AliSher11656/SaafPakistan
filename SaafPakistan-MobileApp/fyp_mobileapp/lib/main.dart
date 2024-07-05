import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fyp/Customer/Login.dart';
import 'package:decimal/decimal.dart';

class ScheduleProvider extends ChangeNotifier {
  late List<ScheduleItem> _items;

  ScheduleProvider() {
    _items = [];
    fetchRecyclablesFromDatabase();
  }

  List<ScheduleItem> get items => _items;

  void increaseQuantity(int index) {
    _items[index].quantity += Decimal.parse('0.1');
    notifyListeners();
  }

  void decreaseQuantity(int index) {
    if (_items[index].quantity > Decimal.zero) {
      _items[index].quantity -= Decimal.parse('0.1');
      notifyListeners();
    }
  }

  double calculateTotalQuantity() {
    return _items.fold(Decimal.zero, (total, item) => total + item.quantity).toDouble();
  }

  double calculateTotalPrice() {
    return _items.fold(Decimal.zero, (total, item) => total + (item.quantity * Decimal.parse(item.price.toString()))).toDouble();
  }

  void resetQuantities() {
    for (var item in _items) {
      item.quantity = Decimal.zero;
    }
    notifyListeners();
  }

  void fetchRecyclablesFromDatabase() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('recyclables').get();

      _items = querySnapshot.docs.map((doc) {
        return ScheduleItem(
          itemName: doc['item'],
          price: doc['price'].toDouble(), // Assuming price is stored as double in Firestore
          quantity: Decimal.zero,
        );
      }).toList();

      notifyListeners();
    } catch (error) {
      print('Error fetching recyclables: $error');
    }
  }
}

class ScheduleItem {
  final String itemName;
  final double price;
  Decimal quantity;

  ScheduleItem({
    required this.itemName,
    required this.price,
    required Decimal quantity,
  }) : this.quantity = quantity;
}

class RiderOrderProvider extends ChangeNotifier {
  late List<RecyclableItem> _recyclableItems;

  RiderOrderProvider() {
    _recyclableItems = [];
  }

  List<RecyclableItem> get recyclableItems => _recyclableItems;

  void addRecyclableItem(RecyclableItem item) {
    _recyclableItems.add(item);
    notifyListeners();
  }

  void removeRecyclableItem(int index) {
    _recyclableItems.removeAt(index);
    notifyListeners();
  }

  double calculateTotalPrice() {
    return _recyclableItems.fold(0.0, (total, item) => total + item.totalPrice);
  }
}

class RecyclableItem {
  final String itemName;
  final int quantity;
  final double totalPrice;

  RecyclableItem({
    required this.itemName,
    required this.quantity,
    required this.totalPrice,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: const FirebaseOptions(
    apiKey: 'AIzaSyBqsHkst-BFg6HXCWhXr6ai0lQLBPg1u0E', // Add your API key
    appId: '1:355966022483:android:7b6a97a29b4f0ed3dca7a6', // Add your App ID
    projectId: 'saafpakistan123', // Add your Project ID
    messagingSenderId: '', // Add your Sender ID if needed
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ScheduleProvider()),
        ChangeNotifierProvider(create: (context) => RiderOrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CLogin(), // Make sure this points to a valid login screen
    );
  }
}
