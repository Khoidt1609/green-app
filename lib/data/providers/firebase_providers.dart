import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider quản lý instance của Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provider quản lý luồng dữ liệu thô từ collection 'tasks'
final rawTasksStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('tasks').where('isActive', isEqualTo: true).snapshots();
});