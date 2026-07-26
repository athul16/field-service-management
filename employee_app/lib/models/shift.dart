class Shift {
  final String id;
  final String workerId;
  final String siteId;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final String? clockOutPhotoUrl;
  final String status; // in_progress | completed

  const Shift({
    required this.id,
    required this.workerId,
    required this.siteId,
    required this.clockInAt,
    this.clockOutAt,
    this.clockOutPhotoUrl,
    required this.status,
  });

  bool get isActive => status == 'in_progress';

  Duration? get workedDuration {
    if (clockOutAt == null) return null;
    return clockOutAt!.difference(clockInAt);
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] as String,
      workerId: map['worker_id'] as String,
      siteId: map['site_id'] as String,
      clockInAt: DateTime.parse(map['clock_in_at'] as String),
      clockOutAt: map['clock_out_at'] != null
          ? DateTime.parse(map['clock_out_at'] as String)
          : null,
      clockOutPhotoUrl: map['clock_out_photo_url'] as String?,
      status: map['status'] as String,
    );
  }
}
