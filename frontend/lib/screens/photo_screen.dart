import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: _selectedImage == null 
          ? const Center(child: Text('No Image'))
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
      decoration: BoxDecoration(border: Border.all(color: Colors.deepPurple)),
      child: _processedBytes == null
          ? const Center(child: Text('Processed Output'))
          : Image.memory(_processedBytes!, fit: BoxFit.contain),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Local AI Photo Enhancer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Select Photo'),
              onPressed: _isLoading ? null : _pickImage,
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _processImage('remove-bg'),
                    child: const Text('Remove BG'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _processImage('enhance'),
                    child: const Text('Auto-Enhance'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _processImage('sharpen'),
                    child: const Text('Sharpen / Unblur'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _processImage('sketch'),
                    child: const Text('Sketch'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _processImage('black-white'),
                    child: const Text('B&W'),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
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
              )
          ],
        ),
      ),
    );
  }
}
