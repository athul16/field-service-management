class AvailabilitySlot {
  final String id;
  final String workerId;
  final DateTime startAt;
  final DateTime endAt;

  const AvailabilitySlot({
    required this.id,
    required this.workerId,
    required this.startAt,
    required this.endAt,
  });

  factory AvailabilitySlot.fromMap(Map<String, dynamic> map) {
    return AvailabilitySlot(
      id: map['id'] as String,
      workerId: map['worker_id'] as String,
      startAt: DateTime.parse(map['start_at'] as String),
      endAt: DateTime.parse(map['end_at'] as String),
    );
  }
}
