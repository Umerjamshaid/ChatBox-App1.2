// lib/screens/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/services/auth_service.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/screens/chat/chat_list_screen.dart';
import 'package:chatbox/screens/groups/groups_screen.dart';
import 'package:chatbox/screens/contacts/contacts_screen.dart';
import 'package:chatbox/screens/profile/profile_screen.dart';
import 'package:chatbox/widgets/search_delegate.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const ChatListScreen(),
    const GroupsScreen(),
    const ContactsScreen(),
    const ProfileScreen(),
  ];

  static const List<String> _titles = [
    'Chats',
    'Groups',
    'Contacts',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSearch() {
    // Navigate to search screen or show search overlay
    // For now, we'll show a simple search dialog
    showSearch(context: context, delegate: ChatSearchDelegate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _buildAppBarActions(),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
            tooltip: 'View your conversations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
            tooltip: 'View your group chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            activeIcon: Icon(Icons.contacts),
            label: 'Contacts',
            tooltip: 'View your contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
            tooltip: 'View your profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey600,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  List<Widget> _buildAppBarActions() {
    switch (_selectedIndex) {
      case 0: // Chats
        return [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
            tooltip: 'Search chats',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle menu actions
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new_group', child: Text('New Group')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'help', child: Text('Help')),
            ],
          ),
        ];
      case 1: // Groups
        return [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
            tooltip: 'Search groups',
          ),
        ];
      case 2: // Contacts
        return [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
            tooltip: 'Search contacts',
          ),
        ];
      case 3: // Profile
        return [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
            tooltip: 'Settings',
          ),
        ];
      default:
        return [];
    }
  }

  Widget? _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 0: // Chats
        return FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to new chat screen
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_comment),
          tooltip: 'Start new chat',
        );
      case 1: // Groups
        return FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to create group screen
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.group_add),
          tooltip: 'Create new group',
        );
      case 2: // Contacts
        return FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to add contact screen
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.person_add),
          tooltip: 'Add new contact',
        );
      default:
        return null;
    }
  }
}
