/// Support for doing something awesome.
///
/// More dartdocs go here.
library screenshot_cusomize;

// import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

// TODO: Export any libraries intended for clients of this package.

///
///
///Cannot capture Platformview due to issue https://github.com/flutter/flutter/issues/25306
///
///
class ScreenShotCustomize {
  late GlobalKey _containerKey;

  ScreenShotCustomize() {
    _containerKey = GlobalKey();
  }

  /// Captures image and saves to given path

  Future<Uint8List?> capture({
    double? pixelRatio,
    Duration delay = const Duration(milliseconds: 20),
  }) {
    //Delay is required. See Issue https://github.com/flutter/flutter/issues/22308
    return Future.delayed(delay, () async {
      try {
        ui.Image? image = await captureAsUiImage(
          delay: Duration.zero,
          pixelRatio: pixelRatio,
        );
        ByteData? byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
        Uint8List? pngBytes = byteData?.buffer.asUint8List();

        return pngBytes;
      } on Exception {
        throw (Exception);
      }
    });
  }

  Future<ui.Image?> captureAsUiImage({double? pixelRatio = 1, Duration delay = const Duration(milliseconds: 20)}) {
    //Delay is required. See Issue https://github.com/flutter/flutter/issues/22308
    return Future.delayed(delay, () async {
      try {
        var findRenderObject = _containerKey.currentContext?.findRenderObject();
        if (findRenderObject == null) {
          return null;
        }
        RenderRepaintBoundary boundary = findRenderObject as RenderRepaintBoundary;
        BuildContext? context = _containerKey.currentContext;
        if (pixelRatio == null) {
          if (context != null) pixelRatio = pixelRatio ?? MediaQuery.of(context).devicePixelRatio;
        }
        ui.Image image = await boundary.toImage(pixelRatio: pixelRatio ?? 1);
        return image;
      } catch (Exception) {
        throw (Exception);
      }
    });
  }

  ///
  /// Value for [delay] should increase with widget tree size. Prefered value is 1 seconds
  ///
  ///[context] parameter is used to Inherit App Theme and MediaQuery data.
  ///
  ///
  ///
  Future captureFromWidget(
    Widget widget, {
    Duration delay = const Duration(seconds: 1),
    double pixelRatio = 1,
    BuildContext? context,
    required double widthImage,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    /// create a new pipeline owner
    final PipelineOwner pipelineOwner = PipelineOwner();

    /// create a new build owner
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    //Size logicalSize = ui.window.physicalSize / ui.window.devicePixelRatio;

    try {
      final RenderView renderView = RenderView(
        window: ui.window,
        child: RenderPositionedBox(alignment: Alignment.center, child: repaintBoundary),
        configuration: ViewConfiguration(
          size: Size(widthImage, 1000),
          devicePixelRatio: 2,
        ),
      );

      /// setting the rootNode to the renderview of the widget
      pipelineOwner.rootNode = renderView;

      /// setting the renderView to prepareInitialFrame
      renderView.prepareInitialFrame();

      /// setting the rootElement with the widget that has to be captured
      final RenderObjectToWidgetElement<RenderBox> rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: widget,
        ),
      ).attachToRenderTree(buildOwner);

      ///adding the rootElement to the buildScope
      buildOwner.buildScope(rootElement);

      /// finialize the buildOwner
      buildOwner.finalizeTree();

      ///Flush Layout
      pipelineOwner.flushLayout();

      /// Flush Compositing Bits
      pipelineOwner.flushCompositingBits();

      /// Flush paint
      pipelineOwner.flushPaint();

      /// we start the createImageProcess once we have the repaintBoundry of
      /// the widget we attached to the widget tree.
      final ui.Image image = await repaintBoundary.toImage(pixelRatio: pixelRatio);

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      print("___ $e");
    }
  }
}

class Screenshot<T> extends StatefulWidget {
  final Widget? child;
  final ScreenShotCustomize controller;

  const Screenshot({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key);

  @override
  State<Screenshot> createState() {
    return new ScreenshotState();
  }
}

class ScreenshotState extends State<Screenshot> with TickerProviderStateMixin {
  late ScreenShotCustomize _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _controller._containerKey,
      child: widget.child,
    );
  }
}

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}
