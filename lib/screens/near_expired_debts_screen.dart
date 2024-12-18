import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'debt_details_screen.dart';
import '../models/debt_transaction.dart';

class NearExpiredDebtsScreen extends StatelessWidget {
  const NearExpiredDebtsScreen({super.key});

  Stream<List<DebtTransaction>> _getDebts({required bool isExpired}) {
    final now = DateTime.now();
    return FirebaseFirestore.instance
        .collection('debts')
        .snapshots()
        .map((snapshot) {
      final List<DebtTransaction> transactions = [];

      for (var doc in snapshot.docs) {
        try {
          // Get the document data
          final userData = doc.data();

          // Process borrowing debts
          final borrowingData = (userData['borrowing']
              as Map<String, dynamic>?)?['debts'] as Map<String, dynamic>?;
          if (borrowingData != null) {
            borrowingData.forEach((debtId, debtData) {
              if (debtData is Map<String, dynamic>) {
                try {
                  final transaction = DebtTransaction(
                    id: debtId,
                    personName: debtData['personName'] as String? ?? '',
                    phoneNumber: debtData['phoneNumber'] as String? ?? '',
                    amount: (debtData['amount'] as num?)?.toDouble() ?? 0.0,
                    isDebtGiven: false,
                    date: DateTime.parse(debtData['date'] as String? ??
                        DateTime.now().toIso8601String()),
                    returnDate: DateTime.parse(
                        debtData['returnDate'] as String? ??
                            DateTime.now().toIso8601String()),
                    description: debtData['description'] as String?,
                    imageUrl: debtData['imageUrl'] as String?,
                  );

                  final daysUntilDue =
                      transaction.returnDate.difference(now).inDays;

                  if (transaction.amount > 0) {
                    if (isExpired && daysUntilDue < 0) {
                      transactions.add(transaction);
                    } else if (!isExpired &&
                        daysUntilDue >= 0 &&
                        daysUntilDue <= 3) {
                      transactions.add(transaction);
                    }
                  }
                } catch (e) {
                  debugPrint('Error parsing borrowing debt: $e');
                }
              }
            });
          }

          // Process lending debts
          final lendingData = (userData['lend']
              as Map<String, dynamic>?)?['debts'] as Map<String, dynamic>?;
          if (lendingData != null) {
            lendingData.forEach((debtId, debtData) {
              if (debtData is Map<String, dynamic>) {
                try {
                  final transaction = DebtTransaction(
                    id: debtId,
                    personName: debtData['personName'] as String? ?? '',
                    phoneNumber: debtData['phoneNumber'] as String? ?? '',
                    amount: (debtData['amount'] as num?)?.toDouble() ?? 0.0,
                    isDebtGiven: true,
                    date: DateTime.parse(debtData['date'] as String? ??
                        DateTime.now().toIso8601String()),
                    returnDate: DateTime.parse(
                        debtData['returnDate'] as String? ??
                            DateTime.now().toIso8601String()),
                    description: debtData['description'] as String?,
                    imageUrl: debtData['imageUrl'] as String?,
                  );

                  final daysUntilDue =
                      transaction.returnDate.difference(now).inDays;

                  if (transaction.amount > 0) {
                    if (isExpired && daysUntilDue < 0) {
                      transactions.add(transaction);
                    } else if (!isExpired &&
                        daysUntilDue >= 0 &&
                        daysUntilDue <= 3) {
                      transactions.add(transaction);
                    }
                  }
                } catch (e) {
                  debugPrint('Error parsing lending debt: $e');
                }
              }
            });
          }
        } catch (e) {
          debugPrint('Error processing document ${doc.id}: $e');
        }
      }

      // Sort transactions by return date
      transactions.sort((a, b) => a.returnDate.compareTo(b.returnDate));
      return transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Muddatlar'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Yaqin muddatlar'),
              Tab(text: 'O\'tgan muddatlar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDebtList(isExpired: false),
            _buildDebtList(isExpired: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtList({required bool isExpired}) {
    final Color color = isExpired ? Colors.red : Colors.orange;

    return StreamBuilder<List<DebtTransaction>>(
      stream: _getDebts(isExpired: isExpired),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Error loading debts: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Xatolik yuz berdi\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Force rebuild
                    DefaultTabController.of(context).animateTo(
                      DefaultTabController.of(context).index,
                    );
                  },
                  child: const Text('Qayta urinish'),
                ),
              ],
            ),
          );
        }

        final debts = snapshot.data ?? [];

        if (debts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isExpired ? Icons.check_circle : Icons.access_time,
                  size: 48,
                  color: color.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  isExpired
                      ? 'O\'tgan muddatli qarzlar yo\'q'
                      : 'Yaqin muddatli qarzlar yo\'q',
                  style: TextStyle(
                    fontSize: 16,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: debts.length,
          itemBuilder: (context, index) {
            final debt = debts[index];
            final daysUntilDue =
                debt.returnDate.difference(DateTime.now()).inDays;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DebtDetailsScreen(
                      transaction: debt,
                    ),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: color.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            child: Text(
                              debt.personName[0].toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  debt.personName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isExpired
                                          ? Icons.warning
                                          : Icons.access_time,
                                      size: 16,
                                      color: color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isExpired
                                          ? '${-daysUntilDue} kun kechikdi'
                                          : '$daysUntilDue kun qoldi',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${debt.amount.toStringAsFixed(0)} so\'m',
                                style: TextStyle(
                                  color: debt.isDebtGiven
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                debt.isDebtGiven ? 'Berilgan' : 'Olingan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (debt.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text(
                          debt.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
