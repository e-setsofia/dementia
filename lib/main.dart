import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

enum UserRole { caregiver, patient }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

//
// LOGIN SCREEN
//
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool hidePassword = true;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  UserRole selectedRole = UserRole.patient;

  void login() {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username and password")),
      );
      return;
    }

    if (selectedRole == UserRole.patient) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CaregiverDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0047FF), Color(0xff3FA9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Please login to continue",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration("Username", Icons.person),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Login as",
                style: TextStyle(color: Colors.white),
              ),

              RadioListTile(
                value: UserRole.patient,
                groupValue: selectedRole,
                onChanged: (v) => setState(() => selectedRole = v!),
                title: const Text("Patient",
                    style: TextStyle(color: Colors.white)),
              ),

              RadioListTile(
                value: UserRole.caregiver,
                groupValue: selectedRole,
                onChanged: (v) => setState(() => selectedRole = v!),
                title: const Text("Caregiver",
                    style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("LOGIN"),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration inputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: Colors.white),
    filled: true,
    fillColor: Colors.white.withOpacity(0.2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  );
}

//
// SIGN UP SCREEN
//
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  UserRole selectedRole = UserRole.patient;

  void signUp() {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account created successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0047FF), Color(0xff3FA9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),

            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: inputDecoration("Username", Icons.person),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: inputDecoration("Password", Icons.lock),
            ),

            const SizedBox(height: 20),

            const Text("Register as",
                style: TextStyle(color: Colors.white)),

            RadioListTile(
              value: UserRole.patient,
              groupValue: selectedRole,
              onChanged: (v) => setState(() => selectedRole = v!),
              title: const Text("Patient",
                  style: TextStyle(color: Colors.white)),
            ),

            RadioListTile(
              value: UserRole.caregiver,
              groupValue: selectedRole,
              onChanged: (v) => setState(() => selectedRole = v!),
              title: const Text("Caregiver",
                  style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: signUp,
                child: const Text("SIGN UP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//
// DASHBOARD CARD WIDGET
//
class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// PATIENT DASHBOARD (REDESIGNED)
//
class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DashboardCard(
              title: "Medication",
              icon: Icons.medication,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicationPage()),
                );
              },
            ),
            DashboardCard(
              title: "Daily Schedule",
              icon: Icons.calendar_today,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SchedulePage()),
                );
              },
            ),
            DashboardCard(
              title: "Emergency",
              icon: Icons.warning,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyPage()),
                );
              },
            ),
            DashboardCard(
              title: "Appointments",
              icon: Icons.event,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
//
// CAREGIVER DASHBOARD (FULL)
//
class CaregiverDashboard extends StatelessWidget {
  const CaregiverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Caregiver Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DashboardCard(
              title: "Medication Management",
              icon: Icons.medication_liquid,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicationPage()),
                );
              },
            ),
            DashboardCard(
              title: "Patient Information",
              icon: Icons.person,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientInfoPage()),
                );
              },
            ),
            DashboardCard(
              title: "Appointments",
              icon: Icons.event_note,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentsPage()),
                );
              },
            ),
            DashboardCard(
              title: "Reports",
              icon: Icons.bar_chart,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                );
              },
            ),
            DashboardCard(
              title: "Alerts",
              icon: Icons.notifications,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsPage()),
                );
              },
            ),
            DashboardCard(
              title: "Settings",
              icon: Icons.settings,
              color: Colors.grey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

//
// MEDICATION PAGE
//
class MedicationPage extends StatelessWidget {
  const MedicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medication")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          MedicationTile(
            time: "Morning",
            drug: "Paracetamol",
            dose: "8:00 AM",
          ),
          MedicationTile(
            time: "Afternoon",
            drug: "Vitamin B",
            dose: "1:00 PM",
          ),
          MedicationTile(
            time: "Night",
            drug: "BP Medicine",
            dose: "8:00 PM",
          ),
        ],
      ),
    );
  }
}
//
// PATIENT INFO PAGE
//
class PatientInfoPage extends StatelessWidget {
  const PatientInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Information")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: Evans"),
            Text("Age: 70"),
            Text("Condition: test_app"),
            Text("Blood Group: O+"),
          ],
        ),
      ),
    );
  }
}

//
// APPOINTMENTS PAGE
//
class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointments")),
      body: const Center(
        child: Text(
          "Doctor appointments will appear here",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

//
// REPORTS PAGE
//
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: const Center(
        child: Text(
          "Medication reports & history",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

//
// ALERTS PAGE
//
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alerts")),
      body: const Center(
        child: Text(
          "Emergency alerts from patient will show here",
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      ),
    );
  }
}

//
// SETTINGS PAGE
//
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Profile"),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Notifications"),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Privacy"),
          ),
        ],
      ),
    );
  }
}//
// PATIENT FEATURES (FULL IMPLEMENTATION)
//


class MedicationTile extends StatelessWidget {
  final String time;
  final String drug;
  final String dose;

  const MedicationTile({
    super.key,
    required this.time,
    required this.drug,
    required this.dose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: Text("$time - $drug"),
        subtitle: Text(dose),
      ),
    );
  }
}

//
// DAILY SCHEDULE
//
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Schedule")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ScheduleTile(time: "8:00 AM", task: "Breakfast"),
          ScheduleTile(time: "9:00 AM", task: "Medication"),
          ScheduleTile(time: "11:00 AM", task: "Walk"),
          ScheduleTile(time: "1:00 PM", task: "Lunch"),
          ScheduleTile(time: "5:00 PM", task: "Rest"),
        ],
      ),
    );
  }
}

class ScheduleTile extends StatelessWidget {
  final String time;
  final String task;

  const ScheduleTile({
    super.key,
    required this.time,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.green),
        title: Text(task),
        subtitle: Text(time),
      ),
    );
  }
}

//
// EMERGENCY PAGE
//
class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  void callHelp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚨 Emergency alert sent to caregiver!"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "Press button to alert caregiver",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 20),
              ),
              onPressed: () => callHelp(context),
              child: const Text("EMERGENCY ALERT"),
            ),
          ],
        ),
      ),
    );
  }
}
