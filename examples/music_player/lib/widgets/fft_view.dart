import 'dart:math';

import 'package:dart_audio_graph_fft/dart_audio_graph_fft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:music_player/main_screen.dart';
import 'package:music_player/painter/fft_painter.dart';
import 'package:music_player/player/music_player.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

class FftView extends StatefulWidget {
  const FftView({Key? key}) : super(key: key);

  @override
  State<FftView> createState() => _FftViewState();
}

class _FftViewState extends State<FftView> {
  final _palette = [Colors.grey.shade300];
  Metadata? _lastMetadata;

  @override
  void initState() {
    super.initState();
    final player = context.read<MusicPlayer>();
    player.addListener(_playerListener);
  }

  @override
  void dispose() {
    final player = context.read<MusicPlayer>();
    player.removeListener(_playerListener);
    super.dispose();
  }

  void _playerListener() async {
    final player = context.read<MusicPlayer>();
    if (player.metadata == _lastMetadata) {
      return;
    }

    _lastMetadata = player.metadata;
    final image = player.metadata?.albumArt;
    if (image != null) {
      final paletteGen = await PaletteGenerator.fromImageProvider(MemoryImage(image));
      setState(() {
        _palette
          ..clear()
          ..add(paletteGen.paletteColors[Random().nextInt(paletteGen.paletteColors.length)].color);
      });
    } else {
      setState(() {
        _palette
          ..clear()
          ..add(Colors.grey.shade300);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fftResult = context.select<FftNotifier, FftResult?>((f) => f.value);
    final width = MediaQuery.of(context).size.width;
    return Visibility(
      visible: fftResult != null,
      child: fftResult != null
          ? CustomPaint(
              painter: FftPainter(
                fftResult,
                10,
                8000,
                _palette,
                width ~/ 30,
              ),
            )
          : const SizedBox(),
    );
  }
}
