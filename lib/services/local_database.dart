import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class AppUser {
  const AppUser({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory AppUser.fromMap(Map<String, Object?> row) => AppUser(
        id: row['id'] as int,
        name: row['name'] as String,
        email: row['email'] as String,
      );
}

class PersonRecord {
  const PersonRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.uniqueId,
    required this.createdAt,
    this.balancePaisa = 0,
  });

  final int id;
  final String name;
  final String phone;
  final String uniqueId;
  final DateTime createdAt;
  final int balancePaisa;

  factory PersonRecord.fromMap(Map<String, Object?> row) => PersonRecord(
        id: row['id'] as int,
        name: row['name'] as String,
        phone: row['phone'] as String,
        uniqueId: row['unique_id'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        balancePaisa: (row['balance_paisa'] as int?) ?? 0,
      );
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.label,
    required this.amountPaisa,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String label;
  final int amountPaisa;
  final DateTime createdAt;

  factory LedgerEntry.fromMap(Map<String, Object?> row) => LedgerEntry(
        id: row['id'] as int,
        type: row['type'] as String,
        label: row['label'] as String,
        amountPaisa: row['amount_paisa'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      );
}

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;
  Database get database => _database!;

  Future<void> initialize() async {
    if (_database != null) return;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, 'pak_khata.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            password_salt TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE people (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            unique_id TEXT NOT NULL UNIQUE,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE ledger_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_id INTEGER NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('due', 'payment')),
            label TEXT NOT NULL,
            amount_paisa INTEGER NOT NULL CHECK(amount_paisa > 0),
            created_at INTEGER NOT NULL,
            FOREIGN KEY(person_id) REFERENCES people(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX people_owner_idx ON people(owner_id)');
        await db.execute('CREATE INDEX ledger_person_date_idx ON ledger_entries(person_id, created_at DESC)');
      },
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  static const _sessionKey = 'pak_khata_user_id';
  final ValueNotifier<AppUser?> currentUserNotifier = ValueNotifier(null);
  final LocalDatabase _store = LocalDatabase.instance;

  AppUser? get currentUser => currentUserNotifier.value;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_sessionKey);
    if (userId == null) return;
    final rows = await _store.database.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (rows.isNotEmpty) currentUserNotifier.value = AppUser.fromMap(rows.first);
  }

  Future<void> signUp({required String name, required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty || normalizedEmail.isEmpty || password.length < 6) {
      throw ArgumentError('Enter a name, valid email, and password with at least 6 characters.');
    }
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final saltText = base64UrlEncode(salt);
    final hash = sha256.convert(utf8.encode('$saltText:$password')).toString();
    try {
      final id = await _store.database.insert('users', {
        'name': name.trim(),
        'email': normalizedEmail,
        'password_hash': hash,
        'password_salt': saltText,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      await _setSession(id);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) throw StateError('An account with this email already exists.');
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final rows = await _store.database.query('users', where: 'email = ?', whereArgs: [email.trim().toLowerCase()], limit: 1);
    if (rows.isEmpty) throw StateError('Incorrect email or password.');
    final row = rows.first;
    final hash = sha256.convert(utf8.encode('${row['password_salt']}:$password')).toString();
    if (hash != row['password_hash']) throw StateError('Incorrect email or password.');
    await _setSession(row['id'] as int);
  }

  Future<void> _setSession(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, id);
    final rows = await _store.database.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    currentUserNotifier.value = AppUser.fromMap(rows.first);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    currentUserNotifier.value = null;
  }
}

class DatabaseService {
  DatabaseService() : _db = LocalDatabase.instance.database;
  final Database _db;
  int get _ownerId => AuthService.instance.currentUser?.id ?? (throw StateError('Please sign in first.'));

  Future<List<PersonRecord>> getPeople({String search = ''}) async {
    final query = search.trim().toLowerCase();
    final rows = await _db.rawQuery('''
      SELECT p.*, COALESCE(SUM(CASE WHEN l.type = 'due' THEN l.amount_paisa ELSE -l.amount_paisa END), 0) AS balance_paisa
      FROM people p LEFT JOIN ledger_entries l ON l.person_id = p.id
      WHERE p.owner_id = ? AND (LOWER(p.name) LIKE ? OR LOWER(p.unique_id) LIKE ? OR LOWER(p.phone) LIKE ?)
      GROUP BY p.id ORDER BY p.created_at DESC
    ''', [_ownerId, '%$query%', '%$query%', '%$query%']);
    return rows.map(PersonRecord.fromMap).toList();
  }

  Future<PersonRecord?> getPerson(int id) async {
    final rows = await _db.rawQuery('''
      SELECT p.*, COALESCE(SUM(CASE WHEN l.type = 'due' THEN l.amount_paisa ELSE -l.amount_paisa END), 0) AS balance_paisa
      FROM people p LEFT JOIN ledger_entries l ON l.person_id = p.id WHERE p.id = ? AND p.owner_id = ? GROUP BY p.id LIMIT 1
    ''', [id, _ownerId]);
    if (rows.isEmpty) return null;
    return PersonRecord.fromMap(rows.first);
  }

  Future<PersonRecord> findCustomerByUniqueId(String code) async {
    final rows = await _db.rawQuery('''
      SELECT p.*, COALESCE(SUM(CASE WHEN l.type = 'due' THEN l.amount_paisa ELSE -l.amount_paisa END), 0) AS balance_paisa
      FROM people p LEFT JOIN ledger_entries l ON l.person_id = p.id WHERE p.unique_id = ? GROUP BY p.id LIMIT 1
    ''', [code.trim()]);
    if (rows.isEmpty) throw StateError('No customer found for that access code.');
    return PersonRecord.fromMap(rows.first);
  }

  Future<PersonRecord?> getCustomerRecord(int id) async {
    final rows = await _db.rawQuery('''
      SELECT p.*, COALESCE(SUM(CASE WHEN l.type = 'due' THEN l.amount_paisa ELSE -l.amount_paisa END), 0) AS balance_paisa
      FROM people p LEFT JOIN ledger_entries l ON l.person_id = p.id WHERE p.id = ? GROUP BY p.id LIMIT 1
    ''', [id]);
    return rows.isEmpty ? null : PersonRecord.fromMap(rows.first);
  }

  Future<List<LedgerEntry>> getCustomerLedger(int personId) async {
    final rows = await _db.query('ledger_entries', where: 'person_id = ?', whereArgs: [personId], orderBy: 'created_at DESC, id DESC');
    return rows.map(LedgerEntry.fromMap).toList();
  }

  Future<PersonRecord> addPerson({required String name, required String phone}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || phone.trim().isEmpty) throw ArgumentError('Enter the customer name and phone number.');
    final random = Random.secure();
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = (10000000 + random.nextInt(90000000)).toString();
      try {
        final id = await _db.insert('people', {
          'owner_id': _ownerId,
          'name': cleanName,
          'phone': phone.trim(),
          'unique_id': code,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
        return (await getPerson(id))!;
      } on DatabaseException catch (error) {
        if (!error.isUniqueConstraintError()) rethrow;
      }
    }
    throw StateError('Unable to create a unique customer code. Try again.');
  }

  Future<List<LedgerEntry>> getLedger(int personId) async {
    final person = await getPerson(personId);
    if (person == null) throw StateError('Customer not found.');
    final rows = await _db.query('ledger_entries', where: 'person_id = ?', whereArgs: [personId], orderBy: 'created_at DESC, id DESC');
    return rows.map(LedgerEntry.fromMap).toList();
  }

  Future<void> addDueItem({required int personId, required String item, required int amountPaisa}) async {
    final person = await getPerson(personId);
    if (person == null) throw StateError('Customer not found.');
    if (item.trim().isEmpty || amountPaisa <= 0) throw ArgumentError('Enter an item and a valid amount.');
    await _db.insert('ledger_entries', {
      'person_id': personId,
      'type': 'due',
      'label': item.trim(),
      'amount_paisa': amountPaisa,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> addPayment({required int personId, required int amountPaisa, String description = ''}) async {
    final person = await getPerson(personId);
    if (person == null) throw StateError('Customer not found.');
    if (amountPaisa <= 0) throw ArgumentError('Enter a valid payment amount.');
    await _db.transaction((txn) async {
      final rows = await txn.rawQuery('''
        SELECT COALESCE(SUM(CASE WHEN type = 'due' THEN amount_paisa ELSE -amount_paisa END), 0) AS balance
        FROM ledger_entries WHERE person_id = ?
      ''', [personId]);
      final balance = rows.first['balance'] as int;
      if (amountPaisa > balance) throw StateError('Payment cannot exceed the outstanding balance.');
      await txn.insert('ledger_entries', {
        'person_id': personId,
        'type': 'payment',
        'label': description.trim().isEmpty ? 'Payment received' : description.trim(),
        'amount_paisa': amountPaisa,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  Future<Map<String, int>> getSummary() async {
    final people = await getPeople();
    var total = 0;
    var highest = 0;
    var lowest = people.isEmpty ? 0 : people.first.balancePaisa;
    for (final person in people) {
      total += person.balancePaisa;
      if (person.balancePaisa > highest) highest = person.balancePaisa;
      if (person.balancePaisa < lowest) lowest = person.balancePaisa;
    }
    return {'people': people.length, 'balance': total, 'highest': highest, 'lowest': lowest};
  }
}
