import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tuneverse/core/constants/app_constants.dart';
import 'package:tuneverse/core/di/profile_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/data/models/profile_entity.dart';

const _avatarEmojis = [
  '\u{1F3B5}', '\u{1F3B6}', '\u{1F3B8}', '\u{1F3B9}', '\u{1F3B7}', '\u{1F3BA}',
  '\u{1F941}', '\u{1F3BB}', '\u{1F3A4}', '\u{1F3A7}', '\u{1F3BC}', '\u{1F399}',
  '\u{1F31F}', '\u{2728}', '\u{1F525}', '\u{1F4AB}', '\u{26A1}', '\u{1F308}',
  '\u{1F98B}', '\u{1F33A}', '\u{1F319}', '\u{1F3A8}', '\u{1F48E}', '\u{1F451}',
  '\u{1F98A}', '\u{1F431}', '\u{1F984}', '\u{1F43C}', '\u{1F680}', '\u{1F3AF}',
  '\u{1F49C}', '\u{1F499}', '\u{1F49A}', '\u{1F9E1}', '\u{2764}\u{FE0F}', '\u{1F49B}',
];

const _accentColors = [
  0xFF6C63FF,
  0xFFFF6B6B,
  0xFF4ECDC4,
  0xFFFFD93D,
  0xFF6BCB77,
  0xFFFF8A5C,
  0xFF4D96FF,
  0xFFFF6B9D,
  0xFFA66CFF,
  0xFF20C997,
  0xFFE74C3C,
  0xFF3498DB,
];

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(allProfilesProvider);
    final activeProfile = ref.watch(activeProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: profilesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              'Could not load profiles',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onDarkSecondary,
              ),
            ),
          ),
          data: (profiles) => _Body(
            profiles: profiles,
            activeId: activeProfile?.id,
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profiles, required this.activeId});

  final List<ProfileEntity> profiles;
  final int? activeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAdd = profiles.length < AppConstants.maxProfileCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Who's listening?",
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.onDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap a profile to switch',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.onDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 28,
                      children: [
                        for (final profile in profiles)
                          _ProfileAvatar(
                            profile: profile,
                            isActive: profile.id == activeId,
                            onTap: () =>
                                ref.read(switchProfileProvider)(profile.id),
                            onLongPress: () =>
                                _showOptions(context, ref, profile),
                          ),
                        if (canAdd)
                          _AddButton(
                            onTap: () => _showForm(context, ref),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOptions(
    BuildContext context,
    WidgetRef ref,
    ProfileEntity profile,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _OptionsSheet(
        profile: profile,
        onEdit: () => _showForm(context, ref, existing: profile),
        onDelete: () => _confirmDelete(context, ref, profile),
        canDelete: profiles.length > 1,
      ),
    );
  }

  void _showForm(
    BuildContext context,
    WidgetRef ref, {
    ProfileEntity? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormSheet(existing: existing),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProfileEntity profile,
  ) {
    final repo = ref.read(profileRepositoryProvider);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Remove "${profile.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await repo.delete(profile.id);
              ref.invalidate(allProfilesProvider);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFCF6679),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid tiles
// ---------------------------------------------------------------------------

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  final ProfileEntity profile;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = Color(profile.accentColorValue);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(
                  color: isActive ? color : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Text(
                  profile.avatarEmoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              profile.name,
              style: GoogleFonts.plusJakartaSans(
                color: isActive ? AppTheme.onDark : AppTheme.onDarkSecondary,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceElevated,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: AppTheme.onDarkSecondary,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onDarkSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Options bottom sheet (long-press menu)
// ---------------------------------------------------------------------------

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
    required this.canDelete,
  });

  final ProfileEntity profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(profile.accentColorValue)
                      .withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    profile.avatarEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profile.name,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit Profile'),
          onTap: () {
            Navigator.of(context).pop();
            onEdit();
          },
        ),
        if (canDelete)
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: Color(0xFFCF6679),
            ),
            title: const Text(
              'Delete Profile',
              style: TextStyle(color: Color(0xFFCF6679)),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onDelete();
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Create / edit form bottom sheet
// ---------------------------------------------------------------------------

class _FormSheet extends ConsumerStatefulWidget {
  const _FormSheet({this.existing});

  final ProfileEntity? existing;

  @override
  ConsumerState<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends ConsumerState<_FormSheet> {
  late final TextEditingController _nameController;
  late String _selectedEmoji;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existing?.name ?? '',
    );
    _selectedEmoji =
        widget.existing?.avatarEmoji ?? _avatarEmojis.first;
    _selectedColor =
        widget.existing?.accentColorValue ?? _accentColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(profileRepositoryProvider);
    if (widget.existing != null) {
      await repo.update(
        widget.existing!.id,
        name,
        _selectedEmoji,
        _selectedColor,
      );
    } else {
      await repo.create(name, _selectedEmoji, _selectedColor);
    }
    ref.invalidate(allProfilesProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Edit Profile' : 'New Profile',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onDark,
                fontSize: 15,
              ),
              decoration: const InputDecoration(hintText: 'Profile name'),
              textCapitalization: TextCapitalization.words,
              autofocus: !isEditing,
            ),
            const SizedBox(height: 28),
            Text(
              'AVATAR',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onDarkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _avatarEmojis.length,
              itemBuilder: (context, index) {
                final emoji = _avatarEmojis[index];
                final selected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? Color(_selectedColor).withValues(alpha: 0.2)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(
                              color: Color(_selectedColor),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'COLOR',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onDarkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _accentColors.map((colorValue) {
                final selected = colorValue == _selectedColor;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedColor = colorValue),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(colorValue),
                      border: selected
                          ? Border.all(
                              color: AppTheme.onDark,
                              width: 2.5,
                            )
                          : null,
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            color: AppTheme.contrastColor(
                              Color(colorValue),
                            ),
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(_selectedColor),
                foregroundColor: AppTheme.contrastColor(
                  Color(_selectedColor),
                ),
              ),
              child: Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
