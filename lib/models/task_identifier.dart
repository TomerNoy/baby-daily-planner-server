class TaskIdentifier {
  final String uuid;
  final String dueDate;
  final String updatedAt;

  TaskIdentifier({
    required this.uuid,
    required this.dueDate,
    required this.updatedAt,
  });

  factory TaskIdentifier.fromJson(Map<String, dynamic> json) {
    return TaskIdentifier(
        uuid: json['id'],
        dueDate: json['dueDate'],
        updatedAt: json['updatedAt']);
  }
}
