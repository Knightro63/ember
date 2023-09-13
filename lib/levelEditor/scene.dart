import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'flood_fill.dart';
import 'model/model_renderer.dart';
import 'package:vector_math/vector_math_64.dart' hide Triangle, Vector4, Colors;
import 'level_editor.dart';
import '../editors/editors.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:math' as Math;

enum BrushStyles{stamp,fill,erase,move}

class LevelScene {
  LevelScene({
    VoidCallback? onStartUp,
    VoidCallback? update,
  }){
    _onStartUp = onStartUp;
    levelInfo.add(
      Levels(
        name: 'Level1',
      )
    );
  }

  Image? levelImage;
  String? fileName;
  Camera camera = Camera();
  List<SelectedTile> selectedTile = [];

  SelectedObjects? selectedObject;
  int? selectedLoadedObject;
  int selectedLevel = 0;
  int selectedTileLocation = 0;

  List<TileImage> tileSets = [];
  Image? allTileImage;
  List<LoadedObject> loadedObjects = [];
  Image? allObjectImage;
  
  BrushStyles brushStyle = BrushStyles.move;
  bool isControlPressed = false;
  VoidCallback? onUpdate;
  VoidCallback? _onStartUp;

  bool isClicked = false;
  bool loaded = false;
  double? currentSize;
  List<SelectedObjects> objectTappedOn = [];
  List<Object> objectsCopied = [];
  List<SelectedObjects> prevObjectTappedOn = [];
  SelectedObjects? objectHoveringOn;
  Offset? tapLocation;
  Offset? hoverLocation;

  bool rayCasting = false;
  bool updateMinMap = true;
  bool updateAnimations = false;

  List<Levels> levelInfo = [];

  Offset _getPoint(Offset point,Offset center, double angle){
    //TRANSLATE TO ORIGIN
    double x = point.dx - center.dx;
    double y = point.dy - center.dy;

    //APPLY ROTATION
    double newX = x * Math.cos(angle) - y * Math.sin(angle);
    double newY = x * Math.sin(angle) + y * Math.cos(angle);

    //TRANSLATE BACK
    return Offset(newX + center.dx, newY + center.dy);
  }
  bool _isBelow(Offset p1, Offset p2, Offset p3){
    if(tapLocation == null) return false;
    Offset p = tapLocation!;
    double sign (double hx, double hy, double ix, double iy, double kx, double ky){
      return (hx - kx) * (iy - ky) - (ix - kx) * (hy - ky);
    }
    double d1, d2, d3;
    bool hasNeg, hasPos;

    d1 = sign(p.dx, p.dy ,p1.dx, p1.dy, p2.dx, p2.dy);
    d2 = sign(p.dx, p.dy, p2.dx, p2.dy, p3.dx, p3.dy);
    d3 = sign(p.dx, p.dy, p3.dx, p3.dy, p1.dx, p1.dy);

    hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return !(hasNeg && hasPos);
  }
  bool doesContain(Rect rect,double angle){
    Offset topLeft = _getPoint(rect.topLeft,rect.center, angle);
    Offset topRight = _getPoint(rect.topRight,rect.center, angle);
    Offset bottomLeft = _getPoint(rect.bottomLeft,rect.center, angle);
    Offset bottomRight = _getPoint(rect.bottomRight,rect.center, angle);

    return _isBelow(topLeft,topRight,bottomLeft)||_isBelow(bottomLeft, bottomRight,topRight);
  }

  List<SelectedObjects> clickedObject(){
    if(isClicked){
      prevObjectTappedOn = objectTappedOn;
      tapLocation = null;
      currentSize = null;
      isClicked = false;
    }
    else if(objectTappedOn.isEmpty){
      prevObjectTappedOn = objectTappedOn;
    }
    return prevObjectTappedOn;
  }
  SelectedObjects? hoverObject(){
    return objectHoveringOn;
  }

  void render(Canvas canvas, Size size){
    final Rect totalRect = Rect.fromLTWH(0, 0, camera.viewportWidth, camera.viewportHeight);
    canvas.saveLayer(totalRect,Paint());
    _drawGrid(canvas);
    generateMiniMap();
    if(levelInfo[selectedLevel].objects.isEmpty && !isClicked){
      tapLocation = null;
    }

    _hideOutside(canvas, totalRect);
    canvas.restore();
  }

  void _hideOutside(Canvas canvas, Rect totalRect){
    Path path = Path();
    final Size size = levelInfo[selectedLevel].grid.boxSize*camera.zoom;
    final Vector3 newPosition = Vector3.zero();
    newPosition.applyMatrix4(camera.lookAtMatrix);

    path.addRect(
      Rect.fromLTWH(
        newPosition.x+newPosition.x*(camera.zoom-1), 
        newPosition.y+newPosition.y*(camera.zoom-1), 
        size.width*levelInfo[selectedLevel].grid.width, 
        size.height*levelInfo[selectedLevel].grid.height
      )
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(totalRect),
        path..close(),
      ),
        Paint()..color = Colors.grey[900]!.withOpacity(0.5)
        ..blendMode = BlendMode.srcOver,
    );
  }
  void _drawGrid(Canvas canvas){
    final int length = levelInfo[selectedLevel].grid.width*levelInfo[selectedLevel].grid.height;
    if(levelInfo[selectedLevel].currentGridLength != length){
      levelInfo[selectedLevel].updateTiles(length);
    }
    if(levelInfo[selectedLevel].grid.show){
      int j = 0;
      int k = 0;
      Size size = levelInfo[selectedLevel].grid.boxSize;

      TileAtlas tiles = TileAtlas();
      final int selectedLayer = levelInfo[selectedLevel].selectedTileLayer;
      List<TileRects> tileRects = levelInfo[selectedLevel].tileLayer[selectedLayer].tiles;
      
      for(int h = 0; h < length; h++){
        if(h != 0 && h%levelInfo[selectedLevel].grid.width != 0){
          j++;
        }
        else if(h != 0 && h%levelInfo[selectedLevel].grid.width == 0){
          k++;
          j = 0;
        }
        int i = j+k*levelInfo[selectedLevel].maxGridSize.width.toInt();

        final Vector3 newPosition = Converter.toVector3(Vector3.zero(), Offset(j*size.width,k*size.height));
        newPosition.applyMatrix4(camera.lookAtMatrix);

        final Rect rect = Rect.fromLTWH(
          newPosition.x+newPosition.x*(camera.zoom-1), 
          newPosition.y+newPosition.y*(camera.zoom-1), 
          size.width*(camera.zoom), 
          size.height*(camera.zoom)
        );
        bool isHover = false;

        final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = levelInfo[selectedLevel].grid.color
        ..strokeWidth = levelInfo[selectedLevel].grid.lineWidth
        ..blendMode = BlendMode.srcOver;

        if(selectedTile.isNotEmpty && brushStyle != BrushStyles.move){
          if(tapLocation != null && rect.contains(tapLocation!)){
            if(!isClicked && brushStyle == BrushStyles.stamp){
              final double off = tileSets[selectedTile[0].tileSet!].offsetHeight.toDouble();
              final Rect updateRect = Rect.fromLTWH(selectedTile[0].rect!.left, selectedTile[0].rect!.top+off, selectedTile[0].rect!.width, selectedTile[0].rect!.height);
              tileRects[i] = TileRects(
                position: [j,k],
                tileSet: selectedTile[0].tileSet!,
                rect: updateRect,
                isAnimation: selectedTile[0].isAnimation,
                useAnimation: selectedTile[0].animationLocation,
                transform: RSTransform.fromComponents(rotation: 0, scale: camera.zoom, anchorX: 0, anchorY: 0, translateX: rect.left, translateY: rect.top)
              );
              updateMinMap = true;
              selectedTileLocation = i;
            }
            else if(!isClicked && brushStyle == BrushStyles.fill){
              selectedTileLocation = i;
              floodFill();
              updateMinMap = true;
            }
            else if(!isClicked && BrushStyles.erase == brushStyle){
              tileRects[i] = TileRects();
              updateMinMap = true;
            }
            isClicked = true;
          }
          if(hoverLocation != null && rect.contains(hoverLocation!) && selectedTile.isNotEmpty){
            isHover = true;
          }
          
          if(isHover && tileSets.isNotEmpty && selectedTile.isNotEmpty && BrushStyles.move != brushStyle){
            paint.color = isHover?Colors.blue:Colors.green;
            paint.strokeWidth = levelInfo[selectedLevel].grid.lineWidth*6;
            final double scale = (camera.zoom*levelInfo[selectedLevel].grid.boxSize.width/selectedTile[0].rect!.width);
            if(brushStyle == BrushStyles.stamp || brushStyle == BrushStyles.fill){
              double off = tileSets[selectedTile[0].tileSet!].offsetHeight.toDouble();
              Rect updateRect = Rect.fromLTWH(
                selectedTile[0].rect!.left, 
                selectedTile[0].rect!.top+off, 
                selectedTile[0].rect!.width, 
                selectedTile[0].rect!.height
              );
              canvas.drawAtlas(
                allTileImage!,
                [RSTransform.fromComponents(
                  rotation: 0, 
                  scale: scale, 
                  anchorX: 0, 
                  anchorY: 0, 
                  translateX: rect.left, 
                  translateY: rect.top
                )], 
                [updateRect], 
                [], 
                BlendMode.srcOver, 
                null, 
                Paint()
              );
            }
          }
        }

        if(isHover && BrushStyles.move != brushStyle){
          canvas.drawRect(rect, paint);
        }
        else if(tileSets.isNotEmpty && !isHover){
          bool hasTile = false;
          for(int l = 0; l < levelInfo[selectedLevel].tileLayer.length; l++){
            if(levelInfo[selectedLevel].tileLayer[l].visible && levelInfo[selectedLevel].tileLayer[l].tiles[i].position.isNotEmpty){
              hasTile = true;
              final List<TileRects> newTileRects = levelInfo[selectedLevel].tileLayer[l].tiles;
              Rect newRect = newTileRects[i].rect;
              if(newTileRects[i].isAnimation){
                final int frame = levelInfo[selectedLevel].animations[newTileRects[i].useAnimation].useFrame;
                final int set = levelInfo[selectedLevel].animations[newTileRects[i].useAnimation].tileSet;
                final double off = tileSets[set].offsetHeight.toDouble();
                newRect = Rect.fromLTWH(
                  levelInfo[selectedLevel].animations[newTileRects[i].useAnimation].rects[frame].left, 
                  levelInfo[selectedLevel].animations[newTileRects[i].useAnimation].rects[frame].top+off, 
                  levelInfo[selectedLevel].animations[newTileRects[i].useAnimation].rects[frame].width, 
                  levelInfo[selectedLevel].animations[newTileRects[i].useAnimation].rects[frame].height
                );
              }
              final double scale = (camera.zoom*levelInfo[selectedLevel].grid.boxSize.width/newTileRects[i].rect.width);

              tiles.rect.add(newRect);
              tiles.transform.add(
                RSTransform.fromComponents(rotation: 0, scale: scale, anchorX: 0, anchorY: 0, translateX: rect.left, translateY: rect.top)
              );
            }
          }
          if(!hasTile){
            canvas.drawRect(rect, paint);
          }
        }
        else{
          canvas.drawRect(rect, paint);
        }
      }

      if(tileSets.isNotEmpty){
        if(tiles.rect.isNotEmpty){
          canvas.drawAtlas(
            allTileImage!, 
            tiles.transform, 
            tiles.rect, 
            [], 
            BlendMode.srcOver, 
            null, 
            Paint()
          );
        }
      }
    }
  }
  void generateMiniMap() async{
    if(levelInfo[selectedLevel].objects.isEmpty && allTileImage == null || !updateMinMap) return;
    updateMinMap = false;
    TileAtlas tiles = TileAtlas();
    List<Offset> pos = [];
    List<Offset> text = [];

    if(levelInfo[selectedLevel].tileLayer.isNotEmpty && allTileImage != null){
      for(int j = 0; j < levelInfo[selectedLevel].tileLayer.length;j++){
        List<TileRects> tileRectes = levelInfo[selectedLevel].tileLayer[j].tiles;
        for(int i = 0; i < tileRectes.length; i++){
          if(tileRectes[i].position.isNotEmpty){
            Size size = levelInfo[selectedLevel].grid.boxSize;
            int j = tileRectes[i].position[0];
            int k = tileRectes[i].position[1];
            Vector3 position = Converter.toVector3(
              camera.position, 
              Offset(
                j*size.width,
                k*size.height
              )
            );
            Offset newPosition = Converter.toOffset(camera.position,position);
            double scale = (levelInfo[selectedLevel].grid.boxSize.width/tileRectes[i].rect.width);
            tiles.rect.add(tileRectes[i].rect);
            tiles.transform.add(              
              RSTransform.fromComponents(
                rotation: 0, 
                scale: scale, 
                anchorX: 0, 
                anchorY: 0, 
                translateX: newPosition.dx, 
                translateY: newPosition.dy
              )
            );
          }
        }
      }
    }

    Size size = Size(levelInfo[selectedLevel].grid.boxSize.width*levelInfo[selectedLevel].grid.width,levelInfo[selectedLevel].grid.boxSize.height*levelInfo[selectedLevel].grid.height);
    await _generateImage(tiles,allTileImage,pos,text,allObjectImage,size).then((value){
      levelImage = value;
      //updateMinMap = true;
    });
  }
  
  void copy(){
    objectsCopied = [];
    if(objectTappedOn.isNotEmpty){
      for(int i =0; i < objectTappedOn.length;i++){
        objectsCopied.add(levelInfo[selectedLevel].objects[objectTappedOn[i].objectLocation]);
      }
    }
  }
  void cut(){
    objectsCopied = [];
    if(objectTappedOn.isNotEmpty){
      copy();
      for(int i = 0; i < objectTappedOn.length;i++){
        removeObject(objectTappedOn[i].objectLocation);
      }
      objectTappedOn = [];
      currentSize = null;
      updateMinMap = true;
    }
    update();
  }
  void paste(){
    Vector3 newPosition = Vector3.copy(-camera.position)+Vector3(-camera.viewportWidth/1000,camera.viewportHeight/1000,0)*camera.zoom;
    if(objectsCopied.isNotEmpty){
      objectTappedOn = [];
      currentSize = null;
      for(int i = 0; i < objectsCopied.length;i++){
        levelInfo[selectedLevel].objects.add(
          Object(
            name: objectsCopied[i].name,
            position: newPosition,
            size: objectsCopied[i].size,
            imageLocation: objectsCopied[i].imageLocation,
            type: objectsCopied[i].type,
            color: objectsCopied[i].color,
            layer: objectsCopied[i].layer,
            mesh: objectsCopied[i].mesh,
            rotation: objectsCopied[i].rotation,
            scale :objectsCopied[i].scale,
            scaleAllowed: objectsCopied[i].scaleAllowed
          )
        );
      }
      updateMinMap = true;
    }
    update();
  }
  void bringToFront([int? obj]){
    if(obj != null){
      levelInfo[selectedLevel].objects[obj].layer++;
    }
    else if(objectTappedOn.isNotEmpty){
      for(int i = 0; i < objectTappedOn.length; i++){
        levelInfo[selectedLevel].objects[objectTappedOn[i].objectLocation].layer++;
      }
      updateMinMap = true;
    }
    levelInfo[selectedLevel].objects.sort((Object a, Object b){
      final int az = a.layer;
      final int bz = b.layer;
      //return (az-bz).round();
      if (bz > az) return -1;
      if (bz < az) return 1;
      return 0;
    });
    update();
  }
  void sendToBack([int? obj]){
    if(obj != null){
      levelInfo[selectedLevel].objects[obj].layer--;
    }
    else if(objectTappedOn.isNotEmpty){
      for(int i = 0; i < objectTappedOn.length; i++){
        levelInfo[selectedLevel].objects[objectTappedOn[i].objectLocation].layer--;
      }
      updateMinMap = true;
    }
    levelInfo[selectedLevel].objects.sort((Object a, Object b){
      final int az = a.layer;
      final int bz = b.layer;
      //return (az-bz).round();
      if (bz > az) return -1;
      if (bz < az) return 1;
      return 0;
    });
    update();
  }

  void floodFill(){
    List<TileRects> tileRectes = levelInfo[selectedLevel].tileLayer[levelInfo[selectedLevel].selectedTileLayer].tiles;
    int width = levelInfo[selectedLevel].grid.width;
    int height = levelInfo[selectedLevel].grid.height;
    QueueLinearFloodFiller flood = QueueLinearFloodFiller(
      tileRectes[selectedTileLocation],
      tileRectes,
      selectedTile[0],
      Size(width.toDouble(),height.toDouble()),
      levelInfo[selectedLevel].grid.boxSize*camera.zoom,
      camera
    );

    int y = selectedTileLocation < width?0:(selectedTileLocation/width).floor();
    int x = selectedTileLocation < width?selectedTileLocation:selectedTileLocation-width*y;
    flood.floodFill(x, y).then((value){
      levelInfo[selectedLevel].tileLayer[levelInfo[selectedLevel].selectedTileLayer].tiles = flood.allTiles as List<TileRects>;
    });
  }

  void removeLoadedObject(int location){
    //loadedObjects.removeAt(location);
    loadedObjects[location].show = false;
    updateMinMap = true;
    update();
  }
  void addObject(Object object){
    Vector3 newPosition = Vector3.copy(-camera.position)+Vector3(-camera.viewportWidth/1000,camera.viewportHeight/1000,0)*camera.zoom;

    levelInfo[selectedLevel].objects.add(
      Object(
        scale: object.scale,
        rotation: object.rotation,
        mesh: object.mesh,
        position: newPosition,
        type: object.type,
        size: object.size,
        name: object.name,
        imageLocation: object.imageLocation,
        color: object.color,
        layer: object.layer,
      )
    );
    updateMinMap = true;
    update();
  }
  void removeObject(int location,[bool clearTap = true]){
    levelInfo[selectedLevel].objects.removeAt(location);
    currentSize = null;
    tapLocation = null;
    if(clearTap){
      objectTappedOn = [];
    }
    updateMinMap = true;
    update();
  }
  void removeSelectedObject(){
    objectTappedOn.sort((SelectedObjects a,SelectedObjects b){
      final int az = a.objectLocation;
      final int bz = b.objectLocation;
      //return (az-bz).round();
      if (bz > az) return 1;
      if (bz < az) return -1;
      return 0;
    });
    for(int i = 0; i < objectTappedOn.length; i++){
      removeObject(objectTappedOn[i].objectLocation,false);
    }
    updateMinMap = true;
    objectTappedOn = [];
  }
  void removeTileset(List<int> sprite) {
    sprite.sort();
    for(int i = sprite.length-1; i >= 0;i--){
      tileSets.removeAt(sprite[i]);
      objectTappedOn = [];
      currentSize = null;
      if(tileSets.isEmpty){
        levelImage = null;
      }
    }
    updateMinMap = true;
    update();
  }

  void update() {
    if (onUpdate != null) onUpdate!();
    if(!loaded && _onStartUp != null){
      _onStartUp!();
    }
  }
  void removeLevel(int level){
    if(levelInfo.length == 1){
      levelInfo = [
        Levels(
          name: 'Level1',
        )
      ];
      selectedLevel = 0;
    }
    else{
      levelInfo.removeAt(level);
    }
    
    if(selectedLevel >= levelInfo.length){
      selectedLevel = 0;
    }
    update();
  }
  void addLevel(){
    levelInfo.add(
      Levels(
        name: 'Level${levelInfo.length+1}',
      )
    );
    update();
  }
  void importLevels(List<Levels> levels){
    levelInfo = levels;
    update();
  }
  void clear(){
    allObjectImage = null;
    allTileImage = null;
    levelImage = null;
    selectedLevel = 0;
    selectedTileLocation = 0;
    selectedTile = [];
    tileSets = [];
    selectedObject = null;
    levelInfo = [];
    loadedObjects = [];
    levelInfo = [
      Levels(
        name: 'Level1',
      )
    ];

    isClicked = false;
    objectTappedOn = [];
    prevObjectTappedOn = [];
    objectsCopied = [];
    objectHoveringOn = null;
  }
  
  // Mark needs update texture
  void updateTapLocation(Offset details) {
    if(!isControlPressed){
      objectTappedOn = [];
      currentSize = null;
      isClicked = false;
    }
    tapLocation = details;
    update();
  }
  void updateHoverLocation(Offset details) {
    hoverLocation = details;
    update();
  }
  Future<void> loadObject(
    String path, 
    LoadedType type,
    {bool show = true, 
    List<Rect>? locations, 
    ObjectType? objType, 
    List<String>? names, 
    List<double>? scales
  }) async{
    await _loadImage(path).then((value) async{
      int height = (allObjectImage == null?0:allObjectImage!.height);
      loadedObjects.add(
        LoadedObject(
          size: Size(value.width.toDouble(),value.height.toDouble()),
          objectType: objType??ObjectType.landscape,
          type: type,
          path: path,
          show: show,
          spriteLocations: locations,
          spriteNames: locations == null?names:(names ??List<String>.filled(locations.length, 'Object Names')),
          objectScale: scales,
          offsetHeight: height
        )
      );

      if(allObjectImage == null){
        allObjectImage = value;
      }
      else{
        await _combineImage(allObjectImage!,value).then((img){
          allObjectImage = img;
        });
      }
      update();
    });
  }
  Future<void> updateTileset({required String path, required String name,bool gridUpdate = false, GridType? type, int? gridWidth, int? gridHeight, List<List<Rect>>? collisions}) async{
    if(tileSets.isEmpty  && !kIsWeb){
      fileName = name;
    }
    else{
      fileName = 'untitled';
    }
      
    await _loadImage(path).then((value) async{
      int height = (allTileImage == null?0:allTileImage!.height);
      tileSets.add(
        TileImage(
          size: Size(value.width.toDouble(),value.height.toDouble()),
          name: name,
          path: path,
          offsetHeight: height,
        )
      );
      if(allTileImage == null){
        allTileImage = value;
      }
      else{
        await _combineImage(allTileImage!,value).then((img){
          allTileImage = img;
        });
      }

      if(gridUpdate && gridWidth != null && gridHeight != null){
        if(type == GridType.manual){
          tileSets[tileSets.length-1].manualGrid(gridWidth, gridHeight);
          if(collisions != null){
            tileSets[tileSets.length-1].grid.collisions = collisions;
          }
        }
        else{
          tileSets[tileSets.length-1].autoGrid(allTileImage!).then((value){
            if(collisions != null){
              tileSets[tileSets.length-1].grid.collisions = collisions;
            }
          });
        }
      }
      update();
    });
  }
  Future<Image> _generateImage(TileAtlas tilesAtlas, Image? atlasImage,List<Offset> positions, List<Offset> texCoord, Image? texture,Size size) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0,0,size.width, size.height)
    );

    if(tilesAtlas.rect.isNotEmpty){
      canvas.drawAtlas(
        allTileImage!, 
        tilesAtlas.transform, 
        tilesAtlas.rect, 
        [], 
        BlendMode.srcOver, 
        null, 
        Paint()
      );
    }

    ModelRender(LevelScene()
    ..camera = Camera(
        position: Vector3(-12,2,0),
        viewportHeight: size.height,
        viewportWidth: size.width
      )
    ).generateMap(canvas, size, levelInfo[selectedLevel].objects, allObjectImage);

    return await recorder.endRecording().toImage(size.width.ceil(), size.height.ceil());
  }
  Future<Image> _loadImage(String fileName) async{
    final c = Completer<Image>();
    String basePath = kIsWeb?'assets':path.dirname(fileName);
    if(basePath.contains('assets')){
      await rootBundle.load(fileName).then((data){
        instantiateImageCodec(data.buffer.asUint8List()).then((codec) {
          codec.getNextFrame().then((frameInfo) {
            c.complete(frameInfo.image);
          });
        });
      });
    }
    else if(basePath.contains('http') ||basePath.contains('https')){
      await http.get(Uri.parse(fileName));
    }
    else{
      var dataFuture = File(fileName).readAsBytes();
      dataFuture.then((data) {
        instantiateImageCodec(data).then((codec) {
          codec.getNextFrame().then((frameInfo) {
            c.complete(frameInfo.image);
          });
        });
      }).catchError((error) {
        c.completeError(error);
      });
    }

    return c.future;
  }
  Future<Image> _combineImage(Image init,Image add) async{
    final recorder = PictureRecorder();
    int width = init.width;
    int height = init.height;

    if(add.width > width){
      width = add.width;
    }
    height = init.height+add.height;

    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0,0,width.toDouble(),height.toDouble())
    );

    canvas.drawImage(
      init, 
      const Offset(0,0), 
      Paint()
    );
    canvas.drawImage(
      add, 
      Offset(0,init.height.toDouble()), 
      Paint()
    );

    return await recorder.endRecording().toImage(width, height);
  }
}