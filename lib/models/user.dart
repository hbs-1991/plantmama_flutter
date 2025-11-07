class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String dateJoined;
  final String? token;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    required this.dateJoined,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      dateJoined: json['date_joined'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'address': address,
      'date_joined': dateJoined,
      if (token != null) 'token': token,
    };
  }
}

class AuthResponse {
  final String access;
  final String refresh;
  final User user;

  AuthResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phone;
  final String address;

  RegisterRequest({
    required this.email,
    required this.password,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.address = '',
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email,
      'password': password,
    };
    
    if (firstName.isNotEmpty) data['first_name'] = firstName;
    if (lastName.isNotEmpty) data['last_name'] = lastName;
    if (phone.isNotEmpty) data['phone'] = phone;
    if (address.isNotEmpty) data['address'] = address;
    
    return data;
  }
}