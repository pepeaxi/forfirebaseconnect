import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> setupAdminUser() async {
  try {
    // Create admin user document in Firestore
    await FirebaseFirestore.instance.collection('users').doc('admin').set({
      'username': 'admin',
      'password': 'admin123',
      'type': 'admin',
      'Phonenumber': '1234567890',
      'Namesurname': 'System Admin',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('Admin user created successfully in Firestore');
  } catch (e) {
    print('Error creating admin user: $e');
  }
}
