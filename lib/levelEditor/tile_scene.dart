import 'dart:ui';
import 'package:flutter/material.dart' hide Image;
import 'package:vector_math/vector_math_64.dart' hide Triangle, Vector4, Colors;
import 'level_editor.dart';
import '../editors/editors.dart';

class TileScene{
  TileScene({
    this.onUpdate
  }){
    update();
  }

  List<TileImage> tileSets = [];
  Image? allTileImage;
  int selectedTileSet = 0;
  String? fileName;
  Camera camera = Camera();

  VoidCallback? onUpdate;
  VoidCallback? onTap;

  bool isControlPressed = false;
  bool isClicked = false;
  List<SelectedTile> tileTappedOn = [];
  List<SelectedTile> prevTileTappedOn = [];
  SelectedTile tileHoveringOn = SelectedTile();
  Offset? tapLocation;
  Offset? hoverLocation;
  bool rayCasting = false;

  List<SelectedTile> clickedObject(){
    if(isClicked){
      prevTileTappedOn = tileTappedOn;
      tapLocation = null;
      isClicked = false;
    }
    else if(tileTappedOn.isEmpty){
      prevTileTappedOn = tileTappedOn;
    }
    return prevTileTappedOn;
  }
  SelectedTile hoverObject(){
    return tileHoveringOn;
  }

  void render(Canvas canvas, Size size){
    if(tileSets.isEmpty || allTileImage == null) return;
    camera.zoomCamera(tileSets[selectedTileSet].zoom(camera.viewportWidth));
    Rect totalRect = Rect.fromLTWH(0, 0, camera.viewportWidth, camera.viewportHeight);
    Vector3 newPosition = Vector3.copy(tileSets[selectedTileSet].position)..scale(camera.zoom);
    newPosition.applyMatrix4(camera.lookAtMatrix);

    double scale = (camera.viewportWidth)/(tileSets[selectedTileSet].size.width);
    
    canvas.drawAtlas(
      allTileImage!, 
      [RSTransform.fromComponents(
        rotation: 0, 
        scale: scale, 
        anchorX: 0, 
        anchorY: 0, 
        translateX: newPosition.x,
        translateY: newPosition.y
      )], 
      [Rect.fromLTWH(
        0, 
        tileSets[selectedTileSet].offsetHeight.toDouble(), 
        tileSets[selectedTileSet].size.width, 
        tileSets[selectedTileSet].size.height
      )], 
      [], 
      BlendMode.srcOver, 
      null, 
      Paint()
    );
    if(tileSets[selectedTileSet].grid.rects.isNotEmpty){
      _drawGrid(canvas,totalRect);
    }
    if(!isClicked){
      tapLocation = null;
    }
  }
  void _drawGrid(Canvas canvas, Rect totalRect){
    if(tileSets[selectedTileSet].grid.rects.isEmpty) return;
    
    for(int i = 0; i < tileSets[selectedTileSet].grid.rects.length;i++){
      Size size = Size(
        tileSets[selectedTileSet].grid.rects[i].width,
        tileSets[selectedTileSet].grid.rects[i].height
      )*camera.zoom;

      Vector3 newPosition = Vector3.copy(tileSets[selectedTileSet].grid.position[i])..scale(camera.zoom);
      newPosition.applyMatrix4(camera.lookAtMatrix);
      Rect rect = Rect.fromLTWH(newPosition.x, newPosition.y, size.width, size.height);

      bool isTapped = false;
      bool isHover = false;

      bool isDifferent = true;
      if(tileTappedOn.isNotEmpty){
        for(int j = 0; j < tileTappedOn.length;j++){
          if(tileTappedOn[j].rect == tileSets[selectedTileSet].grid.rects[i]){
            isTapped = true;
            isDifferent = false;
            break;
          }
        }
      }
      if(tapLocation != null && rect.contains(tapLocation!) && isDifferent && !isClicked){
        isClicked = true;
        if(tileTappedOn.isNotEmpty && !isControlPressed){
          tileTappedOn = [];
        }
        if((!isControlPressed && tileTappedOn.isEmpty) || (tileTappedOn.isNotEmpty && isControlPressed)){
          tileTappedOn.add(
            SelectedTile(
              tileSet: selectedTileSet,
              rect: tileSets[selectedTileSet].grid.rects[i],
              gridLocation: i
            )
          );
        }
        isTapped = true;
      }
      if(hoverLocation != null && rect.contains(hoverLocation!)){
        tileHoveringOn = SelectedTile();
        isHover = true;
      }

      final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 0.025
      ..blendMode = BlendMode.srcOver;

      if(isHover || isTapped){
        paint.color = isHover?Colors.blue:Colors.green;
        paint.strokeWidth = 2;
      }

      canvas.drawRect(rect, paint);
    }
  }

  void update() {
    if (onUpdate != null) onUpdate!();
  }
  void clear(){
    isClicked = false;
    tileTappedOn = [];
    prevTileTappedOn = [];
    tileHoveringOn = SelectedTile();
    tileSets = [];
  }
  // Mark needs update texture
  void updateTapLocation(Offset? details) {
    tapLocation = details;
    isClicked = false;
    update();
  }
  void updateHoverLocation(Offset? details) {
    hoverLocation = details;
    update();
  }
}

