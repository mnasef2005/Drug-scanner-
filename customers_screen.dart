import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/models.dart';
import '../widgets/customer_form.dart';

class CustomersScreen extends StatefulWidget {
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Customer>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _refreshCustomers();
  }

  void _refreshCustomers() {
    setState(() {
      _customersFuture = DatabaseHelper.instance.getCustomers();
    });
  }

  void _addCustomer(Customer customer) async {
    await DatabaseHelper.instance.addCustomer(customer);
    _refreshCustomers();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة العميل بنجاح')));
  }

  void _deleteCustomer(int id) async {
    await DatabaseHelper.instance.deleteCustomer(id);
    _refreshCustomers();
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف العميل')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إدارة العملاء')),
      body: FutureBuilder<List<Customer>>(
        future: _customersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا يوجد عملاء. أضف عميلاً جديداً.'));
          }
          final customers = snapshot.data!;
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (ctx, i) {
              final customer = customers[i];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(customer.name),
                  subtitle: Text(customer.phone),
                  trailing: customer.hasCredit ? Chip(label: Text('آجل'), backgroundColor: Colors.orange[100]) : null,
                  onLongPress: () => _deleteCustomer(customer.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => CustomerForm(onSubmit: _addCustomer),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
