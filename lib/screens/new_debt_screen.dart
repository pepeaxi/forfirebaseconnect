import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../utils/number_formatter.dart';

class NewDebtScreen extends StatefulWidget {
  final bool isOwed;
  final String? personName;
  const NewDebtScreen({
    super.key,
    required this.isOwed,
    this.personName,
  });

  @override
  State<NewDebtScreen> createState() => _NewDebtScreenState();
}

class _NewDebtScreenState extends State<NewDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  DateTime _givenDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 7));
  bool _isDebtGiven = true;
  bool _isSaving = false;
  File? _imageFile;
  final _imagePicker = ImagePicker();
  List<DebtItem> _debtItems = [];

  @override
  void initState() {
    super.initState();
    _isDebtGiven = widget.isOwed;
    _givenDate = DateTime.now();
    _returnDate = DateTime.now().add(const Duration(days: 7));
    _debtItems = [];
    if (widget.personName != null) {
      _nameController.text = widget.personName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isGivenDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isGivenDate ? _givenDate : _returnDate,
      firstDate: isGivenDate ? DateTime(2020) : _givenDate,
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        if (isGivenDate) {
          _givenDate = picked;
          // Update return date if it's before given date
          if (_returnDate.isBefore(_givenDate)) {
            _returnDate = _givenDate.add(const Duration(days: 7));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  void _addItem() {
    if (_itemNameController.text.isEmpty || _itemPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomi va narxini kiriting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final price =
        double.tryParse(_itemPriceController.text.replaceAll(',', ''));

    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Narx raqam bo\'lishi kerak'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _debtItems.add(DebtItem(
        name: _itemNameController.text.trim(),
        price: price,
      ));

      // Clear item input fields
      _itemNameController.clear();
      _itemPriceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _debtItems.removeAt(index);
    });
  }

  Widget _buildItemInput() {
    return Card(
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
                  Icons.shopping_bag_outlined,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Qarz ma\'lumotlari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nomi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _itemPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Narxi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Qo\'shish'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            if (_debtItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Qarzga olingan narsalar:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nomi')),
                      DataColumn(label: Text('Narxi')),
                      DataColumn(label: Text('Amal')),
                    ],
                    rows: _debtItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text(item.name)),
                          DataCell(
                              Text('${NumberFormatter.formatNumber(item.price)} so\'m')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Jami summa: ${NumberFormatter.formatNumber(_calculateTotal())} so\'m',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _debtItems) {
      total += item.price;
    }
    return total;
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_debtItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamida bitta mahsulot kiriting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String? imageUrl;
    try {
      // Upload image if selected
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('debt_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Convert items to a list of maps
      final itemsList = _debtItems
          .map((item) => {
                'name': item.name,
                'price': item.price,
              })
          .toList();

      // Create debt transaction
      final Map<String, dynamic> debtData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'personName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'amount': _calculateTotal(),
        'isDebtGiven': _isDebtGiven,
        'date': _givenDate.toIso8601String(),
        'returnDate': _returnDate.toIso8601String(),
        'imageUrl': imageUrl,
        'description': _reasonController.text.trim(),
        'items': itemsList,
        'type': _isDebtGiven ? 'lend' : 'borrowing',
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('debts')
          .doc(debtData['id'])
          .set(debtData);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        Navigator.of(context).pushReplacementNamed('/home');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDebtGiven ? 'Qarz berish saqlandi' : 'Qarz olish saqlandi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If saving is in progress, prevent navigation
        if (_isSaving) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isDebtGiven ? 'Qarz berish' : 'Qarz olish'),
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveDebt,
              ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isDebtGiven = true),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isDebtGiven
                                      ? Colors.blue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Qarz berish',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isDebtGiven
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isDebtGiven = false),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: !_isDebtGiven
                                      ? Colors.blue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Qarz olish',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isDebtGiven
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Rasm qo\'shish',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ism',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Iltimos, ismni kiriting';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon raqam',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Iltimos, telefon raqamni kiriting';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Berilgan sana',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                '${_givenDate.day}/${_givenDate.month}/${_givenDate.year}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Qaytarish sanasi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.event_repeat),
                              ),
                              child: Text(
                                '${_returnDate.day}/${_returnDate.month}/${_returnDate.year}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Qarz sababi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    _buildItemInput(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (_isSaving)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DebtItem {
  final String name;
  final double price;

  DebtItem({required this.name, required this.price});
}
