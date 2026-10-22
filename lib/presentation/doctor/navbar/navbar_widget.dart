import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../widgets/app_version_label.dart';

class Navbar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const Navbar({
    Key? key,
    required this.scaffoldKey,
  }) : super(key: key);

  // Method to clear session values and navigate to the login screen
  Future<void> _logout(BuildContext context) async {
    await BiometricAuthService.clearSessionPreservingPreferences();
    Navigator.pushReplacementNamed(context, '/sign_in_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0XFF4675C0).withOpacity(0.05),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Enhanced Header
            _buildEnhancedHeader(context),

            SizedBox(height: 16),

            // Menu Items
            _buildMenuItem(
              context: context,
              icon: Icons.dashboard_rounded,
              title: 'Dashboard',
              subtitle: 'View patient overview',
              route: '/doctordashboard_screen',
              iconColor: Color(0XFF4675C0),
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.medical_services_rounded,
              title: 'Quotations',
              subtitle: 'Manage patient quotes',
              route: '/quotationrequest_dpatient_screen',
              iconColor: Colors.orange[600]!,
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.shopping_bag_rounded,
              title: 'Orders',
              subtitle: 'Track patient orders',
              route: '/dorder_list_screen',
              iconColor: Colors.green[600]!,
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.description_rounded,
              title: 'Prescriptions',
              subtitle: 'View written prescriptions',
              route: '/written_prescription_list',
              iconColor: Colors.teal[600]!,
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.person_rounded,
              title: 'Profile',
              subtitle: 'Manage doctor account',
              route: '/profile_screen',
              iconColor: Colors.purple[600]!,
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.settings_rounded,
              title: 'Settings',
              subtitle: 'Security & biometric preferences',
              route: '/profile_screen',
              iconColor: Colors.grey[600]!,
            ),

            Divider(
              height: 32,
              thickness: 1,
              color: Colors.grey[300],
              indent: 24,
              endIndent: 24,
            ),

            // Logout Section
            _buildLogoutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0XFF4675C0),
            Color(0XFF4675C0).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0XFF4675C0).withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Container with enhanced styling
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Image.asset(
                  ImageConstant.imgRectangle159,
                  height: 48,
                  width: 48,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: 20),

              // App Name with enhanced typography
              Text(
                'QuikDawa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Your Health, Our Priority',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),

              SizedBox(height: 16),

              // User Info Section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppVersionLabel(inDrawerHeader: true),
                          Text(
                            'Doctor Account',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    String? route,
    VoidCallback? onTap,
    required Color iconColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.grey[400],
          size: 16,
        ),
        onTap: onTap ??
            () {
              Navigator.pushNamed(context, route!);
            },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.red[50],
        border: Border.all(
          color: Colors.red[200]!,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.logout_rounded,
            color: Colors.red[600],
            size: 24,
          ),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        subtitle: Text(
          'Sign out of your account',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.red[600],
          ),
        ),
        onTap: () => _logout(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
