class PhoneCountry {
  final String iso2;
  final String name;
  final String dialCode;
  final int nationalLength;

  const PhoneCountry({
    required this.iso2,
    required this.name,
    required this.dialCode,
    required this.nationalLength,
  });

  factory PhoneCountry.fromMap(Map<String, dynamic> map) {
    return PhoneCountry(
      iso2: map['iso2'] as String,
      name: map['name'] as String,
      dialCode: map['dialCode'] as String,
      nationalLength: map['nationalLength'] as int,
    );
  }
}
