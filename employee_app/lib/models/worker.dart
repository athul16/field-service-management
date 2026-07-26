class Worker {
  final String id;
  final String fullName;
  final String phone;
  final String? email;

  const Worker({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
  });

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      if (email != null) 'email': email,
    };
  }
}
