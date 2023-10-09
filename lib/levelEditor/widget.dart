import 'package:flutter/gestures.dart';
import 'model/model_renderer.dart';
import '../navigation/right_click.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors,Triangle;
import 'level_editor.dart';
import '../editors/editors.dart';
import 'package:flutter/material.dart';
import 'text_edit.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

typedef void SceneCreatedCallback(LevelScene scene);
enum LevelEditorCallbacks{onTap,removeObject,save,open,undo,copy,paste,cut,newObject, nameChange}

class LevelEditor extends StatefulWidget {
  const LevelEditor({
    Key? key,
    this.interactive = true,
    this.onSceneCreated,
    this.onSceneUpdated,
    this.callback,
    required this.scene,
  }) : super(key: key);

  final bool interactive;
  final SceneCreatedCallback? onSceneCreated;
  final VoidCallback? onSceneUpdated;
  final LevelScene scene;
  final void Function({required LevelEditorCallbacks call, Offset? details})? callback;
  
  @override
  LevelEditorState createState() => LevelEditorState();
}

class LevelEditorState extends State<LevelEditor> {
  late LevelScene scene;
  Offset _lastFocalPoint = const Offset(0,0);
  double? _lastZoom;
  double _scroll = 1.0;
  double _scale = 0;
  int _mouseType = -1;
  List<int> keyDown = [];
  late RightClick rightClick;
  bool isSecondTime = false;
  bool didStart = false;
  HotKeys hotKeys = HotKeys();
  TextEdit? textEdit;
  LongPressDownDetails? onLongPressDown;
  
  final FocusNode _focusNode = FocusNode();
  List<RightClickOptions> handelRightClick(){
    List<RightClickOptions> toShow = [
      RightClickOptions.addCollision,
      RightClickOptions.addObject,
    ];
    if(scene.objectTappedOn.isNotEmpty){
      if(scene.objectTappedOn.length == 1 
        && (scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn.first.objectLocation].type == SelectedType.atlas
        || scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn.first.objectLocation].type == SelectedType.image)
      ){
        toShow += [RightClickOptions.flipHorizontal,RightClickOptions.flipVertical,RightClickOptions.editName];
      }
      if(scene.objectTappedOn.length == 1 && scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn.first.objectLocation].type == SelectedType.object){
        toShow += [RightClickOptions.editName,RightClickOptions.changeColor];
      }
      toShow += [
        RightClickOptions.remove,
        RightClickOptions.bringToFront,
        RightClickOptions.sendToBack,
        RightClickOptions.copy,
        RightClickOptions.cut
      ];
      if(scene.objectsCopied.isNotEmpty){
        toShow.add(RightClickOptions.paste);
      }
    }
    else if(scene.objectsCopied.isNotEmpty){
      toShow = [
        RightClickOptions.addCollision,
        RightClickOptions.addObject,     
        RightClickOptions.paste,
      ];
    }

    return toShow;
  }
  void rightClickActions(RightClickOptions options){
    switch (options) {
      case RightClickOptions.cut:
        widget.scene.cut();
        break;
      case RightClickOptions.copy:
        widget.scene.copy();
        break;
      case RightClickOptions.paste:
        widget.scene.paste();
        break;
      case RightClickOptions.addObject:
        widget.scene.addObject(Object(
          type: SelectedType.object,
          name: 'Object'
        ));
        break;
      case RightClickOptions.sendToBack:
        widget.scene.sendToBack();
        break;
      case RightClickOptions.editName:
        textEdit?.open(_lastFocalPoint,scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn.first.objectLocation].name);
        break;
      case RightClickOptions.changeColor:
        changeColor(
          context, 
          scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn.first.objectLocation].color
        ).then((value){
          if(value != null){
            scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn.first.objectLocation].changeColor(value);
          }
        });
        break;
      case RightClickOptions.bringToFront:
        widget.scene.bringToFront();
        break;
      case RightClickOptions.addCollision:
        widget.scene.addObject(Object(
          type: SelectedType.collision,
          name: 'Collision',
          color: Colors.green.withAlpha(180),
          size: const Size(50,5),
        ));
        break;
      default:
    }

    SelectedObjects? selectedObject = scene.objectTappedOn.isNotEmpty?scene.objectTappedOn[0]:null;
    if(selectedObject != null){
      switch (options) {
        
        case RightClickOptions.remove:
          scene.removeObject(selectedObject.objectLocation);
          break;
        case RightClickOptions.flipHorizontal:
          scene.levelInfo[scene.selectedLevel].objects[selectedObject.objectLocation].flipHorizontal();
          break;
        case RightClickOptions.flipVertical:
          scene.levelInfo[scene.selectedLevel].objects[selectedObject.objectLocation].filpVertical();
          break;
        default:
      }
    }
    rightClick.closeMenu();
  }
  void _handleSavePosition(){
    if(scene.objectTappedOn.isNotEmpty && hotKeys.movePressed){
      for(int i = 0; i < scene.objectTappedOn.length; i++){
        Object obj = scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn[i].objectLocation];
        obj.savePosition();
      }
    }
    setState(() {});
  }
  void _handleScaleStart(Offset localFocalPoint) {
    if((scene.isClicked && (_mouseType == 1 || _mouseType == -1)) || hotKeys.scalePressed || hotKeys.rotatePressed){
      for(int i = 0; i < scene.objectTappedOn.length; i++){
        Object obj = scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn[i].objectLocation];
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
  void _handleScaleUpdate(double? scale, Offset localFocalPoint, bool pan) {
    if(scene.isClicked && (_mouseType == 1 || _mouseType == -1)){
      for(int i = 0; i < scene.objectTappedOn.length; i++){
        Object obj = scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn[i].objectLocation];
        obj.updatePosition(toVector2(localFocalPoint),1/scene.camera.zoom);
      }
    }
    else{
      if(!pan){
        double zoom = scene.camera.zoom;
        if (_lastZoom == null){
          _scale = scale!;
          _lastZoom = scene.camera.zoom;
        }
        if(scale != null){
          zoom = _lastZoom !* scale;
        }
        if(zoom < 0.5){
          zoom = 0.5;
          scale = 0.5;
        }
        scene.camera.zoomCamera(zoom,toVector2(localFocalPoint),Vector2(-0.8999999999,0.305));
      }
      else if((_mouseType == 4 || _mouseType == -1) && pan){
        // if(scene.isControlPressed){
        //   scene.camera.trackBall(toVector2(localFocalPoint), 10);
        // }
        // else{
          scene.camera.panCamera(toVector2(localFocalPoint), 1.5);
        //}
      }
    }
    setState(() {});
  }
  void _handleSelectedObjects(int x, int y, [Offset? localFocalPoint]){
    for(int i = 0; i < scene.objectTappedOn.length;i++){
      if(hotKeys.movePressed){
        scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn[i].objectLocation].move(x,y);
      }
      else if(hotKeys.scalePressed && hotKeys.directionPressed){
        scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn[i].objectLocation].scaleObject(x,y);
      }
      else if(hotKeys.scalePressed && localFocalPoint != null){
        scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn[i].objectLocation].scaleMouse(toVector2(localFocalPoint),1/scene.camera.zoom);
      }
      else if(hotKeys.rotatePressed&& localFocalPoint != null){
        scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn[i].objectLocation].rotateMouse(toVector2(localFocalPoint),1/scene.camera.zoom);
      }
      setState((){});
    }
  }
  void _handleKeyEvent(RawKeyEvent event) {
    scene.isControlPressed = event.isControlPressed;
    HotKeyTypes type = hotKeys.getHotKeyType(event);
    if(event.runtimeType.toString() == 'RawKeyDownEvent' ){
      if(type == HotKeyTypes.number || type == HotKeyTypes.backSpace){
        int x = 0;
        int y = 0;
        if(type == HotKeyTypes.backSpace){
          if(hotKeys.currentMove.length > 1){
            hotKeys.currentMove = hotKeys.currentMove.substring(0,hotKeys.currentMove.length-1);
          }
          else{
            if(hotKeys.currentMove == '-'){
              hotKeys.currentMove = '-0';
            }
            else{
              hotKeys.currentMove = '0';
            }
          }
        }
        else if(event.character != '-'){
          hotKeys.currentMove += event.character!;
        }
        else if(!hotKeys.scalePressed && event.character == '-'){
          if(hotKeys.currentMove == '' || hotKeys.currentMove == '0'){
            hotKeys.currentMove = '-0';
          }
          else{
            hotKeys.currentMove = '-${hotKeys.currentMove}';
          }
        }

        if(hotKeys.isDirectionX){
          x = int.parse(hotKeys.currentMove);
        }
        else{
          y = int.parse(hotKeys.currentMove);
        }

        if(hotKeys.directionPressed){
          _handleSelectedObjects(x, y);
        }
      }
      else if(type != HotKeyTypes.none ){
        hotKeys.reset();
        didStart = false;
        if(type == HotKeyTypes.delete){
          widget.scene.removeSelectedObject();
        }
        else if(type == HotKeyTypes.copy){
          widget.scene.copy();
        }
        else if(type == HotKeyTypes.enter){
          _handleSavePosition();
          scene.updateTapLocation(const Offset(0,0));
          if(widget.callback != null){
            widget.callback!(call: LevelEditorCallbacks.onTap,details: const Offset(0,0));
          }
        }
        else if(type == HotKeyTypes.paste){
          widget.scene.paste();
        }
        else if(type == HotKeyTypes.save){
          if(widget.callback != null){
            widget.callback!(call: LevelEditorCallbacks.save);
          }
        }
        else if(type == HotKeyTypes.newSheet){
          if(widget.callback != null){
            widget.callback!(call: LevelEditorCallbacks.newObject);
          }
        }
        else if(type == HotKeyTypes.open){
          if(widget.callback != null){
            widget.callback!(call: LevelEditorCallbacks.open);
          }
        }
        else if(type == HotKeyTypes.cut){
          widget.scene.cut();
        }
        else if(type == HotKeyTypes.move){
          hotKeys.movePressed = true;
        }
        else if(type == HotKeyTypes.scale){
          hotKeys.scalePressed = true;
        }
        else if(type == HotKeyTypes.rotate){
          hotKeys.rotatePressed = true;
        }
      }
    }
   
  }
  void textEditComplete(String val){
    if(scene.objectTappedOn.isNotEmpty && scene.objectTappedOn.length == 1){
      scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn[0].objectLocation].name = val;
      widget.callback!(call: LevelEditorCallbacks.nameChange);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    rightClick = RightClick(
      context: context,
      style: null,
      onTap: rightClickActions,
    );
    textEdit = TextEdit(
      context: context,
      onEditingComplete: textEditComplete
    );
    scene = widget.scene;
    scene.onUpdate = () => setState(() {
      if(widget.onSceneUpdated != null) widget.onSceneUpdated!();
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
    rightClick.dispose();
    textEdit?.close();
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
        child:MouseRegion(
          cursor: _mouseType == 4?SystemMouseCursors.move:MouseCursor.defer,
          onHover: (details){
            if(hotKeys.scalePressed || hotKeys.rotatePressed){
              if(!didStart){
                _handleScaleStart(details.localPosition);
                didStart = true;
              }
              else{
                _handleSelectedObjects(0,0,details.localPosition);
              }
            }
          },
          child: Listener(
            onPointerDown: (event){
              hotKeys.reset();
              didStart = false;
              if(event.buttons == 2){
                rightClick.openMenu('',event.localPosition,handelRightClick());
              }
              else{
                rightClick.closeMenu();
              }
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
              if(scene.rayCasting){
                scene.updateHoverLocation(details.localPosition);
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
                _handleScaleUpdate(_scroll,details.localPosition,false);
              }

            },
            child: GestureDetector(
              onLongPress: (){
                if(!rightClick.isMenuOpen && _mouseType == -1){
                  rightClick.openMenu('',onLongPressDown!.localPosition,handelRightClick());
                }
                else{
                  textEdit?.open(onLongPressDown!.globalPosition,scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn.first.objectLocation].name);
                }
              },
              onLongPressDown: (LongPressDownDetails event){
                onLongPressDown = event;
              },
              onScaleStart: (details){
                _handleScaleStart(details.localFocalPoint);
              },
              onScaleUpdate: (details){
                if(_mouseType == 1 && (scene.brushStyle == BrushStyles.stamp || scene.brushStyle == BrushStyles.erase)){
                  scene.updateTapLocation(details.localFocalPoint);
                }
                bool pan = false;
                if(_scale < details.scale+0.1 && _scale > details.scale-0.1){
                  pan = true;
                }
                _handleScaleUpdate(details.scale,details.localFocalPoint, pan);
              },
              onScaleEnd: (details){
                setState(() {
                  
                });
                scene.update();
              },
              onTapDown: (TapDownDetails details){
                _lastFocalPoint = details.localPosition;
                _lastZoom = null;
                FocusScope.of(context).requestFocus(_focusNode);
                _handleSavePosition();
                textEdit?.close();
                scene.updateTapLocation(details.localPosition);
                if(widget.callback != null){
                  widget.callback!(call: LevelEditorCallbacks.onTap,details: details.localPosition);
                }
                if(rightClick.isMenuOpen){
                  rightClick.closeMenu();
                }
              },
              onTapUp: (TapUpDetails details){
                if(widget.callback != null){
                  widget.callback!(call: LevelEditorCallbacks.onTap,details: details.localPosition);
                }
                if(scene.objectTappedOn.isNotEmpty && scene.objectTappedOn.length == 1 && !scene.isControlPressed){
                  textEdit?.open(details.globalPosition,scene.levelInfo[scene.selectedLevel].objects[scene.objectTappedOn.first.objectLocation].name);
                }
                setState(() {});
                scene.update();
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
  final LevelScene _scene;
  late ModelRender model;
  _CubePainter(this._scene){
    model = ModelRender(_scene);
  }

  @override
  void paint(Canvas canvas, Size size) {
    model.render(canvas, size);
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(_CubePainter oldDelegate) {
    return oldDelegate._scene.camera != _scene.camera || oldDelegate._scene.levelInfo != _scene.levelInfo;
  }
}
Future<Color?> changeColor(BuildContext context, Color selectedColor ) async {
  return showDialog<Color>(
    context: context,
    //barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      Color color = selectedColor;
      return AlertDialog(
        title: const Text('Pick a color!'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (newColor){
              color = newColor;
            },
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Got it'),
            onPressed: () {
              Navigator.pop(context,color);
            },
          ),
        ],
      );
    }
  );
}
/// Convert Offset to Vector2
Vector2 toVector2(Offset? value) {
  return value != null?Vector2(value.dx, value.dy):Vector2(0,0);
}
