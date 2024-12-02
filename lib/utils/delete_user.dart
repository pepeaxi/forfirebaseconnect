import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteUser(String userId) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    print('User $userId deleted successfully from Firestore');
  } catch (e) {
    print('Error deleting user: $e');
  }
}
