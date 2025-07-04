import 'package:flutter/material.dart';
import '../data/models.dart';

class CustomerForm extends StatefulWidget {
  final Function(Customer) onSubmit;

  CustomerForm({required this.onSubmit});

  @override
  _CustomerFormState createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _address = '';
  bool _hasCredit = false;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newCustomer = Customer(
        name: _name,
        phone: _phone,
        address: _address,
        hasCredit: _hasCredit,
      );
      widget.onSubmit(newCustomer);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة عميل جديد'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'الاسم'),
                validator: (val) => val!.isEmpty ? 'الاسم مطلوب' : null,
                onSaved: (val) => _name = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
                onSaved: (val) => _phone = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'العنوان'),
                onSaved: (val) => _address = val!,
              ),
              SwitchListTile(
                title: Text('سماح بالدفع الآجل'),
                value: _hasCredit,
                onChanged: (val) => setState(() => _hasCredit = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text('حفظ'),
        ),
      ],
    );
  }
}
