class Areas {
  late String location;


  Areas({
    required this.location,

  });

  Map<String, dynamic> toMap() {
    return {
      'locations': location,
    };
  }

  factory Areas.fromMap(Map<String, dynamic> map) {
    return Areas(
      location: map['location'],
    );
  }
}
