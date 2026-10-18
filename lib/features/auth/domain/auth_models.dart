class Credentials {
  const Credentials({required this.email, required this.password});

  final String email;
  final String password;
}

class Registration {
  const Registration({
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;
}
