import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import '../data/database_helper.dart';
import '../data/models.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cashController = TextEditingController();
  double _startCash = 0.0;
  bool _shiftActive = false;

  Future<void> _importFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      int count = 0;
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        // Skip header row (assuming it's the first row)
        for (int i = 1; i < sheet.maxRows; i++) {
          var row = sheet.row(i);
          if (row.length >= 3) {
            final barcode = row[0]?.value?.toString() ?? '';
            final name = row[1]?.value?.toString() ?? '';
            final price = double.tryParse(row[2]?.value?.toString() ?? '0.0') ?? 0.0;
            
            if(barcode.isNotEmpty && name.isNotEmpty){
                final product = Product(barcode: barcode, name: name, price: price);
                await DatabaseHelper.instance.insertOrUpdateProduct(product);
                count++;
            }
          }
        }
      }
      _showSnackBar('$count تم استيراد وتحديث المنتجات بنجاح');
    } else {
      _showSnackBar('تم إلغاء اختيار الملف', isError: true);
    }
  }

  void _startShift() {
    final cash = double.tryParse(_cashController.text) ?? 0.0;
    setState(() {
        _startCash = cash;
        _shiftActive = true;
    });
    _showSnackBar('تم بدء الوردية بنقدية: $_startCash جنيه');
  }

  Future<void> _endShift() async {
    final invoices = await DatabaseHelper.instance.getInvoices();
    // Filter for invoices created after the shift started (simplified)
    // A more robust solution would save the shift start time.
    final cashSales = invoices.where((inv) => inv.isPaid).fold<double>(0, (sum, inv) => sum + inv.totalAmount);
    
    final expectedAmount = _startCash + cashSales;

    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text('تقرير تسليم الوردية'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text('النقدية في البداية: $_startCash ج'),
                Text('إجمالي المبيعات النقدية: $cashSales ج'),
                Divider(),
                Text('المبلغ المتوقع بالدرج: $expectedAmount ج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
        ),
        actions: [
            TextButton(onPressed: (){
                Navigator.of(ctx).pop();
                setState(() {
                    _shiftActive = false;
                    _startCash = 0.0;
                    _cashController.clear();
                });
            }, child: Text('إنهاء الوردية'))
        ],
    ));
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
      appBar: AppBar(title: Text('الإعدادات')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Shift Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إدارة الوردية', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 16),
                  if (!_shiftActive) ...[
                    TextField(
                      controller: _cashController,
                      decoration: InputDecoration(labelText: 'النقدية المبدئية في الدرج', prefixIcon: Icon(Icons.money)),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _startShift, child: Text('بدء وردية جديدة'))),
                  ] else ...[
                     ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('الوردية الحالية نشطة'),
                        subtitle: Text('النقدية المبدئية: $_startCash ج'),
                     ),
                     SizedBox(height: 12),
                     SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _endShift, child: Text('حساب وتسليم الدرج'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange))),
                  ]
                ],
              ),
            ),
          ),
          // Data Management
          Card(
            child: ListTile(
              leading: Icon(Icons.upload_file),
              title: Text('استيراد قاعدة بيانات الأدوية'),
              subtitle: Text('استورد المنتجات والأسعار من ملف Excel'),
              onTap: _importFromExcel,
            ),
          ),
        ],
      ),
    );
  }
}
