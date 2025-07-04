class Product {
  final String barcode;
  final String name;
  final double price;
  int quantity;

  Product({required this.barcode, required this.name, required this.price, this.quantity = 1});

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'price': price,
    };
  }
}

class Customer {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final bool hasCredit; // آجل

  Customer({this.id, required this.name, required this.phone, required this.address, required this.hasCredit});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'hasCredit': hasCredit ? 1 : 0,
    };
  }
}

class Invoice {
  final int? id;
  final int? customerId;
  final String customerName;
  final double totalAmount;
  final DateTime date;
  final bool isPaid;
  final List<Product> items;

  Invoice({
    this.id,
    this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.date,
    this.isPaid = true,
    required this.items,
  });
}
