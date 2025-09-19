// lib/screens/contacts/contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:chatbox/constants/colors.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts, size: 80, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'Contacts',
              style: TextStyle(
                fontSize: 24,
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your contacts will appear here',
              style: TextStyle(fontSize: 16, color: AppColors.grey600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
