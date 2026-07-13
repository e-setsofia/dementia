class PatientInfo {
  const PatientInfo({
    this.name = '',
    this.age = 0,
    this.condition = '',
    this.bloodGroup = '',
  });

  final String name;
  final int age;
  final String condition;
  final String bloodGroup;

  factory PatientInfo.fromMap(String id, Map<String, dynamic> data) {
    return PatientInfo(
      name: data['name'] as String? ?? '',
      age: data['age'] as int? ?? 0,
      condition: data['condition'] as String? ?? '',
      bloodGroup: data['bloodGroup'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'condition': condition,
      'bloodGroup': bloodGroup,
    };
  }

  PatientInfo copyWith({
    String? name,
    int? age,
    String? condition,
    String? bloodGroup,
  }) {
    return PatientInfo(
      name: name ?? this.name,
      age: age ?? this.age,
      condition: condition ?? this.condition,
      bloodGroup: bloodGroup ?? this.bloodGroup,
    );
  }
}
