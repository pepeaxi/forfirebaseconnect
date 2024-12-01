import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Abdulloh Azizov',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '+998 90 123 45 67',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSettingsItem(
            icon: Icons.notifications,
            title: 'Bildirishnomalar',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.language,
            title: 'Til',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.dark_mode,
            title: 'Tungi rejim',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.security,
            title: 'Xavfsizlik',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.help,
            title: 'Yordam',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.info,
            title: 'Ilova haqida',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
