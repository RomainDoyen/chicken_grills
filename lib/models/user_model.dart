class User {
  final String email;
  final String password;
  final String lastName;
  final String firstName;
  final String numSiret;
  final String numTel;
  final String? address;
  final String? description;
  final String role;

  User({
    required this.email,
    required this.password,
    required this.lastName,
    required this.firstName,
    required this.numSiret,
    required this.numTel,
    this.address,
    this.description,
    this.role = "pro",
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "passwordMd5": password,
      "lastName": lastName,
      "firstName": firstName,
      "numSiret": numSiret,
      "numTel": numTel,
      "address": address,
      "description": description,
      "role": role,
    };
  }

  final Map<String, bool> publicInfo = {
    'name': true,
    'phone': true,
    'description': true,
    'address': true,
    'email': false,
    'siret': false,
  };
}
