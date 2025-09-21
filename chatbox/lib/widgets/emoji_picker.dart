// lib/widgets/emoji_picker.dart
import 'package:flutter/material.dart';
import 'package:chatbox/constants/colors.dart';

class EmojiPicker extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final List<String> recentEmojis;
  final int crossAxisCount;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.recentEmojis = const [],
    this.crossAxisCount = 8,
  });

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _smileys = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '😂',
    '🤣',
    '😊',
    '😇',
    '🙂',
    '🙃',
    '😉',
    '😌',
    '😍',
    '🥰',
    '😘',
    '😗',
    '😙',
    '😚',
    '😋',
    '😛',
    '😝',
    '😜',
    '🤪',
    '🤨',
    '🧐',
    '🤓',
    '😎',
    '🤩',
    '🥳',
    '😏',
  ];

  final List<String> _gestures = [
    '👍',
    '👎',
    '👌',
    '✌️',
    '🤞',
    '🤟',
    '🤘',
    '🤙',
    '👈',
    '👉',
    '👆',
    '🖕',
    '👇',
    '☝️',
    '👋',
    '🤚',
    '🖐️',
    '✋',
    '🖖',
    '👏',
    '🙌',
    '🤲',
    '🤝',
    '🙏',
    '✍️',
    '💪',
    '🦾',
    '🦿',
    '🦵',
    '🦶',
    '👂',
    '🦻',
  ];

  final List<String> _hearts = [
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '🤍',
    '🤎',
    '💔',
    '❤️‍🔥',
    '❤️‍🩹',
    '💕',
    '💞',
    '💓',
    '💗',
    '💖',
    '💘',
    '💝',
    '💟',
    '☮️',
    '✝️',
    '☪️',
    '🕉️',
    '☸️',
    '✡️',
    '🔯',
    '🕎',
    '☯️',
    '☦️',
    '🛐',
    '⛎',
  ];

  final List<String> _animals = [
    '🐶',
    '🐱',
    '🐭',
    '🐹',
    '🐰',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🐯',
    '🦁',
    '🐮',
    '🐷',
    '🐽',
    '🐸',
    '🐵',
    '🙈',
    '🙉',
    '🙊',
    '🐒',
    '🐔',
    '🐧',
    '🐦',
    '🐤',
    '🐣',
    '🐥',
    '🦆',
    '🦅',
    '🦉',
    '🦇',
    '🐺',
    '🐗',
  ];

  final List<String> _food = [
    '🍎',
    '🍊',
    '🍋',
    '🍌',
    '🍉',
    '🍇',
    '🍓',
    '🫐',
    '🍈',
    '🍒',
    '🍑',
    '🥭',
    '🍍',
    '🥥',
    '🥝',
    '🍅',
    '🍆',
    '🥑',
    '🥦',
    '🥬',
    '🥒',
    '🌶️',
    '🫑',
    '🌽',
    '🥕',
    '🫒',
    '🧄',
    '🧅',
    '🥔',
    '🍠',
    '🥐',
    '🥖',
  ];

  final List<String> _activities = [
    '⚽',
    '🏀',
    '🏈',
    '⚾',
    '🥎',
    '🎾',
    '🏐',
    '🏉',
    '🥏',
    '🎱',
    '🪀',
    '🏓',
    '🏸',
    '🏒',
    '🏑',
    '🥍',
    '🏏',
    '🪃',
    '🥅',
    '⛳',
    '🪁',
    '🏹',
    '🎣',
    '🤿',
    '🥊',
    '🥋',
    '🎽',
    '🛹',
    '🛷',
    '⛸️',
    '🥌',
    '🎿',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Tab bar
          SizedBox(
            height: 50,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey600,
              tabs: const [
                Tab(icon: Text('😀', style: TextStyle(fontSize: 20))),
                Tab(icon: Text('👍', style: TextStyle(fontSize: 20))),
                Tab(icon: Text('❤️', style: TextStyle(fontSize: 20))),
                Tab(icon: Text('🐶', style: TextStyle(fontSize: 20))),
                Tab(icon: Text('🍎', style: TextStyle(fontSize: 20))),
                Tab(icon: Text('⚽', style: TextStyle(fontSize: 20))),
              ],
            ),
          ),

          // Emoji grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmojiGrid(_smileys),
                _buildEmojiGrid(_gestures),
                _buildEmojiGrid(_hearts),
                _buildEmojiGrid(_animals),
                _buildEmojiGrid(_food),
                _buildEmojiGrid(_activities),
              ],
            ),
          ),

          // Recent emojis (if any)
          if (widget.recentEmojis.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Recent:',
                    style: TextStyle(color: AppColors.grey600, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.recentEmojis.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => widget.onEmojiSelected(
                            widget.recentEmojis[index],
                          ),
                          child: Container(
                            width: 35,
                            height: 35,
                            margin: const EdgeInsets.only(right: 8),
                            alignment: Alignment.center,
                            child: Text(
                              widget.recentEmojis[index],
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid(List<String> emojis) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return GestureDetector(
          onTap: () => widget.onEmojiSelected(emoji),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      },
    );
  }
}
