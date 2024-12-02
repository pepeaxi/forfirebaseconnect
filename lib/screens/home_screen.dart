import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_transaction.dart';
import 'near_expired_debts_screen.dart';
import 'account_screen.dart';
import 'debt_details_screen.dart';
import 'debt_contacts_screen.dart';
import 'login_screen.dart'; // Import for currentUsername

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onNewDebtAdded() {
    setState(() {
      _selectedIndex = 0; // Go back to home page
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomePage(),
          NearExpiredDebtsScreen(),
          DebtContactsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Asosiy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Muddatlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Yangi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Stream<List<DebtTransaction>> get _debtsStream {
    if (currentUsername == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('debts')
        .doc(currentUsername)
        .collection('borrowing')
        .doc('debts')
        .collection('items')
        .orderBy('date', descending: true) // Sana bo'yicha tartiblash
        .snapshots()
        .asyncMap((borrowingSnapshot) async {
      final lendSnapshot = await FirebaseFirestore.instance
          .collection('debts')
          .doc(currentUsername)
          .collection('lend')
          .doc('debts')
          .collection('items')
          .orderBy('date', descending: true) // Sana bo'yicha tartiblash
          .get();

      final borrowingDebts = borrowingSnapshot.docs.map((doc) {
        final data = doc.data();
        return DebtTransaction.fromMap({...data, 'isDebtGiven': false});
      }).toList();

      final lendDebts = lendSnapshot.docs.map((doc) {
        final data = doc.data();
        return DebtTransaction.fromMap({...data, 'isDebtGiven': true});
      }).toList();

      return [...borrowingDebts, ...lendDebts];
    });
  }

  String _formatNumber(double number) {
    // Convert to integer since we're already using toStringAsFixed(0) everywhere
    int numberInt = number.round();
    String numStr = numberInt.abs().toString();
    String result = '';
    int count = 0;

    // Process digits from right to left
    for (int i = numStr.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) {
        result = ' $result';
      }
      result = numStr[i] + result;
      count++;
    }

    // Add negative sign if needed
    if (numberInt < 0) {
      result = '-$result';
    }

    return result;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarz Daftarcha'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<DebtTransaction>>(
        stream: _debtsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Xatolik yuz berdi'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final debts = snapshot.data ?? [];

          final givenDebts = debts.where((debt) => debt.isDebtGiven).toList();
          final takenDebts = debts.where((debt) => !debt.isDebtGiven).toList();

          final totalGiven =
              givenDebts.fold<double>(0, (sum, debt) => sum + debt.amount);
          final totalTaken =
              takenDebts.fold<double>(0, (sum, debt) => sum + debt.amount);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Qarz berganlarim',
                        amount: totalGiven.toStringAsFixed(0),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Qarz olganlarim',
                        amount: totalTaken.toStringAsFixed(0),
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTotalBalance(totalGiven - totalTaken),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildRecentTransactions(debts),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String amount,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatNumber(double.parse(amount))} so\'m',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalance(double balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Umumiy balans',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatNumber(balance)} so\'m',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: balance >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<DebtTransaction> debts) {
    // Oxirgi 5 ta tranzaksiyani olish
    final recentDebts = debts.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Oxirgi qarzlar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (recentDebts.isEmpty)
          const Center(
            child: Text('Qarzlar yo\'q'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentDebts.length,
            itemBuilder: (context, index) {
              final debt = recentDebts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        debt.isDebtGiven ? Colors.green[100] : Colors.red[100],
                    child: Icon(
                      debt.isDebtGiven
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: debt.isDebtGiven ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(debt.personName),
                  subtitle: Text(
                    '${debt.amount.toStringAsFixed(0)} so\'m\n${_formatDate(debt.date)}',
                  ),
                  trailing: Text(
                    debt.isDebtGiven ? 'Berildi' : 'Olindi',
                    style: TextStyle(
                      color: debt.isDebtGiven ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
