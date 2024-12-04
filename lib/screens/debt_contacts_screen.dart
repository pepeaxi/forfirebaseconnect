import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_transaction.dart';
import 'new_debt_screen.dart';
import 'login_screen.dart'; // currentUsername uchun

class DebtContactsScreen extends StatelessWidget {
  const DebtContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (currentUsername == null) {
      return const Center(child: Text('Foydalanuvchi topilmadi'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kontaktlar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('debts')
              .doc(currentUsername)
              .collection('borrowing')
              .doc('debts')
              .collection('items')
              .snapshots(),
          builder: (context, borrowingSnapshot) {
            if (borrowingSnapshot.hasError) {
              return Center(
                child: Text('Xatolik yuz berdi: ${borrowingSnapshot.error}'),
              );
            }

            if (borrowingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('debts')
                  .doc(currentUsername)
                  .collection('lend')
                  .doc('debts')
                  .collection('items')
                  .snapshots(),
              builder: (context, lendSnapshot) {
                if (lendSnapshot.hasError) {
                  return Center(
                    child: Text('Xatolik yuz berdi: ${lendSnapshot.error}'),
                  );
                }

                if (lendSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Borrowing va Lend ma'lumotlarini birlashtirish
                final allDebts = [
                  ...(borrowingSnapshot.data?.docs ?? []).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DebtTransaction.fromMap({
                      ...data,
                      'isOwed': true,
                    });
                  }),
                  ...(lendSnapshot.data?.docs ?? []).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DebtTransaction.fromMap({
                      ...data,
                      'isOwed': false,
                    });
                  }),
                ].whereType<DebtTransaction>().toList();

                // Remove duplicates based on personName
                final uniqueDebts = allDebts
                    .fold<Map<String, DebtTransaction>>(
                      {},
                      (map, debt) {
                        if (!map.containsKey(debt.personName)) {
                          map[debt.personName] = debt;
                        }
                        return map;
                      },
                    )
                    .values
                    .toList();

                if (uniqueDebts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Kontaktlar mavjud emas',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: uniqueDebts.length,
                  itemBuilder: (context, index) {
                    final debt = uniqueDebts[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.blue.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.only(
                                  left: 20, right: 20, top: 10),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  debt.personName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              title: Text(
                                debt.personName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, bottom: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NewDebtScreen(
                                            isOwed: false,
                                            personName: debt.personName,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Qarz berish',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NewDebtScreen(
                                            isOwed: true,
                                            personName: debt.personName,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Qarz olish',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 22),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              title: const Text(
                                                'Kontaktni o\'chirish',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              content: Text(
                                                '${debt.personName}ni o\'chirishni xohlaysizmi?',
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    'Bekor qilish',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    try {
                                                      // O'chirish borrowing va lend dan
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('debts')
                                                          .doc(currentUsername)
                                                          .collection(
                                                              'borrowing')
                                                          .doc('debts')
                                                          .collection('items')
                                                          .where('personName',
                                                              isEqualTo: debt
                                                                  .personName)
                                                          .get()
                                                          .then((snapshot) {
                                                        for (var doc
                                                            in snapshot.docs) {
                                                          doc.reference
                                                              .delete();
                                                        }
                                                      });

                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('debts')
                                                          .doc(currentUsername)
                                                          .collection('lend')
                                                          .doc('debts')
                                                          .collection('items')
                                                          .where('personName',
                                                              isEqualTo: debt
                                                                  .personName)
                                                          .get()
                                                          .then((snapshot) {
                                                        for (var doc
                                                            in snapshot.docs) {
                                                          doc.reference
                                                              .delete();
                                                        }
                                                      });

                                                      if (context.mounted) {
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                '${debt.personName} o\'chirildi'),
                                                            backgroundColor:
                                                                Colors.green,
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Xatolik yuz berdi: $e'),
                                                            backgroundColor:
                                                                Colors.red,
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  child:
                                                      const Text('O\'chirish'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewDebtScreen(isOwed: false),
            ),
          );
        },
        backgroundColor: Colors.blue,
        elevation: 4,
        child: const Icon(
          Icons.add,
          size: 28,
        ),
      ),
    );
  }
}
