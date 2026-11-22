import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../models/flashcard.dart';
import '../services/api_service.dart';
import '../widgets/flip_card.dart';

enum AppState { idle, loading, result, error }
enum InputMode { file, text }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  InputMode _inputMode = InputMode.file;
  PlatformFile? _selectedFile;
  final TextEditingController _textController = TextEditingController();
  int _cardCount = 5;
  AppState _appState = AppState.idle;
  List<Flashcard> _flashcards = [];
  String _errorMessage = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handlePickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final ext = file.extension?.toLowerCase() ?? '';

      if (ext != 'pdf' && ext != 'docx') {
        setState(() {
          _errorMessage = 'Format file tidak didukung. Gunakan PDF atau DOCX.';
          _appState = AppState.error;
        });
        return;
      }

      if (file.size == 0) {
        setState(() {
          _errorMessage = 'File kosong.';
          _appState = AppState.error;
        });
        return;
      }

      if (file.size > 20 * 1024 * 1024) {
        setState(() {
          _errorMessage = 'Ukuran file melebihi batas 20MB.';
          _appState = AppState.error;
        });
        return;
      }

      setState(() {
        _selectedFile = file;
        _appState = AppState.idle;
        _flashcards = [];
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memilih file: $e';
        _appState = AppState.error;
      });
    }
  }

  bool get _isInputValid {
    if (_inputMode == InputMode.file) {
      return _selectedFile != null;
    } else {
      return _textController.text.trim().isNotEmpty;
    }
  }

  Future<void> _handleGenerate() async {
    if (_inputMode == InputMode.file && _selectedFile == null) {
      setState(() {
        _errorMessage = 'Pilih file PDF atau DOCX terlebih dahulu.';
        _appState = AppState.error;
      });
      return;
    }

    if (_inputMode == InputMode.text && _textController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan materi terlebih dahulu.';
        _appState = AppState.error;
      });
      return;
    }

    setState(() {
      _appState = AppState.loading;
      _flashcards = [];
      _errorMessage = '';
    });

    try {
      final cards = await ApiService.generateFlashcards(
        inputType: _inputMode == InputMode.file ? 'file' : 'text',
        cardCount: _cardCount,
        text: _inputMode == InputMode.text ? _textController.text.trim() : null,
        fileBytes: _selectedFile?.bytes,
        filePath: _selectedFile?.path,
        fileName: _selectedFile?.name,
      );

      setState(() {
        _flashcards = cards;
        _appState = AppState.result;
      });
    } catch (err) {
      setState(() {
        _errorMessage = err.toString().replaceFirst('Exception: ', '');
        _appState = AppState.error;
      });
    }
  }

  void _handleReset() {
    setState(() {
      _selectedFile = null;
      _textController.clear();
      _flashcards = [];
      _errorMessage = '';
      _appState = AppState.idle;
      _cardCount = 5;
    });
  }

  void _handleRegenerate() {
    if (_isInputValid) {
      _handleGenerate();
    }
  }

  Future<void> _handleDownloadMarkdown() async {
    if (_flashcards.isEmpty) return;

    try {
      final sourceName = _inputMode == InputMode.file && _selectedFile != null
          ? _selectedFile!.name
          : 'Materi';

      final buffer = StringBuffer();
      buffer.writeln('# Flashcard: $sourceName\n');

      for (int i = 0; i < _flashcards.length; i++) {
        buffer.writeln('### ${i + 1}. ${_flashcards[i].question}\n');
        buffer.writeln('${_flashcards[i].answer}\n');
        buffer.writeln('---\n');
      }

      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      dir ??= await getApplicationDocumentsDirectory();

      final fileName = 'flashcards-${DateTime.now().millisecondsSinceEpoch}.md';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File .md berhasil disimpan:\n${file.path}',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            backgroundColor: const Color(0xFF0A0A0A),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan file: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showBackendSettings() {
    final urlController = TextEditingController(text: ApiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Konfigurasi Backend API',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A0A0A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesuaikan alamat backend Next.js:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF737373),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                hintText: 'https://flashcard-kamu.vercel.app',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0A0A0A)),
                ),
              ),
              style: GoogleFonts.jetBrainsMono(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              '• Backend Production: https://flashcard-kamu.vercel.app',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF737373),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: const Color(0xFF737373)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                ApiService.baseUrl = urlController.text.trim();
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.inter(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 768), // max-w-3xl
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 32),
                        _buildInputPanel(),
                        if (_appState == AppState.error) ...[
                          const SizedBox(height: 32),
                          _buildErrorBanner(),
                        ],
                        if (_appState == AppState.result && _flashcards.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildResultSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _showBackendSettings,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FlashCard.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _handleReset,
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF737373),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Text(
      'Buat flashcard dari materi belajar.',
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: const Color(0xFF0A0A0A),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs Container
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabButton(
                  title: 'Upload File',
                  isActive: _inputMode == InputMode.file,
                  onTap: () {
                    setState(() {
                      _inputMode = InputMode.file;
                      if (_errorMessage.isNotEmpty) _errorMessage = '';
                    });
                  },
                ),
                _buildTabButton(
                  title: 'Masukkan Teks',
                  isActive: _inputMode == InputMode.text,
                  onTap: () {
                    setState(() {
                      _inputMode = InputMode.text;
                      if (_errorMessage.isNotEmpty) _errorMessage = '';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tab Content
          if (_inputMode == InputMode.file) _buildUploadFileArea(),
          if (_inputMode == InputMode.text) _buildTextInputArea(),

          const SizedBox(height: 24),

          // Bottom Action & Counter
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final counterWidget = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Jumlah kartu',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF737373),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCounterButton(
                            label: '−',
                            disabled: _cardCount <= 1,
                            onTap: () {
                              if (_cardCount > 1) {
                                setState(() => _cardCount--);
                              }
                            },
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$_cardCount',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0A0A0A),
                              ),
                            ),
                          ),
                          _buildCounterButton(
                            label: '+',
                            disabled: _cardCount >= 10,
                            onTap: () {
                              if (_cardCount < 10) {
                                setState(() => _cardCount++);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final actionButton = _buildGenerateButton();

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      counterWidget,
                      const SizedBox(height: 16),
                      actionButton,
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      counterWidget,
                      actionButton,
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF0A0A0A) : const Color(0xFF737373),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadFileArea() {
    return GestureDetector(
      onTap: _handlePickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedFile != null) ...[
              Text(
                _selectedFile!.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0A0A0A),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: const Color(0xFF737373),
                ),
              ),
            ] else ...[
              Text(
                'Upload PDF atau DOCX.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF737373),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      child: TextField(
        controller: _textController,
        maxLines: null,
        minLines: 7,
        onChanged: (_) {
          if (_errorMessage.isNotEmpty) {
            setState(() => _errorMessage = '');
          }
          setState(() {});
        },
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF0A0A0A),
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Tempel materi di sini...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFA3A3A3),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCounterButton({
    required String label,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            color: disabled ? const Color(0xFFD4D4D4) : const Color(0xFF737373),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    final bool canSubmit = _isInputValid && _appState != AppState.loading;

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: canSubmit ? _handleGenerate : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: canSubmit ? const Color(0xFF0A0A0A) : const Color(0xFFE5E5E5),
          disabledBackgroundColor: const Color(0xFFE5E5E5),
          foregroundColor: const Color(0xFFFFFFFF),
          disabledForegroundColor: const Color(0xFFA3A3A3),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          _appState == AppState.loading ? 'Memproses...' : 'Buat Flashcard',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              _errorMessage,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFDC2626),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleReset,
            child: Text(
              'Reset',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subheader
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_flashcards.length} Flashcard',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF737373),
                ),
              ),
              Row(
                children: [
                  _buildSecondaryButton(
                    label: 'Download .md',
                    textColor: const Color(0xFF0A0A0A),
                    onTap: _handleDownloadMarkdown,
                  ),
                  const SizedBox(width: 8),
                  _buildSecondaryButton(
                    label: 'Buat Ulang',
                    textColor: const Color(0xFF737373),
                    onTap: _handleRegenerate,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid of Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;
            if (isWide) {
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 250,
                ),
                itemCount: _flashcards.length,
                itemBuilder: (context, index) {
                  return FlipCardWidget(
                    card: _flashcards[index],
                    index: index,
                  );
                },
              );
            } else {
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _flashcards.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return FlipCardWidget(
                    card: _flashcards[index],
                    index: index,
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
          color: const Color(0xFFFFFFFF),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
