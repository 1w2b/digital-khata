import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/components/my_text_field.dart';
import 'package:digital_khata/screens/customer/customer_screen.dart';
import 'package:digital_khata/services/local_database.dart';
import 'package:flutter/material.dart';

class LoginAsCustomerScreen extends StatefulWidget {
  final void Function()? onTap;
  final void Function()? onregTap;
  const LoginAsCustomerScreen({super.key, required this.onTap, required this.onregTap});
  @override
  State<LoginAsCustomerScreen> createState() => _LoginAsCustomerScreenState();
}

class _LoginAsCustomerScreenState extends State<LoginAsCustomerScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  Future<void> _login() async {
    if (_code.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final person = await DatabaseService().findCustomerByUniqueId(_code.text);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerScreen(customerId: person.id, customerName: person.name)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    } finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  void dispose() { _code.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Theme.of(context).colorScheme.surface, body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.menu_book_rounded, size: 84, color: Color(0xFF087F5B)), const SizedBox(height: 12), const Text('Pak Khata', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Customer ledger access', style: TextStyle(color: Colors.black54)), const SizedBox(height: 28),
    MyTextField(hintText: '8-digit customer access code', obscureText: false, controller: _code), const SizedBox(height: 20),
    _loading ? const CircularProgressIndicator() : MyButton(text: 'View my khata', onTap: _login), const SizedBox(height: 18),
    TextButton(onPressed: widget.onTap, child: const Text('Business owner login')), TextButton(onPressed: widget.onregTap, child: const Text('Create business account')),
  ]))));
}
