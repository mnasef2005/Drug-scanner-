import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../api/elazaby_scraper.dart';
import '../data/database_helper.dart';
import '../data/models.dart';
import '../utils/invoice_generator.dart';

class PosScreen extends StatefulWidget {
  @override
  _PosScreenState createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Product> _cart = [];
  double _total = 0.0;
  bool _isLoading = false;
  Customer? _selectedCustomer;
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await DatabaseHelper.instance.getCustomers();
    setState(() {
      _customers = customers;
    });
  }

  Future<void> _scanBarcode() async {
    try {
      String barcodeResult = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'إلغاء', true, ScanMode.BARCODE);
      if (barcodeResult != '-1') {
        _addProductToCart(barcodeResult);
      }
    } catch (e) {
      _showSnackBar('خطأ في المسح: $e', isError: true);
    }
  }

  Future<void> _addProductToCart(String barcode) async {
    setState(() => _isLoading = true);
    Product? product;

    // 1. Check local DB first
    product = await DatabaseHelper.instance.getProduct(barcode);

    // 2. If not in DB, scrape from web
    if (product == null) {
      product = await ElazabyScraper.fetchDrugInfo(barcode);
      if (product != null) {
        // Save to our DB for future use
        await DatabaseHelper.instance.insertOrUpdateProduct(product);
      }
    }

    setState(() => _isLoading = false);

    if (product != null) {
      setState(() {
        // Check if product already in cart
        final index = _cart.indexWhere((p) => p.barcode == barcode);
        if (index != -1) {
          _cart[index].quantity++;
        } else {
          _cart.add(product);
        }
        _calculateTotal();
      });
    } else {
      _showSnackBar('لم يتم العثور على المنتج', isError: true);
    }
  }

  void _calculateTotal() {
    _total = _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
  
  void _clearCart(){
    setState(() {
      _cart.clear();
      _total = 0.0;
      _selectedCustomer = null;
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      _showSnackBar('السلة فارغة!', isError: true);
      return;
    }
    
    // Default to cash customer if none is selected
    final customerName = _selectedCustomer?.name ?? 'عميل نقدي';
    final customerId = _selectedCustomer?.id;
    final isPaid = _selectedCustomer?.hasCredit == true ? false : true;

    final newInvoice = Invoice(
      customerId: customerId,
      customerName: customerName,
      totalAmount: _total,
      date: DateTime.now(),
      isPaid: isPaid,
      items: List.from(_cart),
    );

    final invoiceId = await DatabaseHelper.instance.createInvoice(newInvoice);

    await InvoiceGenerator.generateAndPrintInvoice(
      Invoice(
        id: invoiceId,
        customerName: newInvoice.customerName,
        totalAmount: newInvoice.totalAmount,
        date: newInvoice.date,
        isPaid: newInvoice.isPaid,
        items: newInvoice.items,
      )
    );
    
    _showSnackBar('تم إنشاء الفاتورة بنجاح!');
    _clearCart();
  }


  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('نقطة البيع')),
      body: Column(
        children: [
          _buildCustomerSelector(),
          Expanded(
            child: _cart.isEmpty
                ? Center(child: Text('السلة فارغة. ابدأ بمسح باركود.'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (ctx, i) {
                      final item = _cart[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(item.quantity.toString())),
                        title: Text(item.name),
                        subtitle: Text('السعر: ${item.price.toStringAsFixed(2)}'),
                        trailing: Text('${(item.price * item.quantity).toStringAsFixed(2)} ج'),
                      );
                    },
                  ),
          ),
          if (_isLoading) LinearProgressIndicator(),
          _buildTotalCard(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanBarcode,
        label: Text('مسح'),
        icon: Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButtonFormField<Customer>(
        value: _selectedCustomer,
        hint: Text('اختر عميل (اختياري)'),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person),
          border: OutlineInputBorder(),
        ),
        items: _customers.map((Customer customer) {
          return DropdownMenuItem<Customer>(
            value: customer,
            child: Text(customer.name),
          );
        }).toList(),
        onChanged: (Customer? newValue) {
          setState(() {
            _selectedCustomer = newValue;
          });
        },
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الإجمالي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('${_total.toStringAsFixed(2)} جنيه',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkout,
                    icon: Icon(Icons.print),
                    label: Text('إتمام وطباعة فاتورة'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_sweep, color: Colors.red),
                  onPressed: _clearCart,
                  tooltip: 'إفراغ السلة',
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

