enum VisitStatus { scheduled, inProgress, completed }

class Visit {
  final String id;
  final String clientName;
  final VisitStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  List<String> completedTasks = [];

  Visit({
    required this.id,
    required this.clientName,
    this.status = VisitStatus.scheduled,
    this.checkInTime,
    this.checkOutTime,
    this.completedTasks = const [],
  });

  // Immutability: Create a new instance with updated fields
  Visit copyWith({
    VisitStatus? status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    List<String>? completedTasks,
  }) {
    return Visit(
      id: id,
      clientName: clientName,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }
}