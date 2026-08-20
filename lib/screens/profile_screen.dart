
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/them_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = ThemeService.instance.isDarkMode;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    await ThemeService.instance.setThemeMode(value);
    setState(() => _isDarkMode = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Dark mode enabled' : 'Light mode enabled'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() => _notificationsEnabled = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              value ? 'Notifications enabled' : 'Notifications disabled'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  //  Edit Profile — saves username + email to Firestore
  Future<void> _showEditProfileDialog(String currentUsername) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final usernameController =
    TextEditingController(text: currentUsername);
    final emailController =
    TextEditingController(text: user.email ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'username': usernameController.text.trim(),
              'email': emailController.text.trim(),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result['username']!.isNotEmpty) {
      try {
        //  Save username to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'username': result['username'],
          'email': result['email'],
        }, SetOptions(merge: true));

        //  Update email in Firebase Auth if changed
        if (result['email'] != user.email &&
            result['email']!.isNotEmpty) {
          await user.verifyBeforeUpdateEmail(result['email']!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  //  Change Password — uses Firebase Auth reauthentication
  Future<void> _showChangePasswordDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(
                              () => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(
                              () => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  //  Reauthenticate before changing password
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPasswordController.text);

                  if (mounted) Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  //  Logout with confirmation dialog first
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    }
  }

  //  Clear all Firestore transactions for this user
  Future<void> _clearAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all your transactions. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final collection = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions');

        final snapshot = await collection.get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    final transactionsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF667eea),
        // ✅ OLD FEATURE: white back button
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userRef.snapshots(),
        builder: (context, userSnap) {
          final userData =
              userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final username = userData['username'] ?? 'User';

          return StreamBuilder<QuerySnapshot>(
            stream: transactionsRef.snapshots(),
            builder: (context, txSnap) {
              double balance = 0;
              int txCount = 0;

              if (txSnap.hasData) {
                txCount = txSnap.data!.docs.length;
                for (var doc in txSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final double amount =
                  (data['amount'] as num).toDouble();
                  if (data['type'] == 'income') {
                    balance += amount;
                  } else {
                    balance -= amount;
                  }
                }
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // ✅ OLD FEATURE: Gradient header with stat chips
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF667eea),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.email ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // ✅ OLD FEATURE: Stat chips
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatChip(
                                'Transactions',
                                '$txCount',
                                Icons.receipt,
                              ),
                              _buildStatChip(
                                'Balance',
                                '₹${balance.toStringAsFixed(0)}',
                                Icons.account_balance_wallet,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    //  OLD FEATURE: Account section
                    _sectionLabel('Account'),
                    _buildMenuItem(
                      Icons.person,
                      'Edit Profile',
                          () => _showEditProfileDialog(username),
                    ),
                    _buildMenuItem(
                      Icons.lock,
                      'Change Password',
                      _showChangePasswordDialog,
                    ),

                    const Divider(),

                    //  OLD FEATURE: Settings section with styled toggles
                    _sectionLabel('Settings'),
                    ListTile(
                      leading: Icon(
                        _isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: const Color(0xFF667eea),
                      ),
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: Switch(
                        value: _isDarkMode,
                        onChanged: _toggleDarkMode,
                        activeColor: const Color(0xFF667eea),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        _notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: const Color(0xFF667eea),
                      ),
                      title: const Text(
                        'Notifications',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeColor: const Color(0xFF667eea),
                      ),
                    ),

                    const Divider(),

                    //  OLD FEATURE: Data section
                    _sectionLabel('Data'),
                    _buildMenuItem(
                      Icons.backup,
                      'Backup Data',
                          () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Feature coming soon')),
                      ),
                    ),
                    _buildMenuItem(
                      Icons.restore,
                      'Restore Data',
                          () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Feature coming soon')),
                      ),
                    ),
                    _buildMenuItem(
                      Icons.delete_forever,
                      'Clear All Data',
                      _clearAllData,
                      color: Colors.orange,
                    ),

                    const Divider(),

                    //  OLD FEATURE: About section
                    _sectionLabel('About'),
                    _buildMenuItem(
                      Icons.help,
                      'Help & Support',
                          () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text('Contact: support@financemanager.com'),
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      Icons.info,
                      'About App',
                          () => showAboutDialog(
                        context: context,
                        applicationName: 'Finance Manager',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.account_balance_wallet,
                          size: 50,
                          color: Color(0xFF667eea),
                        ),
                        children: const [
                          Text(
                            'A complete personal finance management app',
                          ),
                        ],
                      ),
                    ),
                    _buildMenuItem(
                      Icons.privacy_tip,
                      'Privacy Policy',
                          () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Your data is stored securely on Firebase'),
                        ),
                      ),
                    ),

                    const Divider(),

                    //  OLD FEATURE: Logout with confirmation
                    _buildMenuItem(
                      Icons.logout,
                      'Logout',
                      _logout,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  //  OLD FEATURE: Section label helper
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  //  OLD FEATURE: Styled stat chip in header
  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  //  OLD FEATURE: Styled menu item with arrow icon
  Widget _buildMenuItem(
      IconData icon,
      String title,
      VoidCallback onTap, {
        Color? color,
      }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF667eea)),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}