import 'package:digital_khata/helper/pkr.dart';
import 'package:digital_khata/services/local_database.dart';
import 'package:flutter/material.dart';

class AddDueAmountScreen extends StatefulWidget {
  final int personId;
  final String personName;
  const AddDueAmountScreen({super.key, required this.personId, required this.personName});
  @override
  State<AddDueAmountScreen> createState() => _AddDueAmountScreenState();
}

class _AddDueAmountScreenState extends State<AddDueAmountScreen> {
  final _db = DatabaseService();
  late Future<List<LedgerEntry>> _ledger = _db.getLedger(widget.personId);
  late Future<PersonRecord?> _person = _db.getPerson(widget.personId);
  void _reload() { setState(() { _ledger = _db.getLedger(widget.personId); _person = _db.getPerson(widget.personId); }); }

  Future<void> _showEntryDialog({required bool isPayment, required int balance}) async {
    final label = TextEditingController();
    final amount = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(isPayment ? 'Record payment' : 'Add credit / sale'),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: label, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: isPayment ? 'Note (optional)' : 'Item or description'), validator: (value) => !isPayment && (value == null || value.trim().isEmpty) ? 'Enter an item description' : null),
        TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (PKR)', prefixText: 'Rs '), validator: (value) { final parsed = parsePaisa(value ?? ''); if (parsed == null) return 'Enter an amount greater than zero'; if (isPayment && parsed > balance) return 'Cannot exceed ${formatPkr(balance)}'; return null; }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: Text(isPayment ? 'Save payment' : 'Add to khata'))],
    ));
    if (result != true) { label.dispose(); amount.dispose(); return; }
    try {
      final paisa = parsePaisa(amount.text)!;
      if (isPayment) {
        await _db.addPayment(personId: widget.personId, amountPaisa: paisa, description: label.text);
      } else {
        await _db.addDueItem(personId: widget.personId, item: label.text, amountPaisa: paisa);
      }
      if (mounted) _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    } finally { label.dispose(); amount.dispose(); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.personName)),
    body: FutureBuilder<PersonRecord?>(future: _person, builder: (context, personSnapshot) {
      final person = personSnapshot.data;
      if (personSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (person == null) return const Center(child: Text('Customer not found.'));
      return Column(children: [
        Container(width: double.infinity, margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFE5F5EC), borderRadius: BorderRadius.circular(18)), child: Column(children: [Text(person.name, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text(person.phone), const SizedBox(height: 16), const Text('CURRENT BALANCE', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.w600)), Text(formatPkr(person.balancePaisa), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: person.balancePaisa > 0 ? Colors.red.shade700 : Colors.green.shade700))])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Expanded(child: FilledButton.icon(onPressed: () => _showEntryDialog(isPayment: false, balance: person.balancePaisa), icon: const Icon(Icons.add_shopping_cart), label: const Text('Add credit'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: person.balancePaisa > 0 ? () => _showEntryDialog(isPayment: true, balance: person.balancePaisa) : null, icon: const Icon(Icons.payments_outlined), label: const Text('Payment')))])),
        const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Transaction history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
        Expanded(child: FutureBuilder<List<LedgerEntry>>(future: _ledger, builder: (context, ledgerSnapshot) {
          if (ledgerSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final entries = ledgerSnapshot.data ?? [];
          if (entries.isEmpty) return const Center(child: Text('No transactions yet. Add a credit or payment.'));
          return RefreshIndicator(onRefresh: () async => _reload(), child: ListView.builder(itemCount: entries.length, itemBuilder: (context, index) {
            final entry = entries[index];
            final isDue = entry.type == 'due';
            final date = entry.createdAt;
            return ListTile(leading: CircleAvatar(backgroundColor: isDue ? Colors.red.shade50 : Colors.green.shade50, child: Icon(isDue ? Icons.arrow_upward : Icons.arrow_downward, color: isDue ? Colors.red : Colors.green)), title: Text(entry.label), subtitle: Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'), trailing: Text('${isDue ? '+' : '-'}${formatPkr(entry.amountPaisa)}', style: TextStyle(fontWeight: FontWeight.bold, color: isDue ? Colors.red.shade700 : Colors.green.shade700)));
          }));
        })),
      ]);
    }),
  );
}
