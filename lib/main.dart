// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  String? url;
  String? anonKey;

  try {
    await dotenv.load(fileName: ".env");
    url = dotenv.env['SUPABASE_URL'];
    anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null ||
        url.isEmpty ||
        url.contains('your-project-id') ||
        anonKey == null ||
        anonKey.isEmpty ||
        anonKey.contains('your-supabase-anon-key')) {
      throw Exception(
        "Invalid credentials in .env file. Please set your actual Supabase URL and Anon Key.",
      );
    }

    if (anonKey.startsWith('sb_secret_') || anonKey.contains('secret')) {
      throw Exception(
        "Forbidden use of secret API key. Please use your PUBLIC anon key (starts with 'eyJ...'), NOT the secret key (starts with 'sb_secret_').",
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  } catch (e) {
    initError = e.toString();
  }

  runApp(MyApp(
    initError: initError,
    initialUrl: url,
    initialAnonKey: anonKey,
  ));
}

class MyApp extends StatelessWidget {
  final String? initError;
  final String? initialUrl;
  final String? initialAnonKey;

  const MyApp({
    super.key,
    this.initError,
    this.initialUrl,
    this.initialAnonKey,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dementia Care App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
      ),
      home: initError != null
          ? SupabaseConfigErrorScreen(
              initialError: initError!,
              initialUrl: initialUrl,
              initialAnonKey: initialAnonKey,
            )
          : const LoginScreen(),
    );
  }
}

class SupabaseConfigErrorScreen extends StatefulWidget {
  final String initialError;
  final String? initialUrl;
  final String? initialAnonKey;

  const SupabaseConfigErrorScreen({
    super.key,
    required this.initialError,
    this.initialUrl,
    this.initialAnonKey,
  });

  @override
  State<SupabaseConfigErrorScreen> createState() => _SupabaseConfigErrorScreenState();
}

class _SupabaseConfigErrorScreenState extends State<SupabaseConfigErrorScreen> {
  late String _currentError;
  String? _currentUrl;
  String? _currentAnonKey;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _currentError = widget.initialError;
    _currentUrl = widget.initialUrl;
    _currentAnonKey = widget.initialAnonKey;
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });

    try {
      // Reload dotenv variables from file
      await dotenv.load(fileName: ".env");
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      setState(() {
        _currentUrl = url;
        _currentAnonKey = anonKey;
      });

      if (url == null ||
          url.isEmpty ||
          url.contains('your-project-id') ||
          anonKey == null ||
          anonKey.isEmpty ||
          anonKey.contains('your-supabase-anon-key')) {
        throw Exception(
          "Invalid credentials in .env file. Please set your actual Supabase URL and Anon Key.",
        );
      }

      if (anonKey.startsWith('sb_secret_') || anonKey.contains('secret')) {
        throw Exception(
          "Forbidden use of secret API key. Please use your PUBLIC anon key (starts with 'eyJ...'), NOT the secret key (starts with 'sb_secret_').",
        );
      }

      // Try to initialize Supabase
      try {
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
        );
      } catch (e) {
        // If it's already initialized, we can ignore the already initialized error
        if (!e.toString().contains('already been initialized')) {
          rethrow;
        }
      }

      // If successful, navigate to LoginScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      setState(() {
        _currentError = e.toString();
        _isRetrying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Retry failed: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2E), Color(0xFF11111B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing warning icon container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Configuration Required",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please configure your Supabase settings in the `.env` file.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Current config values card
                  Card(
                    color: Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Current Settings:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const Divider(color: Colors.white24, height: 16),
                          _buildConfigRow("SUPABASE_URL", _currentUrl ?? "Not found"),
                          const SizedBox(height: 8),
                          _buildConfigRow(
                            "SUPABASE_ANON_KEY",
                            _currentAnonKey != null && _currentAnonKey!.length > 15
                                ? "${_currentAnonKey!.substring(0, 15)}..."
                                : (_currentAnonKey ?? "Not found"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error message details
                  Card(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        "Error: $_currentError",
                        style: const TextStyle(
                          fontFamily: "monospace",
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step-by-step instructions card
                  Card(
                    color: Colors.white.withOpacity(0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.help_outline, color: Colors.blueAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "How to Set Up:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionStep(1, "Go to supabase.com and create a project."),
                          _buildInstructionStep(2, "Copy your API URL and anon public key."),
                          _buildInstructionStep(3, "Open the .env file in this project root."),
                          _buildInstructionStep(4, "Update the variables and save the file."),
                          _buildInstructionStep(5, "Click the button below to retry connection."),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isRetrying ? null : _handleRetry,
                      child: _isRetrying
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh),
                                SizedBox(width: 8),
                                Text(
                                  "Retry Connection",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontFamily: "monospace",
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: "monospace",
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(int stepNum, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              "$stepNum",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

