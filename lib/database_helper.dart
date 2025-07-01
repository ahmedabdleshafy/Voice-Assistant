import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern to ensure only one instance of the database helper exists.
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Getter for the database. If it doesn't exist, it will be initialized.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initializes the database by opening a connection and creating tables if they don't exist.
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'rafiq.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // The `onCreate` function is called when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    // Table for appointments
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table for reminders
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        remindAt TEXT NOT NULL, // Stores date and time for the reminder
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table for expenses
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT,
        date TEXT NOT NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // CRUD Operations for Appointments
  Future<int> insertAppointment(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('appointments', row);
  }

  Future<List<Map<String, dynamic>>> queryAllAppointments() async {
    Database db = await database;
    return await db.query('appointments');
  }

  Future<int> updateAppointment(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update('appointments', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAppointment(int id) async {
    Database db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Reminders
  Future<int> insertReminder(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('reminders', row);
  }

  Future<List<Map<String, dynamic>>> queryAllReminders() async {
    Database db = await database;
    return await db.query('reminders');
  }

  Future<int> updateReminder(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update('reminders', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteReminder(int id) async {
    Database db = await database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Expenses
  Future<int> insertExpense(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('expenses', row);
  }

  Future<List<Map<String, dynamic>>> queryAllExpenses() async {
    Database db = await database;
    return await db.query('expenses');
  }

  Future<int> updateExpense(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update('expenses', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExpense(int id) async {
    Database db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
