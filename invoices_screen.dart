import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/models.dart';
import 'package:intl/intl.dart';

import '../utils/invoice_generator.dart';

class InvoicesScreen extends StatefulWidget {
  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late Future<List<Invoice>> _invoicesFuture;

  @override
  void initState() {
    super.initState();
    _refreshInvoices();
  }

  void _refreshInvoices() {
    setState(() {
      _invoicesFuture = DatabaseHelper.instance.getInvoices();
    });
  }

  Future<void> _processReturn(int invoiceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الإرجاع'),
        content: Text('هل أنت متأكد من رغبتك في إرجاع هذه الفاتورة؟ سيتم حذفها نهائياً.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('إلغاء')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('تأكيد', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteInvoice(invoiceId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرجاع الفاتورة بنجاح'), backgroundColor: Colors.green));
      _refreshInvoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الفواتير والمرتجعات'),
        actions: [
            IconButton(icon: Icon(Icons.refresh), onPressed: _refreshInvoices),
        ],
      ),
      body: FutureBuilder<List<Invoice>>(
        future: _invoicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا توجد فواتير مسجلة بعد.'));
          }

          final invoices = snapshot.data!;
          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (ctx, i) {
              final invoice = invoices[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('#${invoice.id}')),
                  title: Text('فاتورة لـ: ${invoice.customerName}'),
                  subtitle: Text('بتاريخ: ${DateFormat('yyyy-MM-dd hh:mm a').format(invoice.date)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                        Text('${invoice.totalAmount.toStringAsFixed(2)} ج', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(invoice.isPaid ? 'مدفوعة' : 'آجل', style: TextStyle(color: invoice.isPaid ? Colors.green : Colors.orange)),
                    ],
                  ),
                  onTap: () {
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                        title: Text('فاتورة #${invoice.id}'),
                        content: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: invoice.items.map((item) => Text('${item.name} (x${item.quantity})')).toList(),
                            ),
                        ),
                        actions: [
                            TextButton(onPressed: () => InvoiceGenerator.generateAndPrintInvoice(invoice), child: Text('إعادة طباعة')),
                            TextButton(onPressed: () => _processReturn(invoice.id!), child: Text('إرجاع الفاتورة', style: TextStyle(color: Colors.red))),
                        ],
                    ));
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
