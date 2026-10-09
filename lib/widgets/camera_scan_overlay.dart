import 'package:flutter/material.dart';

class CameraScanOverlay extends StatefulWidget {
  final VoidCallback onCapture;
  final VoidCallback onPickGallery;
  final VoidCallback onToggleFlash;
  final bool isFlashOn;

  const CameraScanOverlay({
    super.key,
    required this.onCapture,
    required this.onPickGallery,
    required this.onToggleFlash,
    required this.isFlashOn,
  });

  @override
  State<CameraScanOverlay> createState() => _CameraScanOverlayState();
}

class _CameraScanOverlayState extends State<CameraScanOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final frameWidth = screenWidth * 0.85;
        final frameHeight = screenHeight * 0.60;
        final frameLeft = (screenWidth - frameWidth) / 2;
        final frameTop = (screenHeight - frameHeight) / 2 - 20;

        return Stack(
          children: [
            // Lớp phủ tối xung quanh khung quét (CustomPainter Bounding Box)
            CustomPaint(
              size: Size(screenWidth, screenHeight),
              painter: _ScanHolePainter(
                rect: Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight),
              ),
            ),

            // Viền 4 góc của khung hóa đơn
            Positioned(
              left: frameLeft,
              top: frameTop,
              width: frameWidth,
              height: frameHeight,
              child: Stack(
                children: [
                  // Laser scan line
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: frameHeight * _laserAnimation.value,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Góc trên trái
                  const Align(
                    alignment: Alignment.topLeft,
                    child: _CornerMarker(corner: _Corner.topLeft),
                  ),
                  // Góc trên phải
                  const Align(
                    alignment: Alignment.topRight,
                    child: _CornerMarker(corner: _Corner.topRight),
                  ),
                  // Góc dưới trái
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: _CornerMarker(corner: _Corner.bottomLeft),
                  ),
                  // Góc dưới phải
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: _CornerMarker(corner: _Corner.bottomRight),
                  ),
                ],
              ),
            ),

            // Hướng dẫn người dùng
            Positioned(
              top: frameTop - 40,
              left: 20,
              right: 20,
              child: const Text(
                'Căn chỉnh hóa đơn / biên lai vào giữa khung quét',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),

            // Thanh điều khiển phía dưới
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút chọn ảnh từ thư viện
                  IconButton.filledTonal(
                    onPressed: widget.onPickGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),

                  // Nút chụp ảnh chính
                  GestureDetector(
                    onTap: widget.onCapture,
                    child: Container(
                      width: 74,
                      height: 74,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.black87,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Nút bật / tắt Flash
                  IconButton.filledTonal(
                    onPressed: widget.onToggleFlash,
                    icon: Icon(
                      widget.isFlashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                    ),
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      backgroundColor: widget.isFlashOn
                          ? Colors.amber.withOpacity(0.3)
                          : Colors.white.withOpacity(0.2),
                      foregroundColor: widget.isFlashOn
                          ? Colors.amberAccent
                          : Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerMarker extends StatelessWidget {
  final _Corner corner;
  const _CornerMarker({required this.corner});

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    const stroke = 4.0;
    const color = Colors.greenAccent;

    Border border;
    switch (corner) {
      case _Corner.topLeft:
        border = const Border(
          top: BorderSide(color: color, width: stroke),
          left: BorderSide(color: color, width: stroke),
        );
        break;
      case _Corner.topRight:
        border = const Border(
          top: BorderSide(color: color, width: stroke),
          right: BorderSide(color: color, width: stroke),
        );
        break;
      case _Corner.bottomLeft:
        border = const Border(
          bottom: BorderSide(color: color, width: stroke),
          left: BorderSide(color: color, width: stroke),
        );
        break;
      case _Corner.bottomRight:
        border = const Border(
          bottom: BorderSide(color: color, width: stroke),
          right: BorderSide(color: color, width: stroke),
        );
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(border: border),
    );
  }
}

class _ScanHolePainter extends CustomPainter {
  final Rect rect;

  _ScanHolePainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.65),
    );
  }

  @override
  bool shouldRepaint(covariant _ScanHolePainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}
