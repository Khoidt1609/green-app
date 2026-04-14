import 'package:flutter/material.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/repositories/task_repository.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskRepository _repository = TaskRepository();

  Stream<List<TaskModel>> get taskStream => _repository.getActiveTasks();
}