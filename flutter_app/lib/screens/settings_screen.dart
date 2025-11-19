import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/database_service.dart';
import 'dart:convert';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const _SectionHeader(title: 'Data Management'),
        
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Export Notes'),
          subtitle: const Text('Export all notes as JSON'),
          onTap: () => _exportNotes(context, ref),
        ),
        
        ListTile(
          leading: const Icon(Icons.delete_sweep),
          title: const Text('Clear All Notes'),
          subtitle: const Text('Delete all saved notes'),
          onTap: () => _confirmClearNotes(context, ref),
        ),
        
        const Divider(),
        
        const _SectionHeader(title: 'About'),
        
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Version'),
          subtitle: const Text('1.0.0'),
        ),
        
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('Source Code'),
          subtitle: const Text('github.com/athulkannan2000/audio-player'),
          onTap: () {
            // Open GitHub repository
          },
        ),
        
        const Divider(),
        
        const _SectionHeader(title: 'Remote Control'),
        
        const ListTile(
          leading: Icon(Icons.bluetooth),
          title: Text('ESP32 Remote'),
          subtitle: Text(
            'Use the Bluetooth icon in the top bar to pair your ESP32 remote',
          ),
        ),
        
        const _CommandReference(),
      ],
    );
  }

  void _exportNotes(BuildContext context, WidgetRef ref) async {
    try {
      final notesManager = ref.read(notesManagerProvider);
      final notes = await notesManager.exportNotes();
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(notes);
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exported Notes'),
            content: SingleChildScrollView(
              child: SelectableText(jsonString),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting notes: $e')),
        );
      }
    }
  }

  void _confirmClearNotes(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notes'),
        content: const Text(
          'Are you sure you want to delete all notes? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final dbService = ref.read(databaseServiceProvider);
                await dbService.clearAllNotes();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notes cleared')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error clearing notes: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CommandReference extends StatelessWidget {
  const _CommandReference();

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.help_outline),
      title: const Text('Remote Button Functions'),
      children: [
        _CommandItem(
          icon: Icons.play_arrow,
          label: 'Play/Pause',
          description: 'Toggle playback',
        ),
        _CommandItem(
          icon: Icons.skip_next,
          label: 'Next',
          description: 'Skip forward 15 seconds',
        ),
        _CommandItem(
          icon: Icons.skip_previous,
          label: 'Previous',
          description: 'Skip backward 15 seconds',
        ),
        _CommandItem(
          icon: Icons.volume_up,
          label: 'Volume +/-',
          description: 'Adjust volume',
        ),
        _CommandItem(
          icon: Icons.speed,
          label: 'Speed',
          description: 'Cycle playback speed',
        ),
        _CommandItem(
          icon: Icons.repeat,
          label: 'Repeat',
          description: 'Cycle repeat mode',
        ),
        _CommandItem(
          icon: Icons.note_add,
          label: 'Note',
          description: 'Create timestamped note',
        ),
      ],
    );
  }
}

class _CommandItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;

  const _CommandItem({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(label),
      subtitle: Text(description),
    );
  }
}
