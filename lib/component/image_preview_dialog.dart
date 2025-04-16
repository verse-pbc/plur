import 'dart:io';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:bot_toast/bot_toast.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:nostrmo/util/image_tool.dart';
import 'package:permission_handler/permission_handler.dart';

import '../generated/l10n.dart';

const _defaultBackgroundColor = Colors.black;
const _defaultCloseButtonColor = Colors.white;

class ImagePreviewDialog extends StatefulWidget {
  final EasyImageProvider imageProvider;
  final bool immersive;
  final void Function(int)? onPageChanged;
  final void Function(int)? onViewerDismissed;
  final bool useSafeArea;
  final bool swipeDismissible;
  final bool doubleTapZoomable;
  final Color backgroundColor;
  final Color closeButtonColor;

  const ImagePreviewDialog(this.imageProvider,
      {Key? key,
      this.immersive = true,
      this.onPageChanged,
      this.onViewerDismissed,
      this.useSafeArea = false,
      this.swipeDismissible = false,
      this.doubleTapZoomable = false,
      required this.backgroundColor,
      required this.closeButtonColor})
      : super(key: key);

  /// Shows the given [imageProvider] in a full-screen [Dialog].
  /// Setting [immersive] to false will prevent the top and bottom bars from being hidden.
  /// The optional [onViewerDismissed] callback function is called when the dialog is closed.
  /// The optional [useSafeArea] boolean defaults to false and is passed to [showDialog].
  /// The optional [swipeDismissible] boolean defaults to false and allows swipe-down-to-dismiss.
  /// The optional [doubleTapZoomable] boolean defaults to false and allows double tap to zoom.
  /// The [backgroundColor] defaults to black, but can be set to any other color.
  /// The [closeButtonColor] defaults to white, but can be set to any other color.
  static Future<void> show(
      BuildContext context, EasyImageProvider imageProvider,
      {bool immersive = true,
      void Function(int)? onPageChanged,
      void Function(int)? onViewerDismissed,
      bool useSafeArea = false,
      bool swipeDismissible = false,
      bool doubleTapZoomable = false,
      Color backgroundColor = _defaultBackgroundColor,
      Color closeButtonColor = _defaultCloseButtonColor}) {
    // if (immersive) {
    //   // Hide top and bottom bars
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // }

    return showDialog(
        context: context,
        useSafeArea: useSafeArea,
        useRootNavigator: false,
        builder: (context) {
          return ImagePreviewDialog(imageProvider,
              immersive: immersive,
              onPageChanged: onPageChanged,
              onViewerDismissed: onViewerDismissed,
              useSafeArea: useSafeArea,
              swipeDismissible: swipeDismissible,
              doubleTapZoomable: doubleTapZoomable,
              backgroundColor: backgroundColor,
              closeButtonColor: closeButtonColor);
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _ImagePreviewDialog();
  }
}

class _ImagePreviewDialog extends State<ImagePreviewDialog> {
  /// This is used to either activate or deactivate the ability to swipe-to-dismissed, based on
  /// whether the current image is zoomed in (scale > 0) or not.
  DismissDirection _dismissDirection = DismissDirection.down;
  void Function()? _internalPageChangeListener;
  late final PageController _pageController;

  /// This is needed because of https://github.com/thesmythgroup/easy_image_viewer/issues/27
  /// When no global key was used, the state was re-created on the initial zoom, which
  /// caused the new state to have _pagingEnabled set to true, which in turn broke
  /// paning on the zoomed-in image.
  final _popScopeKey = GlobalKey();

  // focus node to capture keyboard events
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: widget.imageProvider.initialIndex);
    if (widget.onPageChanged != null) {
      _internalPageChangeListener = () {
        widget.onPageChanged!(_pageController.page?.round() ?? 0);
      };
      _pageController.addListener(_internalPageChangeListener!);
    }
  }

  @override
  void dispose() {
    if (_internalPageChangeListener != null) {
      _pageController.removeListener(_internalPageChangeListener!);
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);

    var main = Scaffold(
      backgroundColor: widget.backgroundColor.withAlpha(128),
      body: GestureDetector(
        onTap: _close,
        child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              EasyImageViewPager(
                  easyImageProvider: widget.imageProvider,
                  pageController: _pageController,
                  doubleTapZoomable: widget.doubleTapZoomable,
                  onScaleChanged: (scale) {
                    setState(() {
                      _dismissDirection = scale <= 1.0
                          ? DismissDirection.down
                          : DismissDirection.none;
                    });
                  }),
              SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        color: widget.closeButtonColor,
                        tooltip: localization.close,
                        onPressed: _close,
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      left: 5,
                      child: IconButton(
                        icon: const Icon(Icons.download),
                        color: widget.closeButtonColor,
                        tooltip: localization.download,
                        onPressed: saveImage,
                      ),
                    ),
                  ]
                ),
              ),

            ]),
      ),
    );

    final popScopeAwareDialog = PopScope(
      onPopInvokedWithResult: (_, __) => _handleDismissal(),
      key: _popScopeKey,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (ke) {
          var duration = const Duration(seconds: 1);
          if (ke.logicalKey.keyLabel == 'Arrow Left') {
            _pageController.previousPage(
                duration: duration, curve: Curves.ease);
          } else if (ke.logicalKey.keyLabel == 'Arrow Right') {
            _pageController.nextPage(duration: duration, curve: Curves.ease);
          } else if (ke.logicalKey.keyLabel == 'Arrow Down') {
            _close();
          }
        },
        child: main,
      ),
    );

    if (widget.swipeDismissible) {
      return Dismissible(
          direction: _dismissDirection,
          resizeDuration: null,
          confirmDismiss: (dir) async {
            return true;
          },
          onDismissed: (_) => _close(),
          key: const Key('dismissible_easy_image_viewer_dialog'),
          child: popScopeAwareDialog);
    } else {
      return popScopeAwareDialog;
    }
  }

  Future<void> saveImage() async {
    if (Platform.isIOS) {
      _doSaveImage();
    } else if (Platform.isAndroid) {
      await Permission.storage.request();
      try {
        _doSaveImage();
      } catch (e) {
        developer.log("saveImage error $e");
      }
    } else {
      _doSaveImage(isPc: true);
    }
  }

  Future<void> _doSaveImage({bool isPc = false}) async {
    try {
      var index = _pageController.page!.toInt();
      var imageProvider = widget.imageProvider.imageBuilder(context, index);
      
      // Use try-catch to handle errors during image processing
      try {
        var imageAsBytes = await imageProvider.getBytes(context, format: ImageByteFormat.png);
        if (imageAsBytes != null) {
          if (!isPc) {
            var result = await ImageGallerySaver.saveImage(imageAsBytes, quality: 100);
            if (!mounted) return;
            if (result != null && result is Map && result["isSuccess"]) {
              BotToast.showText(text: S.of(context).imageSaveSuccess);
            } else {
              // Silently fail
              developer.log("Failed to save image: $result", name: "ImagePreviewDialog");
            }
          } else {
            var result = await FileSaver.instance.saveFile(
              name: DateTime.now().millisecondsSinceEpoch.toString(),
              bytes: imageAsBytes,
              ext: ".png",
            );
            if (!mounted) return;
            BotToast.showText(
              text: "${S.of(context).imageSaveSuccess} $result",
              crossPage: true,
            );
          }
        } else {
          // No image bytes available
          developer.log("No image bytes available to save", name: "ImagePreviewDialog");
        }
      } catch (e) {
        // Error processing image
        developer.log("Error processing image for save: $e", name: "ImagePreviewDialog");
      }
    } catch (e) {
      // Handle any errors in the outer try block
      developer.log("Error in _doSaveImage: $e", name: "ImagePreviewDialog");
    }
  }

  // Internal function to be called whenever the dialog
  // is dismissed, whether through the Android back button,
  // through the "x" close button, or through swipe-to-dismiss.
  void _handleDismissal() {
    if (widget.onViewerDismissed != null) {
      widget.onViewerDismissed!(_pageController.page?.round() ?? 0);
    }
  }

  void _close() {
    Navigator.of(context).pop();
    _handleDismissal();
  }
}
