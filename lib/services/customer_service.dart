import 'package:digital_khata/services/local_database.dart';

/// Read-only customer access operations backed by the local khata database.
class CustomerService {
  static final DatabaseService _database = DatabaseService();

  static Future<PersonRecord> findCustomerByUniqueId(String uniqueId) =>
      _database.findCustomerByUniqueId(uniqueId);

  static Future<PersonRecord?> getCustomer(int personId) =>
      _database.getCustomerRecord(personId);

  static Future<List<LedgerEntry>> getLedger(int personId) =>
      _database.getCustomerLedger(personId);
}
