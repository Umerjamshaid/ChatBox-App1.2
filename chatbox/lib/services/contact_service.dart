// lib/services/contact_service.dart
import 'dart:convert';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactData {
  final String id;
  final String? displayName;
  final List<String> phoneNumbers;
  final List<String> emails;
  final String? photo; // Base64 encoded photo
  final bool isRegistered; // Whether this contact is registered on ChatBox
  final String? chatBoxUserId;

  const ContactData({
    required this.id,
    this.displayName,
    this.phoneNumbers = const [],
    this.emails = const [],
    this.photo,
    this.isRegistered = false,
    this.chatBoxUserId,
  });

  ContactData copyWith({
    String? id,
    String? displayName,
    List<String>? phoneNumbers,
    List<String>? emails,
    String? photo,
    bool? isRegistered,
    String? chatBoxUserId,
  }) {
    return ContactData(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      emails: emails ?? this.emails,
      photo: photo ?? this.photo,
      isRegistered: isRegistered ?? this.isRegistered,
      chatBoxUserId: chatBoxUserId ?? this.chatBoxUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'phoneNumbers': phoneNumbers,
      'emails': emails,
      'photo': photo,
      'isRegistered': isRegistered,
      'chatBoxUserId': chatBoxUserId,
    };
  }

  factory ContactData.fromJson(Map<String, dynamic> json) {
    return ContactData(
      id: json['id'],
      displayName: json['displayName'],
      phoneNumbers: List<String>.from(json['phoneNumbers'] ?? []),
      emails: List<String>.from(json['emails'] ?? []),
      photo: json['photo'],
      isRegistered: json['isRegistered'] ?? false,
      chatBoxUserId: json['chatBoxUserId'],
    );
  }

  factory ContactData.fromContact(Contact contact) {
    String? photoBase64;
    if (contact.photo != null) {
      photoBase64 = base64Encode(contact.photo!);
    }

    return ContactData(
      id: contact.id,
      displayName: contact.displayName,
      phoneNumbers: contact.phones.map((phone) => phone.number).toList(),
      emails: contact.emails.map((email) => email.address).toList(),
      photo: photoBase64,
    );
  }
}

class ContactService {
  final SharedPreferences _prefs;
  static const String _contactsKey = 'synced_contacts';
  static const String _lastSyncKey = 'last_contact_sync';

  ContactService(this._prefs);

  // Check contact permissions
  Future<bool> checkContactPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  // Request contact permissions
  Future<bool> requestContactPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  // Get all contacts
  Future<List<ContactData>> getContacts() async {
    try {
      if (!await checkContactPermission()) {
        if (!await requestContactPermission()) {
          throw Exception('Contact permission denied');
        }
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      return contacts
          .map((contact) => ContactData.fromContact(contact))
          .toList();
    } catch (e) {
      print('Error getting contacts: $e');
      return [];
    }
  }

  // Sync contacts with ChatBox users
  Future<List<ContactData>> syncContactsWithChatBox() async {
    try {
      final contacts = await getContacts();
      final syncedContacts = <ContactData>[];

      // In a real implementation, you would send contact phone numbers/emails
      // to your backend to check which ones are registered ChatBox users
      // For now, we'll simulate this by marking some contacts as registered

      for (final contact in contacts) {
        // Simulate checking if contact is registered
        // This would be done by your backend API
        final isRegistered = _simulateUserCheck(contact);

        syncedContacts.add(
          contact.copyWith(
            isRegistered: isRegistered,
            chatBoxUserId: isRegistered ? 'user_${contact.id}' : null,
          ),
        );
      }

      // Save synced contacts
      await _saveSyncedContacts(syncedContacts);
      await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return syncedContacts;
    } catch (e) {
      print('Error syncing contacts: $e');
      return [];
    }
  }

  // Get synced contacts from cache
  Future<List<ContactData>> getSyncedContacts() async {
    try {
      final contactsJson = _prefs.getString(_contactsKey);
      if (contactsJson == null) return [];

      final contactsList = List<Map<String, dynamic>>.from(
        (jsonDecode(contactsJson) as List).map(
          (item) => item as Map<String, dynamic>,
        ),
      );

      return contactsList.map((json) => ContactData.fromJson(json)).toList();
    } catch (e) {
      print('Error loading synced contacts: $e');
      return [];
    }
  }

  // Get registered ChatBox contacts
  Future<List<ContactData>> getRegisteredContacts() async {
    final contacts = await getSyncedContacts();
    return contacts.where((contact) => contact.isRegistered).toList();
  }

  // Search contacts
  Future<List<ContactData>> searchContacts(String query) async {
    final contacts = await getSyncedContacts();

    if (query.isEmpty) return contacts;

    final lowercaseQuery = query.toLowerCase();

    return contacts.where((contact) {
      final name = contact.displayName?.toLowerCase() ?? '';
      return name.contains(lowercaseQuery) ||
          contact.phoneNumbers.any((phone) => phone.contains(query)) ||
          contact.emails.any(
            (email) => email.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  // Get last sync time
  DateTime? getLastSyncTime() {
    final lastSyncStr = _prefs.getString(_lastSyncKey);
    return lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
  }

  // Check if contacts need syncing (older than 24 hours)
  bool needsSync() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastSync);
    return difference.inHours >= 24;
  }

  // Private methods
  Future<void> _saveSyncedContacts(List<ContactData> contacts) async {
    final contactsJson = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await _prefs.setString(_contactsKey, contactsJson);
  }

  // Simulate checking if a contact is registered (replace with real API call)
  bool _simulateUserCheck(ContactData contact) {
    // Simulate that some contacts are registered
    // In reality, this would check against your backend
    return contact.phoneNumbers.isNotEmpty &&
        contact.phoneNumbers.first.length > 8 &&
        contact.id.hashCode % 3 == 0; // Every 3rd contact is "registered"
  }

  // Clear cached contacts
  Future<void> clearSyncedContacts() async {
    await _prefs.remove(_contactsKey);
    await _prefs.remove(_lastSyncKey);
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
