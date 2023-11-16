import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_coast_audio_miniaudio/flutter_coast_audio_miniaudio.dart';
import 'package:music_player/player/isolated_music_player.dart';
import 'package:music_player/recorder_screen.dart';
import 'package:music_player/widgets/control_view.dart';
import 'package:music_player/widgets/device_dropdown.dart';
import 'package:music_player/widgets/glass_artwork_image.dart';
import 'package:music_player/widgets/url_dialog.dart';
import 'package:provider/provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _format = const AudioFormat(sampleRate: 48000, channels: 2);
  late final _player = IsolatedMusicPlayer(format: _format);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: _buildPlayer(),
    );
  }

  Widget _buildPlayer() {
    return ChangeNotifierProvider<IsolatedMusicPlayer>.value(
      value: _player,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          key: ValueKey('GlassArtworkImage'),
          child: GlassArtworkImage(),
        ),
        RepaintBoundary(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const DeviceDropdown(),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.any,
                            allowMultiple: false,
                            allowCompression: false,
                          );

                          if (result == null) {
                            return;
                          }

                          final filePath = result.files.single.path!;
                          await _player.openFile(filePath);

                          setState(() {
                            _player.play();
                          });
                        },
                        icon: const Icon(Icons.folder_open_outlined),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () async {
                          final url = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              return UrlDialog(
                                onSubmitted: (url) => Navigator.of(context).pop(url),
                                onCancel: () => Navigator.of(context).pop(null),
                              );
                            },
                          );

                          if (url == null) {
                            return;
                          }

                          await _player.openHttpUrl(url);

                          setState(() {
                            _player.play();
                          });
                        },
                        icon: const Icon(Icons.download),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () async {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => RecorderScreen(
                              onRecorded: (dataSource) async {
                                final buffer = Uint8List(dataSource.length!);
                                dataSource.readBytes(buffer);
                                await _player.openBuffer(buffer);
                                await _player.play();
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.mic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Expanded(
                  child: ControlView(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
