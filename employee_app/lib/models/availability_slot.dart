class AvailabilitySlot {
  final String id;
  final DateTime startAt;
  final DateTime endAt;

  const AvailabilitySlot({
    required this.id,
    required this.startAt,
    required this.endAt,
  });

  factory AvailabilitySlot.fromMap(Map<String, dynamic> map) {
    return AvailabilitySlot(
      id: map['id'] as String,
      startAt: DateTime.parse(map['startAt'] as String),
      endAt: DateTime.parse(map['endAt'] as String),
    );
  }
}
