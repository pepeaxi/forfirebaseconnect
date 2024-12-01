class DebtItem {
  final String name;
  final double price;

  DebtItem({
    required this.name,
    required this.price,
  });

  factory DebtItem.fromMap(Map<String, dynamic> map) {
    return DebtItem(
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }
}

class DebtTransaction {
  final String id;
  final String personName;
  final String phoneNumber;
  final double amount;
  final bool isDebtGiven;
  final DateTime date;
  final String? imageUrl;
  final String? description;
  final DateTime returnDate;
  final List<DebtItem> items;

  DebtTransaction({
    required this.id,
    required this.personName,
    required this.phoneNumber,
    required this.amount,
    required this.isDebtGiven,
    required this.date,
    required this.returnDate,
    this.imageUrl,
    this.description,
    List<DebtItem>? items,
  }) : items = items ?? [];

  // Convert from Map (e.g., from Firebase)
  factory DebtTransaction.fromMap(Map<String, dynamic> map) {
    return DebtTransaction(
      id: map['id'] as String,
      personName: map['personName'] as String,
      phoneNumber: map['phoneNumber'] as String,
      amount: (map['amount'] as num).toDouble(),
      isDebtGiven: map['isDebtGiven'] as bool,
      date: DateTime.parse(map['date'] as String),
      returnDate: DateTime.parse(map['returnDate'] as String),
      imageUrl: map['imageUrl'] as String?,
      description: map['description'] as String?,
      items: map['items'] != null
          ? (map['items'] as List<dynamic>)
              .map((item) => DebtItem.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  // Convert to Map (e.g., for Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'isDebtGiven': isDebtGiven,
      'date': date.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'imageUrl': imageUrl,
      'description': description,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}
