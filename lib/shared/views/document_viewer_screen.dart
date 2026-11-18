import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:pdfx/pdfx.dart';
import 'package:collection_agent/core/constants/app_colors.dart';
import 'package:collection_agent/core/constants/app_strings.dart';
import 'package:collection_agent/core/theme/app_text_styles.dart';

/// Full-screen in-app document viewer supporting interactive PDFs and images
class DocumentViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String? subtitle;

  const DocumentViewerScreen({
    super.key,
    required this.url,
    required this.title,
    this.subtitle,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  Key _viewerKey = UniqueKey();
  bool _hasError = false;
  String _errorMessage = '';

  // PDF state
  PdfDocument? _pdfDocument;
  PdfControllerPinch? _pdfPinchController;
  PdfController? _pdfSimpleController;
  bool _isLoadingPdf = false;
  int _pageCount = 0;

  bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;

  String get _cleanPath {
    final trimmed = widget.url.trim();
    if (trimmed.isEmpty) return '';
    try {
      final uri = Uri.parse(trimmed);
      return uri.path.toLowerCase();
    } catch (_) {
      return trimmed.split('?').first.split('#').first.toLowerCase();
    }
  }

  bool get _isPdf => _cleanPath.endsWith('.pdf');

  bool get _isImage {
    final p = _cleanPath;
    return p.endsWith('.png') ||
        p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.webp') ||
        p.endsWith('.gif') ||
        p.endsWith('.bmp');
  }

  @override
  void initState() {
    super.initState();
    if (_isPdf) {
      _isLoadingPdf = true;
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    if (widget.url.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingPdf = false;
          _hasError = true;
          _errorMessage = 'Invalid or empty document URL';
        });
      }
      return;
    }

    setState(() {
      _isLoadingPdf = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await dio.get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (!mounted) return;

      if (response.data != null && response.data!.isNotEmpty) {
        final doc = await PdfDocument.openData(Uint8List.fromList(response.data!));
        if (!mounted) {
          doc.close();
          return;
        }

        _pdfPinchController?.dispose();
        _pdfSimpleController?.dispose();
        _pdfDocument?.close();
        _pdfDocument = doc;

        if (_isWindows) {
          _pdfSimpleController = PdfController(document: Future.value(doc));
        } else {
          _pdfPinchController = PdfControllerPinch(document: Future.value(doc));
        }

        if (mounted) {
          setState(() {
            _pageCount = doc.pagesCount;
            _isLoadingPdf = false;
          });
        }
      } else {
        throw Exception('Empty document response');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPdf = false;
          _hasError = true;
          if (e is DioException) {
            if (e.response?.statusCode == 403) {
              _errorMessage = 'Access denied or document link has expired.';
            } else if (e.response?.statusCode == 404) {
              _errorMessage = 'Document not found on the server.';
            } else if (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout) {
              _errorMessage = 'Connection timed out while loading the document.';
            } else {
              _errorMessage = 'Network error while loading document.';
            }
          } else {
            _errorMessage = 'Failed to load PDF document. Please check your connection.';
          }
        });
      }
    }
  }

  void _reload() {
    PaintingBinding.instance.imageCache.evict(NetworkImage(widget.url));
    if (_isPdf) {
      _loadPdf();
    } else {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _viewerKey = UniqueKey();
      });
    }
  }

  @override
  void dispose() {
    _pdfPinchController?.dispose();
    _pdfSimpleController?.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: _reload,
            tooltip: AppStrings.retry,
          ),
        ],
      ),
      body: SafeArea(
        child: _hasError ? _buildErrorView() : _buildDocumentContent(),
      ),
    );
  }

  Widget _buildDocumentContent() {
    if (widget.url.trim().isEmpty) {
      return _buildErrorView(errorText: 'No document URL provided');
    }

    if (_isPdf) {
      if (_isLoadingPdf || (_pdfPinchController == null && _pdfSimpleController == null)) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 14),
              Text(
                'Loading PDF document...',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        );
      }

      if (_isWindows && _pdfSimpleController != null) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PdfView(
              controller: _pdfSimpleController!,
            ),
            if (_pageCount > 0)
              Positioned(
                bottom: 16,
                child: ValueListenableBuilder<int>(
                  valueListenable: _pdfSimpleController!.pageListenable,
                  builder: (context, page, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0F172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Text(
                        'Page $page of $_pageCount',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }

      if (_pdfPinchController != null) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PdfViewPinch(
              controller: _pdfPinchController!,
            ),
            if (_pageCount > 0)
              Positioned(
                bottom: 16,
                child: ValueListenableBuilder<int>(
                  valueListenable: _pdfPinchController!.pageListenable,
                  builder: (context, page, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0F172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Text(
                        'Page $page of $_pageCount',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }

      return _buildErrorView(errorText: 'Failed to initialize PDF renderer');
    }

    if (_isImage) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Image.network(
            widget.url,
            key: _viewerKey,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              final total = loadingProgress.expectedTotalBytes;
              final loaded = loadingProgress.cumulativeBytesLoaded;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: total != null && total > 0 ? loaded / total : null,
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading image...',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorView(errorText: 'Failed to load image');
            },
          ),
        ),
      );
    }

    // Default fallback: Try loading as image with zoom
    return Center(
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: Image.network(
          widget.url,
          key: _viewerKey,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorView(errorText: 'Unsupported file preview format');
          },
        ),
      ),
    );
  }

  Widget _buildErrorView({String? errorText}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.broken_image_outlined,
                color: Color(0xFFEF4444),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.failedToLoadDocument,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              (errorText != null && errorText.isNotEmpty)
                  ? errorText
                  : (_errorMessage.isNotEmpty
                      ? _errorMessage
                      : 'Please check your internet connection and try again.'),
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                AppStrings.retry,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
