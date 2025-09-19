// lib/widgets/search_delegate.dart
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/screens/chat/chat_screen.dart';

class ChatSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search chats, users, and messages...';

  @override
  TextStyle get searchFieldStyle =>
      TextStyle(color: AppColors.onSurface, fontSize: 16);

  @override
  InputDecorationTheme get searchFieldDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: searchFieldDecorationTheme,
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState();
    }

    return FutureBuilder<List<Channel>>(
      future: _searchChannels(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final channels = snapshot.data ?? [];
        if (channels.isEmpty) {
          return _buildNoResultsState();
        }

        return _buildSearchResults(channels);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches();
    }

    return FutureBuilder<List<Channel>>(
      future: _searchChannels(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final channels = snapshot.data ?? [];
        return _buildSearchResults(channels);
      },
    );
  }

  Future<List<Channel>> _searchChannels(String searchQuery) async {
    if (searchQuery.isEmpty) {
      return [];
    }

    try {
      // For now, return empty list as we need to implement proper search
      // This would require proper GetStream search implementation
      return [];
    } catch (e) {
      return [];
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'Search for chats',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find conversations, users, and messages',
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(fontSize: 16, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            'Search failed',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'Recent searches',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent searches will appear here',
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Channel> channels) {
    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return StreamBuilder<Message?>(
          stream: channel.state?.lastMessageStream,
          builder: (context, snapshot) {
            final lastMessage = snapshot.data;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.grey200,
                  backgroundImage: channel.image != null
                      ? NetworkImage(channel.image!)
                      : null,
                  child: channel.image == null
                      ? Text(
                          channel.name?.substring(0, 1).toUpperCase() ?? '#',
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  channel.name ?? 'Unknown Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: lastMessage != null
                    ? Text(
                        _formatMessagePreview(lastMessage),
                        style: TextStyle(
                          color: AppColors.grey600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        'No messages yet',
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                onTap: () {
                  close(context, '');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(channel: channel),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatMessagePreview(Message message) {
    if (message.text?.isNotEmpty == true) {
      return message.text!;
    }

    if (message.attachments?.isNotEmpty == true) {
      final attachment = message.attachments!.first;
      switch (attachment.type) {
        case 'image':
          return '📷 Photo';
        case 'video':
          return '🎥 Video';
        case 'file':
          return '📎 File';
        default:
          return '📎 Attachment';
      }
    }

    return 'Message';
  }
}
