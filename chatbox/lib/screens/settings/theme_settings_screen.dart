// lib/screens/settings/theme_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/providers/theme_provider.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              context.read<ThemeProvider>().resetToDefault();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme reset to default')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            children: [
              // Theme Selection Section
              _buildSectionHeader('Chat Themes'),
              ...ChatTheme.predefinedThemes.map(
                (theme) => _buildThemeOption(context, theme, themeProvider),
              ),

              const Divider(),

              // Wallpaper Section
              _buildSectionHeader('Chat Wallpaper'),
              _buildWallpaperSection(context, themeProvider),

              const Divider(),

              // Preview Section
              _buildSectionHeader('Preview'),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sample chat bubble
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Text(
                            'U',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: themeProvider.currentTheme.isDark
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(context).colorScheme.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                          ),
                          child: Text(
                            'This is how your messages will look!',
                            style: TextStyle(
                              color: themeProvider.currentTheme.isDark
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Information Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customize your ChatBox experience with different themes and wallpapers. '
                      'Your theme preferences are saved automatically.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ChatTheme theme,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.currentTheme.id == theme.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.primaryColor
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getThemeIcon(theme), color: Colors.white, size: 20),
        ),
        title: Text(
          theme.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          _getThemeDescription(theme),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.primaryColor)
            : null,
        onTap: () {
          themeProvider.setTheme(theme);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Theme changed to ${theme.name}')),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildWallpaperSection(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Column(
      children: [
        // Current wallpaper preview
        if (themeProvider.wallpaperUrl != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(themeProvider.wallpaperUrl!),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.3),
              ),
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () {
                    themeProvider.setWallpaper(null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wallpaper removed')),
                    );
                  },
                ),
              ),
            ),
          ),

        // Wallpaper options
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement wallpaper picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wallpaper picker coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Choose Image'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        themeProvider.setWallpaper(null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Wallpaper removed')),
                        );
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Remove'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Choose a wallpaper to personalize your chat background',
                style: TextStyle(fontSize: 12, color: AppColors.grey600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getThemeIcon(ChatTheme theme) {
    switch (theme.id) {
      case 'light':
        return Icons.wb_sunny;
      case 'dark':
        return Icons.nightlight_round;
      case 'blue':
        return Icons.water;
      case 'purple':
        return Icons.spa;
      case 'green':
        return Icons.grass;
      default:
        return Icons.palette;
    }
  }

  String _getThemeDescription(ChatTheme theme) {
    switch (theme.id) {
      case 'light':
        return 'Clean and bright interface';
      case 'dark':
        return 'Easy on the eyes in low light';
      case 'blue':
        return 'Calming ocean-inspired colors';
      case 'purple':
        return 'Elegant purple theme';
      case 'green':
        return 'Fresh and natural feel';
      default:
        return 'Custom theme';
    }
  }
}
