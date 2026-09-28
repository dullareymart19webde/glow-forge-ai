import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import '../providers/providers.dart';

class PhotoScreen extends ConsumerStatefulWidget {
  const PhotoScreen({super.key});

  @override
  ConsumerState<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends ConsumerState<PhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  XFile? _selectedImage;
  Uint8List? _processedBytes;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _processedBytes = null;
      });
    }
  }

  Future<void> _processImage(String type) async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });
    
    try {
      final api = ref.read(apiProvider);
      final bytes = await api.processImage(_selectedImage!, type);
      setState(() {
        _processedBytes = Uint8List.fromList(bytes);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    final originalBox = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(16)
      ),
      clipBehavior: Clip.antiAlias,
      child: _selectedImage == null 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, size: 48, color: Colors.white24),
                SizedBox(height: 16),
                Text('No Image Selected', style: TextStyle(color: Colors.white54))
              ],
            ))
          : FutureBuilder<Uint8List>(
              future: _selectedImage!.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(snapshot.data!, fit: BoxFit.contain);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
    );

    final processedBox = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF6C63FF), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C63FF).withAlpha(38), blurRadius: 20, spreadRadius: 2)
        ]
      ),
      clipBehavior: Clip.antiAlias,
      child: _processedBytes == null
          ? const Center(child: Text('Processed Output', style: TextStyle(color: Colors.white54)))
          : Image.memory(_processedBytes!, fit: BoxFit.contain),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1136),
            Color(0xFF381460),
            Color(0xFF1E1136),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('AI Photo Studio', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_selectedImage != null)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Remove BG'),
                        avatar: const Icon(Icons.format_color_fill, size: 16),
                        onPressed: _isLoading ? null : () => _processImage('remove-bg'),
                      ),
                      ActionChip(
                        label: const Text('Enhance'),
                        avatar: const Icon(Icons.auto_awesome, size: 16),
                        onPressed: _isLoading ? null : () => _processImage('enhance'),
                      ),
                      ActionChip(
                        label: const Text('Sharpen'),
                        avatar: const Icon(Icons.blur_on, size: 16),
                        onPressed: _isLoading ? null : () => _processImage('sharpen'),
                      ),
                      ActionChip(
                        label: const Text('Sketch'),
                        avatar: const Icon(Icons.draw, size: 16),
                        onPressed: _isLoading ? null : () => _processImage('sketch'),
                      ),
                      ActionChip(
                        label: const Text('B&W'),
                        avatar: const Icon(Icons.tonality, size: 16),
                        onPressed: _isLoading ? null : () => _processImage('black-white'),
                      ),
                    ],
                  ),
                if (_selectedImage != null) const SizedBox(height: 16),
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amberAccent.withAlpha(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amberAccent.withAlpha(100),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                )
                              ]
                            ),
                            child: const CircularProgressIndicator(
                              color: Colors.amberAccent,
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Forging Image...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Applying AI magic',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber[100],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: isMobile
                        ? Column(
                            children: [
                              Expanded(child: originalBox),
                              const SizedBox(height: 16),
                              Expanded(child: processedBox),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: originalBox),
                              const SizedBox(width: 16),
                              Expanded(child: processedBox),
                            ],
                          ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Select Photo'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
                        onPressed: _isLoading ? null : _pickImage,
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text('Save Photo'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent.shade700, foregroundColor: Colors.white),
                          onPressed: (_isLoading || _processedBytes == null) ? null : () async {
                            try {
                              await Gal.putImageBytes(_processedBytes!, name: 'glowforge_${DateTime.now().millisecondsSinceEpoch}.png');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Gallery!')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                              }
                            }
                          },
                        ),
                      )
                    ]
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
