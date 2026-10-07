import 'package:digital_khata/helper/pkr.dart';
import 'package:digital_khata/services/local_database.dart';
import 'package:flutter/material.dart';

class CustomerScreen extends StatefulWidget {
  final int customerId;
  final String customerName;
  const CustomerScreen({super.key, required this.customerId, required this.customerName});
  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _db = DatabaseService();
  late Future<PersonRecord?> _person = _db.getCustomerRecord(widget.customerId);
  late Future<List<LedgerEntry>> _entries = _db.getCustomerLedger(widget.customerId);
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('${widget.customerName}’s khata')), body: FutureBuilder<PersonRecord?>(future: _person, builder: (context, personSnapshot) {
    final person = personSnapshot.data;
    if (personSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    if (person == null) return const Center(child: Text('Ledger unavailable. Please check with the shop.'));
    return Column(children: [Container(width: double.infinity, margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFE5F5EC), borderRadius: BorderRadius.circular(18)), child: Column(children: [const Text('YOUR OUTSTANDING BALANCE'), const SizedBox(height: 8), Text(formatPkr(person.balancePaisa), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF087F5B)))])), const Padding(padding: EdgeInsets.all(12), child: Align(alignment: Alignment.centerLeft, child: Text('Transaction history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))), Expanded(child: FutureBuilder<List<LedgerEntry>>(future: _entries, builder: (context, entrySnapshot) {
      if (entrySnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      final entries = entrySnapshot.data ?? [];
      if (entries.isEmpty) return const Center(child: Text('No transactions yet.'));
      return ListView.builder(itemCount: entries.length, itemBuilder: (context, index) { final entry = entries[index]; final due = entry.type == 'due'; final date = entry.createdAt; return ListTile(leading: Icon(due ? Icons.add_circle_outline : Icons.check_circle_outline, color: due ? Colors.red : Colors.green), title: Text(entry.label), subtitle: Text('${date.day}/${date.month}/${date.year}'), trailing: Text('${due ? '+' : '-'}${formatPkr(entry.amountPaisa)}', style: TextStyle(color: due ? Colors.red : Colors.green, fontWeight: FontWeight.bold))); });
    }))]);
  }));
}
