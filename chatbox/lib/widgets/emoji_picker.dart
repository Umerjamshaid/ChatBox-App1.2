// lib/widgets/emoji_picker.dart
import 'package:flutter/material.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmojiPicker extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final Function(String)? onStickerSelected;
  final List<String> recentEmojis;
  final int crossAxisCount;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.onStickerSelected,
    this.recentEmojis = const [],
    this.crossAxisCount = 8,
  });

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _customStickers = [];
  bool _showEmojiPicker = true;

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
    _tabController = TabController(length: 7, vsync: this);
    _loadCustomStickers();
  }

  Future<void> _loadCustomStickers() async {
    final prefs = await SharedPreferences.getInstance();
    final stickers = prefs.getStringList('custom_stickers') ?? [];
    setState(() {
      _customStickers = stickers;
    });
  }

  Future<void> _addCustomSticker() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final stickers = List<String>.from(_customStickers)..add(image.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('custom_stickers', stickers);

      setState(() {
        _customStickers = stickers;
      });
    }
  }

  Future<void> _removeSticker(int index) async {
    final stickers = List<String>.from(_customStickers)..removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_stickers', stickers);

    setState(() {
      _customStickers = stickers;
    });
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
          // Toggle buttons and tab bar
          SizedBox(
            height: 50,
            child: Row(
              children: [
                // Toggle buttons
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _showEmojiPicker = true),
                      style: TextButton.styleFrom(
                        backgroundColor: _showEmojiPicker
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Text(
                        'Emoji',
                        style: TextStyle(
                          color: _showEmojiPicker
                              ? AppColors.primary
                              : AppColors.grey600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showEmojiPicker = false),
                      style: TextButton.styleFrom(
                        backgroundColor: !_showEmojiPicker
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Text(
                        'Stickers',
                        style: TextStyle(
                          color: !_showEmojiPicker
                              ? AppColors.primary
                              : AppColors.grey600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Add sticker button (only for stickers)
                if (!_showEmojiPicker)
                  IconButton(
                    icon: Icon(Icons.add, color: AppColors.primary),
                    onPressed: _addCustomSticker,
                    tooltip: 'Add custom sticker',
                  ),
              ],
            ),
          ),

          // Content based on toggle
          Expanded(
            child: _showEmojiPicker
                ? _buildEmojiPicker()
                : _buildStickerPicker(),
          ),

          // Recent emojis (if any and showing emojis)
          if (_showEmojiPicker && widget.recentEmojis.isNotEmpty)
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

  Widget _buildEmojiPicker() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildStickerPicker() {
    if (_customStickers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sticky_note_2, size: 48, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'No custom stickers yet',
              style: TextStyle(color: AppColors.grey600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add stickers from your gallery',
              style: TextStyle(color: AppColors.grey500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _customStickers.length,
      itemBuilder: (context, index) {
        final stickerPath = _customStickers[index];
        return GestureDetector(
          onTap: () {
            if (widget.onStickerSelected != null) {
              widget.onStickerSelected!(stickerPath);
            }
          },
          onLongPress: () => _showStickerOptions(context, index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(stickerPath), // For demo, using asset
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStickerOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.danger),
              title: const Text('Remove Sticker'),
              onTap: () {
                _removeSticker(index);
                Navigator.pop(context);
              },
            ),
          ],
        ),
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
