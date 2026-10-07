import 'package:digital_khata/helper/pkr.dart';
import 'package:digital_khata/screens/content/transaction/add_due_amount_screen.dart';
import 'package:digital_khata/services/local_database.dart';
import 'package:flutter/material.dart';

class ListPeopleScreen extends StatefulWidget {
  const ListPeopleScreen({super.key});
  @override
  State<ListPeopleScreen> createState() => _ListPeopleScreenState();
}

class _ListPeopleScreenState extends State<ListPeopleScreen> {
  final _search = TextEditingController();
  late Future<List<PersonRecord>> _people = DatabaseService().getPeople();
  void _reload() => setState(() => _people = DatabaseService().getPeople(search: _search.text));

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Customers')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _search, onChanged: (_) => _reload(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name, phone or access code', border: OutlineInputBorder()))),
      Expanded(child: FutureBuilder<List<PersonRecord>>(future: _people, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Could not load customers: ${snapshot.error}'));
        final people = snapshot.data ?? [];
        if (people.isEmpty) return const Center(child: Text('No customers yet. Add your first customer.'));
        return RefreshIndicator(onRefresh: () async => _reload(), child: ListView.builder(itemCount: people.length, itemBuilder: (context, index) {
          final person = people[index];
          return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFFE5F5EC), child: Text(person.name.isEmpty ? '?' : person.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF087F5B), fontWeight: FontWeight.bold))),
            title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${person.phone}\nAccess code: ${person.uniqueId}'), isThreeLine: true,
            trailing: Text(formatPkr(person.balancePaisa), textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, color: person.balancePaisa > 0 ? Colors.red.shade700 : Colors.green.shade700)),
            onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AddDueAmountScreen(personId: person.id, personName: person.name))); if (mounted) _reload(); },
          ));
        }));
      }))
    ]),
  );
}
