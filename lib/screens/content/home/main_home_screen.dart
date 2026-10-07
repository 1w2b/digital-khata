import 'package:digital_khata/helper/helper_function.dart';
import 'package:digital_khata/helper/pkr.dart';
import 'package:digital_khata/screens/content/people/add_people_screen.dart';
import 'package:digital_khata/screens/content/transaction/add_due_amount_screen.dart';
import 'package:digital_khata/services/local_database.dart';
import 'package:flutter/material.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});
  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final _search = TextEditingController();
  late Future<List<PersonRecord>> _people = DatabaseService().getPeople();
  late Future<Map<String, int>> _summary = DatabaseService().getSummary();
  void _reload() => setState(() { _people = DatabaseService().getPeople(search: _search.text); _summary = DatabaseService().getSummary(); });
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(child: RefreshIndicator(onRefresh: () async => _reload(), child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 24), children: [
    Row(children: [const CircleAvatar(backgroundColor: Color(0xFFE5F5EC), child: Icon(Icons.storefront, color: Color(0xFF087F5B))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Assalamu Alaikum', style: TextStyle(color: Colors.black54)), Text(AuthService.instance.currentUser?.name ?? 'Business owner', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))])), IconButton(tooltip: 'Log out', onPressed: () => logout(context), icon: const Icon(Icons.logout))]),
    const SizedBox(height: 20),
    FutureBuilder<Map<String, int>>(future: _summary, builder: (context, snapshot) { final data = snapshot.data ?? {}; return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF087F5B), Color(0xFF20A779)]), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('TOTAL OUTSTANDING', style: TextStyle(color: Colors.white70, letterSpacing: 1, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text(formatPkr(data['balance'] ?? 0), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)), const SizedBox(height: 18), Row(children: [Expanded(child: _metric('Customers', '${data['people'] ?? 0}')), Expanded(child: _metric('Highest balance', formatPkr(data['highest'] ?? 0))), Expanded(child: _metric('Lowest balance', formatPkr(data['lowest'] ?? 0)))]) ])); }),
    const SizedBox(height: 22),
    Row(children: [const Expanded(child: Text('Customers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), TextButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPeopleScreen())); if (mounted) _reload(); }, icon: const Icon(Icons.person_add_alt_1), label: const Text('Add'))]),
    const SizedBox(height: 8), TextField(controller: _search, onChanged: (_) => _reload(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search customers', border: OutlineInputBorder())),
    const SizedBox(height: 10),
    FutureBuilder<List<PersonRecord>>(future: _people, builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())); if (snapshot.hasError) return Text('Could not load customers: ${snapshot.error}'); final people = snapshot.data ?? []; if (people.isEmpty) return const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No customers yet. Add a customer to start your khata.'))); return Column(children: people.map((person) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFE5F5EC), child: Text(person.name.isEmpty ? '?' : person.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF087F5B)))), title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(person.phone), trailing: Text(formatPkr(person.balancePaisa), style: TextStyle(fontWeight: FontWeight.bold, color: person.balancePaisa > 0 ? Colors.red.shade700 : Colors.green.shade700)), onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AddDueAmountScreen(personId: person.id, personName: person.name))); if (mounted) _reload(); }))).toList()); }),
  ])));

  Widget _metric(String title, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 4), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))]);
}
