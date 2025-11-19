import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../services/audio_service.dart';
import '../models/playback_state.dart' as models;

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return playbackStateAsync.when(
      data: (state) => _PlayerContent(state: state),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _PlayerContent extends ConsumerStatefulWidget {
  final models.PlaybackState state;

  const _PlayerContent({required this.state});

  @override
  ConsumerState<_PlayerContent> createState() => _PlayerContentState();
}

class _PlayerContentState extends ConsumerState<_PlayerContent> {
  bool _isScrubbing = false;
  double _scrubPosition = 0.0;

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final audioService = ref.read(audioServiceProvider);
      try {
        await audioService.loadAudio(result.files.single.path!);
        await audioService.play();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading audio: $e')),
          );
        }
      }
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.read(audioServiceProvider);
    final hasAudio = widget.state.currentAudioPath != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album art placeholder
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.music_note,
              size: 100,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          
          const SizedBox(height: 32),
          
          if (!hasAudio)
            FilledButton.icon(
              onPressed: _pickAudioFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select Audio File'),
            )
          else ...[
            // Progress slider
            Column(
              children: [
                Slider(
                  value: _isScrubbing
                      ? _scrubPosition
                      : widget.state.progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    setState(() {
                      _isScrubbing = true;
                      _scrubPosition = value;
                    });
                  },
                  onChangeEnd: (value) async {
                    final newPositionMs =
                        (value * (widget.state.durationMs ?? 0)).toInt();
                    await audioService.seek(newPositionMs);
                    setState(() {
                      _isScrubbing = false;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(widget.state.positionMs)),
                      Text(_formatDuration(widget.state.durationMs ?? 0)),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Main playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => audioService.skipBackward(),
                  icon: const Icon(Icons.replay),
                  iconSize: 36,
                  tooltip: 'Rewind 15s',
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => audioService.togglePlay(),
                  icon: Icon(
                    widget.state.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                  ),
                  iconSize: 64,
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => audioService.skipForward(),
                  icon: const Icon(Icons.forward),
                  iconSize: 36,
                  tooltip: 'Forward 15s',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Additional controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Volume
                Column(
                  children: [
                    IconButton(
                      onPressed: () => audioService.volumeDown(),
                      icon: const Icon(Icons.volume_down),
                    ),
                    Text('${(widget.state.volume * 100).toInt()}%'),
                    IconButton(
                      onPressed: () => audioService.volumeUp(),
                      icon: const Icon(Icons.volume_up),
                    ),
                  ],
                ),
                
                // Speed
                Column(
                  children: [
                    IconButton(
                      onPressed: () => audioService.cycleSpeed(),
                      icon: const Icon(Icons.speed),
                    ),
                    Text('${widget.state.speed}x'),
                  ],
                ),
                
                // Repeat
                IconButton(
                  onPressed: () => audioService.cycleRepeat(),
                  icon: Icon(
                    widget.state.isRepeating == models.RepeatMode.repeatOne
                        ? Icons.repeat_one
                        : widget.state.isRepeating == models.RepeatMode.repeatAll
                            ? Icons.repeat
                            : Icons.repeat,
                  ),
                  color: widget.state.isRepeating != models.RepeatMode.off
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                
                // Shuffle
                IconButton(
                  onPressed: () => audioService.toggleShuffle(),
                  icon: const Icon(Icons.shuffle),
                  color: widget.state.isShuffling
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: _pickAudioFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Change File'),
            ),
          ],
        ],
      ),
    );
  }
}
