import 'package:equatable/equatable.dart';

class Batch extends Equatable {
  final int id;
  final String name;

  const Batch({required this.id, required this.name});

  @override
  List<Object> get props => [id, name];
}

const sampleBatches = [
  Batch(id: 1, name: 'Batch A-001'),
  Batch(id: 2, name: 'Batch B-002'),
  Batch(id: 3, name: 'Batch C-003'),
];