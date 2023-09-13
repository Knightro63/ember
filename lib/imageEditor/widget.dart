import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart' hide Image;
import '../levelEditor/widget.dart';
import 'image_editor.dart';
import '../editors/editors.dart';
import 'package:flutter/material.dart';

typedef void SceneCreatedCallback(ImageScene scene);

class ImageEditor extends StatefulWidget {
  const ImageEditor({
    Key? key,
    required this.scene,
    this.interactive = true,
    this.onSceneCreated,
    this.onSceneUpdated,
  }):super(key: key);

  final bool interactive;
  final VoidCallback? onSceneUpdated;
  final SceneCreatedCallback? onSceneCreated;
  final ImageScene scene;
  
  @override
  _ImageEditorState createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  late ImageScene scene;
  Offset? _lastFocalPointZoom;
  double? _lastZoom;
  double _scroll = 1.0;
  double _scale = 0;
  int _mouseType = 0;
  bool didStart = false;
  HotKeys hotKeys = HotKeys();
  
  final FocusNode _focusNode = FocusNode();

  void _handleScaleStart(Offset localFocalPoint) {
    if(scene.isClicked && _mouseType == 1  && scene.objectTappedOn[0].type == SelectedType.rect){
      for(int i = 0; i < scene.objectTappedOn.length; i++){
        Object obj = scene.collisions[scene.objectTappedOn[i].animation];
        obj.updatePositionStart(toVector2(localFocalPoint));
      }
    }
    else{
      scene.camera.panCameraStart(toVector2(localFocalPoint));
      _lastZoom = null;
    }
    didStart = true;
    setState(() {});
  }
  void _handleSavePosition(){
    if(scene.objectTappedOn.isNotEmpty && hotKeys.movePressed){
      if(scene.objectTappedOn[0].type == SelectedType.rect ){
        for(int i = 0; i < scene.objectTappedOn.length; i++){
          Object obj = scene.collisions[scene.objectTappedOn[i].animation];
          obj.savePosition();
        }
      }
    }
    setState(() {});
  }
  void _handleScaleUpdate(double scale, Offset localFocalPoint, bool pan) {
    if((scene.isClicked && _mouseType == 1  && scene.objectTappedOn[0].type != SelectedType.image)|| hotKeys.scalePressed){
      for(int i = 0; i < scene.objectTappedOn.length; i++){
        Object obj = scene.collisions[scene.objectTappedOn[i].animation];
        obj.updatePosition(toVector2(localFocalPoint),1/scene.camera.zoom);
      }
    }
    else{
      if(!pan){
        if (_lastZoom == null){
          _scale = scale;
          _lastZoom = scene.camera.zoom;
        }
        scene.camera.zoomCamera(scene.camera.zoom);
      }
      else if(_mouseType == 4 && pan){
        scene.camera.panCamera(toVector2(localFocalPoint), 1.5);
      }
    }
    setState(() {});
  }
  void _handleSelectedObjects(int x, int y, [Offset? localFocalPoint]){
    for(int i = 0; i < scene.objectTappedOn.length;i++){
      if(hotKeys.scalePressed){
        if(scene.objectTappedOn[i].type == SelectedType.rect){
          scene.collisions[scene.objectTappedOn[i].animation].scaleMouse(toVector2(localFocalPoint),1/scene.camera.zoom);
        }
      }

      setState((){});
    }
  }
  void _handleKeyEvent(RawKeyEvent event) {
    scene.isControlPressed = event.isControlPressed;
    HotKeyTypes type = hotKeys.getHotKeyType(event);
    
    if(event.runtimeType.toString() == 'RawKeyDownEvent'){
      if(type != HotKeyTypes.none ){
        hotKeys.reset();
        if(type == HotKeyTypes.scale){
          hotKeys.scalePressed = true;
        }
      }
    }
    setState((){});
  }

  @override
  void initState() {
    super.initState();
    scene = widget.scene;
    scene.onUpdate = () => setState(() {
      if(widget.onSceneUpdated != null)widget.onSceneUpdated!();
    });
    // prevent setState() or markNeedsBuild called during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSceneCreated?.call(scene);
      _scroll = scene.camera.zoom;
    });
  }
  @override
  void dispose(){
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
      scene.camera.viewportWidth = constraints.maxWidth;
      scene.camera.viewportHeight = constraints.maxHeight;
      final customPaint = CustomPaint(
        painter: _CubePainter(scene),
        size: Size(constraints.maxWidth, constraints.maxHeight),
        isComplex: true,
      );
      return widget.interactive
        ?RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyEvent,
        child: MouseRegion(
          cursor: _mouseType == 4?SystemMouseCursors.move:MouseCursor.defer,
          onHover: (details){
          },
          child: Listener(
            onPointerDown: (event){
              hotKeys.reset();
              didStart = false;
            },
            onPointerUp: (details){
              _mouseType = 5;
            },
            onPointerCancel: (details){
              _mouseType = 5;
            },
            onPointerMove: (details){
              _mouseType = details.buttons;
            },
            onPointerHover: (details){
              if(hotKeys.scalePressed){
                if(!didStart){
                  _handleScaleStart(details.localPosition);
                  didStart = true;
                }
                else{
                  _handleSelectedObjects(0,0,details.localPosition);
                }
              }
            },
            onPointerSignal: (details){
              _mouseType = 5;
              if(details is PointerScrollEvent){
                if (_lastZoom == null){
                  _scroll = _scroll;
                }
                else{ 
                  if(scene.camera.zoom > 0.5 || details.scrollDelta.dy > 0){
                    _scroll = _scroll+details.scrollDelta.dy*0.01;
                  }
                }
                _lastFocalPointZoom ??= details.localPosition;
                _handleScaleUpdate(_scroll,details.localPosition,false);
              }

            },
            child: GestureDetector(
              onScaleStart: (details){
                _handleScaleStart(details.localFocalPoint);
              },
              onScaleUpdate: (details){
                bool pan = false;
                if(_scale < details.scale+0.1 && _scale > details.scale-0.1){
                  pan = true;
                }
                _handleScaleUpdate(details.scale,details.localFocalPoint, pan);
              },
              onTapDown: (TapDownDetails details){
                //_scroll = 0;
                _lastZoom = null;
                FocusScope.of(context).requestFocus(_focusNode);
                _handleSavePosition();
                scene.updateTapLocation(details.localPosition);
              },
              onTapUp: (TapUpDetails details){
              },
              child: customPaint,
            )
          )
        )
        )
      : customPaint;
    });
  }
}

class _CubePainter extends CustomPainter {
  final ImageScene _scene;
  const _CubePainter(this._scene);

  @override
  void paint(Canvas canvas, Size size) {
    _scene.render(canvas, size);
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(_CubePainter oldDelegate) {
    return true;
  }
}
