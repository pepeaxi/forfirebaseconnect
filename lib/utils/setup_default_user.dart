import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> setupDefaultUser() async {
  try {
    // Create user document in Firestore
    await FirebaseFirestore.instance.collection('users').doc('pepe').set({
      'username': 'pepe',
      'password': '123456',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('Default user created successfully in Firestore');
  } catch (e) {
    print('Error creating default user: $e');
  }
}
