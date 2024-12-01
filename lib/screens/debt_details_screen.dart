import 'package:flutter/material.dart';
import '../models/debt_transaction.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/number_formatter.dart';

class DebtDetailsScreen extends StatefulWidget {
  final DebtTransaction transaction;

  const DebtDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<DebtDetailsScreen> createState() => _DebtDetailsScreenState();
}

class _DebtDetailsScreenState extends State<DebtDetailsScreen> {
  late double remainingAmount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    remainingAmount = widget.transaction.amount;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final telUrl = 'tel:$cleanNumber';

    try {
      if (await launcher.canLaunchUrl(Uri.parse(telUrl))) {
        await launcher.launchUrl(Uri.parse(telUrl));
      } else {
        throw 'Could not launch phone call';
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
    }
  }

  void _showPartialPaymentDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Qismni to\'lash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'To\'lov miqdori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Noto\'g\'ri miqdor kiritildi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (amount > remainingAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kiritilgan miqdor qarzdan ko\'p'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _updateDebtAmount(remainingAmount - amount);
            },
            child: const Text('To\'lash'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDebtAmount(double newAmount) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (newAmount <= 0) {
        // Delete the debt if it's fully paid
        await FirebaseFirestore.instance
            .collection('debts')
            .doc(widget.transaction.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Qarz to\'liq to\'landi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Return to previous screen
        }
      } else {
        // Update the debt amount if not fully paid
        await FirebaseFirestore.instance
            .collection('debts')
            .doc(widget.transaction.id)
            .update({
          'amount': newAmount,
        });

        setState(() {
          remainingAmount = newAmount;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${NumberFormatter.formatNumber(remainingAmount - newAmount)} so\'m to\'landi. Qolgan qarz: ${NumberFormatter.formatNumber(newAmount)} so\'m',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xatolik yuz berdi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final text = Text(
      value,
      style: TextStyle(
        fontSize: 16,
        color: valueColor,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: onTap != null
                ? InkWell(
                    onTap: onTap,
                    child: text,
                  )
                : text,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qarzga olingan narsalar:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.transaction.items.length,
          itemBuilder: (context, index) {
            final item = widget.transaction.items[index];
            return Card(
              child: ListTile(
                title: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  '${NumberFormatter.formatNumber(item.price)} so\'m',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarz tafsilotlari'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.transaction.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.transaction.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Shaxs ma\'lumotlari',
                  children: [
                    _buildInfoRow('Ism:', widget.transaction.personName),
                    _buildInfoRow(
                      'Telefon:',
                      widget.transaction.phoneNumber,
                      valueColor: Colors.blue,
                      onTap: () =>
                          _makePhoneCall(widget.transaction.phoneNumber),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Qarz ma\'lumotlari',
                  children: [
                    _buildInfoRow(
                      'Holat:',
                      widget.transaction.isDebtGiven ? 'Berilgan' : 'Olingan',
                      valueColor: widget.transaction.isDebtGiven
                          ? Colors.green
                          : Colors.red,
                    ),
                    _buildInfoRow(
                      'Miqdor:',
                      '${NumberFormatter.formatNumber(remainingAmount)} so\'m',
                      valueColor: widget.transaction.isDebtGiven
                          ? Colors.green
                          : Colors.red,
                    ),
                    _buildInfoRow(
                      'Sana:',
                      '${widget.transaction.date.day}/${widget.transaction.date.month}/${widget.transaction.date.year}',
                    ),
                    _buildInfoRow(
                      'Qaytarish sanasi:',
                      '${widget.transaction.returnDate.day}/${widget.transaction.returnDate.month}/${widget.transaction.returnDate.year}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildItemsList(),
                if (widget.transaction.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Izoh',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.transaction.description!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _makePhoneCall(widget.transaction.phoneNumber),
                        icon: const Icon(Icons.phone),
                        label: const Text('Qo\'ng\'iroq'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: remainingAmount > 0
                            ? () => _updateDebtAmount(0)
                            : null,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('To\'landi'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        remainingAmount > 0 ? _showPartialPaymentDialog : null,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Qismni to\'lash'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
