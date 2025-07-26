import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/app_theme.dart';
import 'landing_screen.dart';
import 'wallet_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      // AppBar removed for a cleaner look
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: responsive.screenPadding,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: responsive.mainSpacing * 0.2),
                // Title
                Text(
                  'Account',
                  style: TextStyle(
                    fontSize: responsive.titleSize * 1.1,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: responsive.mainSpacing * 2),

                // Profile Info Section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: responsive.mainIconSize * 0.7,
                        backgroundImage: const AssetImage(
                          'assets/images/dp.png',
                        ),
                      ),
                      SizedBox(height: responsive.mainSpacing),
                      Text(
                        'Mark Tom',
                        style: TextStyle(
                          fontSize: responsive.titleSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      SizedBox(height: responsive.mainSpacing * 0.3),
                      Text(
                        'mark.tom@email.com',
                        style: TextStyle(
                          fontSize: responsive.subtitleSize,
                          color: Colors.grey.shade600,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.mainSpacing * 3),

                // Menu Options
                _buildMenuList(responsive, context),

                SizedBox(height: responsive.mainSpacing * 2),

                // Log Out Button
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LandingScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: responsive.subtitleSize,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.screenNavbarSpace),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for the list of menu items
  Widget _buildMenuList(Responsive responsive, BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.wallet_outlined,
            title: 'Wallet',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
            hasTrailing: false, // Last item
          ),
        ],
      ),
    );
  }

  // Helper for individual list tiles
  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool hasTrailing = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing:
          hasTrailing
              ? const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black45,
              )
              : null,
      onTap: onTap,
    );
  }

  // Helper for the divider
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}
