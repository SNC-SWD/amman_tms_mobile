import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _showSplash = true;
  String _userRole = 'supervisor';

  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
  }

  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(seconds: 2)); // Tambahkan delay splash
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userRole = prefs.getString('userRole') ?? 'unknown';
      _showSplash = false;
    });
  }

  Future<void> _handleLoginSuccess(String userRole) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userRole', userRole);
    setState(() {
      _isLoggedIn = true;
      _userRole = userRole;
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userRole');
    setState(() {
      _isLoggedIn = false;
      _userRole = 'unknown';
    });
  }

  void _finishSplash() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color kPrimaryBlue = const Color(0xFF163458);
    final Color kAccentGold = const Color(0xFFC88C2C);
    final Color kLightGray = const Color(0xFFF4F6F9);
    final Color kSlateGray = const Color(0xFF4C5C74);
    final Color kSoftGold = const Color(0xFFE0B352);
    final Color kBlueTint = const Color(0xFFE6EDF6);

    return MaterialApp(
      title: 'AmmanTrans',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: kPrimaryBlue,
          onPrimary: Colors.white,
          secondary: kAccentGold,
          onSecondary: Colors.white,
          background: kLightGray,
          onBackground: kSlateGray,
          surface: Colors.white,
          onSurface: kSlateGray,
          error: Colors.red,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: kLightGray,
        appBarTheme: AppBarTheme(
          backgroundColor: kPrimaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: kAccentGold,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF163458),
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF4C5C74)),
        ),
      ),
      home: _showSplash
          ? SplashScreen(onFinish: _finishSplash)
          : (_isLoggedIn
                ? MainScreen(
                    onLogout: _handleLogout,
                    userRole: _userRole,
                    busName: _userRole == 'driver' ? 'Bus A' : null,
                  )
                : LoginScreen(onLoginSuccess: _handleLoginSuccess)),
    );
  }
}

class Customer {
  final String name;
  final String email;
  final String phone;

  Customer({required this.name, required this.email, required this.phone});
}

class MyHomePage extends StatefulWidget {
  final String title;
  final VoidCallback onLogout;
  const MyHomePage({super.key, required this.title, required this.onLogout});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  final List<Customer> customers = [
    Customer(name: 'John Doe', email: 'john@example.com', phone: '08123456789'),
    Customer(
      name: 'Jane Smith',
      email: 'jane@example.com',
      phone: '08234567890',
    ),
    Customer(
      name: 'Alice Johnson',
      email: 'alice@example.com',
      phone: '08345678901',
    ),
  ];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: const Text(
                    'Konfirmasi Logout',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text('Apakah Anda yakin ingin logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Ya',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) {
                widget.onLogout();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(
                          customer.name.substring(0, 1),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.email,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.phone,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.deepPurple,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomerDetailPage(customer: customer),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddCustomerDialog(
              onAdd: (Customer newCustomer) {
                setState(() {
                  customers.add(newCustomer);
                });
              },
            ),
          );
        },
        tooltip: 'Tambah Customer',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CustomerDetailPage extends StatelessWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Customer')),
      body: Center(
        child: Card(
          elevation: 10,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    customer.name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 38,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  customer.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(
                      customer.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(
                      customer.phone,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddCustomerDialog extends StatefulWidget {
  final Function(Customer) onAdd;
  const AddCustomerDialog({super.key, required this.onAdd});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String phone = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Tambah Customer',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                onSaved: (value) => name = value ?? '',
              ),
              const SizedBox(height: 14),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Email wajib diisi' : null,
                onSaved: (value) => email = value ?? '',
              ),
              const SizedBox(height: 14),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Telepon',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty
                    ? 'Telepon wajib diisi'
                    : null,
                onSaved: (value) => phone = value ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              widget.onAdd(Customer(name: name, email: email, phone: phone));
              Navigator.of(context).pop();
            }
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
