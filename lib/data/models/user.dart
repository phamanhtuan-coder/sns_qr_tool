import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String name;
  final String role;
  final String department;

  const User({required this.name, required this.role, required this.department});

  @override
  List<Object> get props => [name, role, department];
}