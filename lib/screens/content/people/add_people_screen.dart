import 'package:digital_khata/services/local_database.dart';
import 'package:flutter/material.dart';

class AddPeopleScreen extends StatefulWidget {
  const AddPeopleScreen({super.key});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final person = await DatabaseService().addPerson(name: _name.text, phone: _phone.text);
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: const Text('Customer added'),
        content: SelectableText('${person.name} can view their khata with this access code:\n\n${person.uniqueId}\n\nShare it privately with your customer.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add customer')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.person_add_alt_1, size: 72, color: Color(0xFF087F5B)),
      const SizedBox(height: 16),
      TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Customer name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (value) => value == null || value.trim().isEmpty ? 'Enter a customer name' : null),
      const SizedBox(height: 16),
      TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Pakistani mobile number', hintText: '03XX XXXXXXX', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), validator: (value) => value == null || value.trim().isEmpty ? 'Enter a phone number' : null),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save), label: const Text('Save customer')),
      const SizedBox(height: 12),
      const Text('A private access code is generated so your customer can view their ledger.', textAlign: TextAlign.center),
    ])),
  );
}
