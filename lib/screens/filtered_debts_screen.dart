import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_transaction.dart';
import 'debt_details_screen.dart';
import '../utils/number_formatter.dart';

class FilteredDebtsScreen extends StatelessWidget {
  final String title;
  final String debtType;
  final Color color;

  const FilteredDebtsScreen({
    super.key,
    required this.title,
    required this.debtType,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('debts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Xatolik yuz berdi: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final debts = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Type fieldi mavjud bo'lmasa, null qaytaramiz
            if (!data.containsKey('type')) return null;
            return DebtTransaction.fromMap(data);
          }).where((debt) {
            // null qiymatlarni va type fieldi mos kelmaganlarni o'tkazib yuboramiz
            if (debt == null) return false;
            return debtType == 'lend' ? debt.isDebtGiven : !debt.isDebtGiven;
          }).whereType<DebtTransaction>().toList();

          if (debts.isEmpty) {
            return Center(
              child: Text(
                debtType == 'lend' ? 'Qarz berganlar mavjud emas' : 'Qarz olganlar mavjud emas',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              final isLend = debt.isDebtGiven;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(
                      isLend ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color,
                    ),
                  ),
                  title: Text(
                    debt.personName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Summa: ${NumberFormatter.formatNumber(debt.amount)} so\'m',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Qaytarish sanasi: ${debt.returnDate.toString().split(' ')[0]}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: color),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DebtDetailsScreen(transaction: debt),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
