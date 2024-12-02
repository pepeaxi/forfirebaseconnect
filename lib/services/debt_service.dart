import 'package:cloud_firestore/cloud_firestore.dart';

class DebtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new borrowing debt
  Future<void> addBorrowingDebt({
    required String username,
    required Map<String, dynamic> debtData,
  }) async {
    try {
      // Create a reference to the user's borrowing collection
      final userDebtRef = _firestore
          .collection('debts')
          .doc(username)
          .collection('borrowing')
          .doc('debts');

      // Get current debts or create new if doesn't exist
      final docSnapshot = await userDebtRef.get();
      if (docSnapshot.exists) {
        List currentDebts = docSnapshot.data()?['debts'] ?? [];
        currentDebts.add(debtData);
        
        await userDebtRef.update({
          'debts': currentDebts,
        });
      } else {
        await userDebtRef.set({
          'debts': [debtData],
        });
      }
    } catch (e) {
      throw Exception('Failed to add borrowing debt: $e');
    }
  }

  // Add a new lending debt
  Future<void> addLendingDebt({
    required String username,
    required Map<String, dynamic> debtData,
  }) async {
    try {
      // Create a reference to the user's lending collection
      final userDebtRef = _firestore
          .collection('debts')
          .doc(username)
          .collection('lend')
          .doc('debts');

      // Get current debts or create new if doesn't exist
      final docSnapshot = await userDebtRef.get();
      if (docSnapshot.exists) {
        List currentDebts = docSnapshot.data()?['debts'] ?? [];
        currentDebts.add(debtData);
        
        await userDebtRef.update({
          'debts': currentDebts,
        });
      } else {
        await userDebtRef.set({
          'debts': [debtData],
        });
      }
    } catch (e) {
      throw Exception('Failed to add lending debt: $e');
    }
  }

  // Get user's borrowing debts
  Future<List> getBorrowingDebts(String username) async {
    try {
      final docSnapshot = await _firestore
          .collection('debts')
          .doc(username)
          .collection('borrowing')
          .doc('debts')
          .get();

      return docSnapshot.data()?['debts'] ?? [];
    } catch (e) {
      throw Exception('Failed to get borrowing debts: $e');
    }
  }

  // Get user's lending debts
  Future<List> getLendingDebts(String username) async {
    try {
      final docSnapshot = await _firestore
          .collection('debts')
          .doc(username)
          .collection('lend')
          .doc('debts')
          .get();

      return docSnapshot.data()?['debts'] ?? [];
    } catch (e) {
      throw Exception('Failed to get lending debts: $e');
    }
  }
}
