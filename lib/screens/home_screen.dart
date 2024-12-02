import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_transaction.dart';
import 'near_expired_debts_screen.dart';
import 'account_screen.dart';
import 'debt_details_screen.dart';
import 'debt_contacts_screen.dart';

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
          AccountScreen(),
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

  Stream<QuerySnapshot> get _debtsStream =>
      FirebaseFirestore.instance.collection('debts').snapshots();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarz Daftarcha'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          final debts = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DebtTransaction.fromMap(data);
          }).toList();

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
    final color = balance >= 0 ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Umumiy balans',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatNumber(balance)} so\'m',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<DebtTransaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'So\'nggi o\'zgarishlar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.isDebtGiven
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Icon(
                    transaction.isDebtGiven
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: transaction.isDebtGiven ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  transaction.personName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                ),
                trailing: Text(
                  '${transaction.isDebtGiven ? '+' : '-'}${_formatNumber(transaction.amount)} so\'m',
                  style: TextStyle(
                    color: transaction.isDebtGiven ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DebtDetailsScreen(
                        transaction: transaction,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
