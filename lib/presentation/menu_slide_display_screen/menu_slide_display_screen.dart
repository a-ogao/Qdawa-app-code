import 'package:flutter/material.dart';

class MenuSlideDisplayScreen extends StatelessWidget {
  const MenuSlideDisplayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigation Bar"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/profile_pic.png'),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Jaspreet Singh",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const Divider(thickness: 1),
          // Menu Options
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(context, "Dashboard", Icons.dashboard),
                _buildMenuItem(
                    context, "Quotation Requests", Icons.request_page),
                _buildMenuItem(context, "My Orders", Icons.shopping_cart),
                _buildMenuItem(
                    context, "Transactions", Icons.account_balance_wallet),
                _buildMenuItem(context, "Profile", Icons.person),
                _buildMenuItem(context, "Support", Icons.support),
                _buildMenuItem(context, "Logout", Icons.logout,
                    isLastItem: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds each menu item row
  Widget _buildMenuItem(BuildContext context, String title, IconData icon,
      {bool isLastItem = false}) {
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: isLastItem ? 16 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Add navigation or actions for each menu item here
          print('$title tapped');
        },
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: MenuSlideDisplayScreen(),
  ));
}
