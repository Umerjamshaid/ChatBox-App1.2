// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' hide MessageType;
import 'package:chatbox/services/search_service.dart' as search_service;
import 'package:chatbox/services/auth_service.dart';
import 'package:chatbox/services/qr_service.dart';
import 'package:chatbox/services/location_service.dart';
import 'package:chatbox/services/contact_service.dart';
import 'package:chatbox/models/user_model.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late search_service.SearchService _searchService;
  late ContactService _contactService;
  late LocationService _locationService;

  search_service.SearchResult _searchResult =
      const search_service.SearchResult();
  List<search_service.SearchHistoryItem> _searchHistory = [];
  List<search_service.SavedSearch> _savedSearches = [];
  List<ContactData> _contacts = [];
  List<User> _suggestedUsers = [];

  bool _isLoading = false;
  bool _showFilters = false;
  search_service.SearchType _currentSearchType = search_service.SearchType.all;

  // Filter options
  DateTime? _startDate;
  DateTime? _endDate;
  String? _senderId;
  search_service.MessageType _messageType = search_service.MessageType.all;
  double _nearbyRadius = 10.0; // km

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeServices();
    _loadSearchHistory();
    _loadSavedSearches();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _searchService = search_service.SearchService(prefs);
    _contactService = ContactService(prefs);
    _locationService = LocationService();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final service = search_service.SearchService(prefs);
    final history = await service.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _loadSavedSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final service = search_service.SearchService(prefs);
    final searches = await service.getSavedSearches();
    setState(() {
      _savedSearches = searches;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final filters = search_service.SearchFilters(
        startDate: _startDate,
        endDate: _endDate,
        senderId: _senderId,
        messageType: _messageType,
      );

      final result = await _searchService.globalSearch(
        query,
        _currentSearchType,
        filters: filters,
      );

      setState(() {
        _searchResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await _contactService.getSyncedContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load contacts: $e')));
    }
  }

  Future<void> _syncContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await _contactService.syncContactsWithChatBox();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts synced successfully!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sync contacts: $e')));
    }
  }

  Future<void> _findNearbyUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get your location')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // In a real app, this would query the backend for nearby users
      // For now, we'll show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found users within ${_nearbyRadius}km of your location',
          ),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to find nearby users: $e')),
      );
    }
  }

  Future<void> _loadSuggestedUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suggestedUsers = await _searchService.getSuggestedUsers();
      setState(() {
        _suggestedUsers = suggestedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load suggestions: $e')));
    }
  }

  void _startChatWithUser(User user) {
    // Navigate to chat with this user
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Starting chat with ${user.name}')));
    // TODO: Implement navigation to chat screen
  }

  void _showQRCode() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.getCurrentChatUser();

    if (user != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QRService.generateQRCode(
                QRService.generateUserQRData(user),
                size: 200.0,
              ),
              const SizedBox(height: 16),
              Text(
                user.name ?? 'ChatBox User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan this code to add me as a friend',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                QRService.shareUserProfile(user);
                Navigator.pop(context);
              },
              child: const Text('Share'),
            ),
          ],
        ),
      );
    }
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date range
              const Text(
                'Date Range',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      child: Text(
                        _startDate?.toString().split(' ')[0] ?? 'Start Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      child: Text(
                        _endDate?.toString().split(' ')[0] ?? 'End Date',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Message type filter
              const Text(
                'Message Type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButton<search_service.MessageType>(
                value: _messageType,
                isExpanded: true,
                items: search_service.MessageType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _messageType = value);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Nearby radius
              const Text(
                'Nearby Radius (km)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _nearbyRadius,
                min: 1,
                max: 100,
                divisions: 99,
                label: '${_nearbyRadius.round()} km',
                onChanged: (value) {
                  setState(() => _nearbyRadius = value);
                },
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _senderId = null;
                          _messageType = search_service.MessageType.all;
                          _nearbyRadius = 10.0;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Discover'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(text: 'Contacts', icon: Icon(Icons.contacts)),
            Tab(text: 'Nearby', icon: Icon(Icons.location_on)),
            Tab(text: 'Discover', icon: Icon(Icons.explore)),
            Tab(text: 'QR Code', icon: Icon(Icons.qr_code)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildContactsTab(),
          _buildNearbyTab(),
          _buildDiscoverTab(),
          _buildQRCodeTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: 'Search messages, users, channels...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(
                          () => _searchResult =
                              const search_service.SearchResult(),
                        );
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onSubmitted: _performSearch,
          ),
        ),

        // Search type selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: search_service.SearchType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type.toString().split('.').last.toUpperCase()),
                  selected: _currentSearchType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _currentSearchType = type);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Search results
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResult.messages.isEmpty &&
                    _searchResult.users.isEmpty &&
                    _searchResult.channels.isEmpty
              ? _buildEmptyState()
              : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildContactsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _syncContacts,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Contacts'),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.contacts, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No contacts synced',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sync your contacts to find friends on ChatBox',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          contact.displayName?.substring(0, 1).toUpperCase() ??
                              '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(contact.displayName ?? 'Unknown'),
                      subtitle: Text(
                        contact.phoneNumbers.isNotEmpty
                            ? contact.phoneNumbers.first
                            : 'No phone number',
                      ),
                      trailing: contact.isRegistered
                          ? const Icon(Icons.chat, color: Colors.green)
                          : const Icon(Icons.person_add, color: Colors.grey),
                      onTap: () {
                        if (contact.isRegistered) {
                          // Start chat with this user
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Starting chat with ${contact.displayName}',
                              ),
                            ),
                          );
                        } else {
                          // Invite this contact
                          QRService.shareInviteLink(
                            ChatUser(
                              id: 'temp_${contact.id}',
                              name: contact.displayName,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNearbyTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Find ChatBox users near you',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Discover people in your area (${_nearbyRadius.round()}km radius)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _findNearbyUsers,
                icon: const Icon(Icons.location_searching),
                label: const Text('Find Nearby Users'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Location-based discovery',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find and connect with people nearby',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Discover new friends',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Find people to connect with on ChatBox',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadSuggestedUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Suggestions'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _suggestedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.explore, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No suggestions available',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join some channels to get friend suggestions',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _suggestedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _suggestedUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.image != null
                            ? NetworkImage(user.image!)
                            : null,
                        child: user.image == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user.name ?? 'Unknown User'),
                      subtitle: Text('ID: ${user.id}'),
                      trailing: ElevatedButton(
                        onPressed: () => _startChatWithUser(user),
                        child: const Text('Connect'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQRCodeTab() {
    final authService = Provider.of<AuthService>(context);

    return FutureBuilder<ChatUser?>(
      future: authService.getCurrentChatUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: user != null
                      ? QRService.generateQRCode(
                          QRService.generateUserQRData(user),
                          size: 200,
                        )
                      : const Icon(Icons.error, size: 200, color: Colors.red),
                ),
                const SizedBox(height: 24),
                Text(
                  user?.name ?? 'ChatBox User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan this code to add me as a friend',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showQRCode,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (user != null) {
                            QRService.shareUserProfile(user);
                          }
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share Profile'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Search for messages, users, and channels',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start typing to find what you\'re looking for',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      children: [
        if (_searchResult.messages.isNotEmpty) ...[
          _buildSectionHeader('Messages', _searchResult.messages.length),
          ..._searchResult.messages.map(
            (message) => _buildMessageResult(message),
          ),
        ],
        if (_searchResult.users.isNotEmpty) ...[
          _buildSectionHeader('Users', _searchResult.users.length),
          ..._searchResult.users.map((user) => _buildUserResult(user)),
        ],
        if (_searchResult.channels.isNotEmpty) ...[
          _buildSectionHeader('Channels', _searchResult.channels.length),
          ..._searchResult.channels.map(
            (channel) => _buildChannelResult(channel),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '$title ($count)',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMessageResult(Message message) {
    return ListTile(
      leading: const Icon(Icons.message),
      title: Text(message.text ?? 'No text'),
      subtitle: Text('From: ${message.user?.name ?? 'Unknown'}'),
      onTap: () {
        // Navigate to the message in chat
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Navigate to message')));
      },
    );
  }

  Widget _buildUserResult(User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.image != null ? NetworkImage(user.image!) : null,
        child: user.image == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.name ?? 'Unknown User'),
      subtitle: Text('ID: ${user.id}'),
      onTap: () {
        // Start chat with user
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Start chat with ${user.name}')));
      },
    );
  }

  Widget _buildChannelResult(Channel channel) {
    return ListTile(
      leading: const Icon(Icons.group),
      title: Text(channel.name ?? 'Unnamed Channel'),
      subtitle: Text('ID: ${channel.id}'),
      onTap: () {
        // Navigate to channel
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Open channel ${channel.name}')));
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}
