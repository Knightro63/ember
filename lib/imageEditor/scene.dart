import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:vector_math/vector_math_64.dart' hide Triangle, Vector4, Colors;
import 'image_editor.dart';
import '../editors/editors.dart';

class Rectangle{
  Rectangle({
    required this.x,
    required this.y,
    required this.height,
    required this.width
  });

  int x;
  int y;
  int height;
  int width;

  Size size(){
    return Size(width.toDouble(),height.toDouble());
  }

  Offset offset(){
    return Offset(x.toDouble(),y.toDouble());
  }
}

class ImageScene {
  ImageScene({
    VoidCallback? onStartUp,
    this.selectableType = SelectedType.image
  }) {
    _onStartUp = onStartUp;
    update();
  }

  List<SpriteImage> sprites = [];
  Offset spriteOffset = const Offset(0,0); //offet of the initial sprite rect
  List<Object> collisions = [];
  Vector3 origionalPos = Vector3(0,0,0);
  String? fileName;
  Camera camera = Camera();

  bool isControlPressed = false;
  VoidCallback? onUpdate;
  VoidCallback? _onStartUp;

  SelectedType selectableType;

  bool isClicked = false;
  bool loaded = false;
  double? currentSize;
  List<SelectedObjects> objectTappedOn = [];
  List<SelectedObjects> prevObjectTappedOn = [];
  Offset? tapLocation;
  bool rayCasting = true;

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

  void render(Canvas canvas, Size size){
    if(sprites.isEmpty) return;
    Vector3 newCameraPosition = Vector3.copy(camera.position);
    newCameraPosition.applyMatrix4(camera.lookAtMatrix);
    Rect totalRect = Rect.fromLTWH(0, 0, camera.viewportWidth, camera.viewportHeight);

    canvas.saveLayer(totalRect, Paint());
    for(int i = 0; i < sprites.length;i++){
      Vector3 newPosition = Vector3.copy(sprites[i].position)..scale(camera.zoom);
      newPosition.applyMatrix4(camera.lookAtMatrix);//..applyMatrix4(Matrix4.identity()..translate((camera.zoom*offsetVal.width)-offsetVal.width,(camera.zoom*offsetVal.height)-offsetVal.height));
      paintImage(
        canvas: canvas, 
        rect: Rect.fromLTWH(newPosition.x, newPosition.y, sprites[i].sprite.width*camera.zoom,sprites[i].sprite.height*camera.zoom), 
        image: sprites[i].sprite,
        fit: BoxFit.fill
      );
      CanvasRects rect = createRect(Size(sprites[i].sprite.width*1.0,sprites[i].sprite.height*1.0),  sprites[i].position, sprites[i].color, i, i,type: SelectedType.image);
      
      final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = rect.color
      ..blendMode = BlendMode.srcOver;
      canvas.drawRect(rect.rect, paint);
    }

    if(collisions.isNotEmpty){
      for(int i = 0; i < collisions.length;i++){
        Vector3 newPosition = Vector3.copy(collisions[i].position)..scale(camera.zoom);
        newPosition.applyMatrix4(camera.lookAtMatrix);//..applyMatrix4(Matrix4.identity()..translate((camera.zoom*offsetVal.width)-offsetVal.width,(camera.zoom*offsetVal.height)-offsetVal.height));
        CanvasRects rect = createRect(collisions[i].size,  collisions[i].position, Colors.green.withAlpha(180), i, i, type: SelectedType.rect);
        
        bool accent = false;
        if(objectTappedOn.isNotEmpty){
          for(int k = 0; k < objectTappedOn.length;k++){
            if(objectTappedOn[k].animation == i){
              accent = true;
              break;
            }
          }
        }
        final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = accent?const Color(0xff0055ff):rect.color
        ..blendMode = BlendMode.srcOver;
        canvas.drawRect(rect.rect, paint);
      }
    }
    canvas.restore();
    Vector3 newPosition = Vector3.zero()..scale(camera.zoom);
    newPosition.applyMatrix4(camera.lookAtMatrix);
    canvas.drawPoints(PointMode.points, [Offset(newPosition.x,newPosition.y)], Paint()..color=Colors.green..strokeWidth=5);
  }
  CanvasRects createRect(Size size, Vector3 position, Color color, int i, int currentRect, {int j = 0, SelectedType type = SelectedType.rect}){
    size *= camera.zoom;
    Vector3 newPosition = Vector3.copy(position)..scale(camera.zoom);
    newPosition.applyMatrix4(camera.lookAtMatrix);

    Rect rect = Rect.fromLTWH(newPosition.x, newPosition.y, size.width, size.height);
    double area = size.width*size.height;
    
    bool isAllowed = false;
    bool isDifferent = true;
    if(objectTappedOn.isNotEmpty && isControlPressed){
      if(objectTappedOn[0].type == SelectedType.image && objectTappedOn[0].type == type){
        isAllowed = true;
      }
      else if(objectTappedOn[0].type == SelectedType.rect && objectTappedOn[0].type == type && objectTappedOn[0].animation == i){
        isAllowed = true;
      }
    }
    else if(objectTappedOn.isEmpty){
      isAllowed = true;
    }

    if(objectTappedOn.isNotEmpty){
      for(int k = 0; k < objectTappedOn.length;k++){
        if(objectTappedOn[k].type == type && objectTappedOn[k].animation == i && objectTappedOn[k].frame == j){
          isDifferent = false;
          color = Colors.green;
          break;
        }
      }
    }
    print(type == selectableType);
    if(tapLocation != null && rect.contains(tapLocation!) && isDifferent && type == selectableType){
      isClicked = true;
      if(currentSize == null){
        currentSize = area;
        objectTappedOn.add(SelectedObjects(type: type,frame: j,animation: i, toColor: currentRect));
      }
      else if(currentSize! > area || isAllowed){
        currentSize = area;
        if(objectTappedOn.length == 1 && !isAllowed){
          objectTappedOn[0] = SelectedObjects(type: type,frame: j,animation: i, toColor: currentRect);
        }
        else if(isAllowed){
          objectTappedOn.add(SelectedObjects(type: type,frame: j,animation: i, toColor: currentRect));
        }
      }
      color = Colors.green;
    }
    
    return CanvasRects(rect: rect, color: color, name: (j+1).toString(), type: type);
  }

  void addCollision(){
    collisions.add(Object());
  }
  void removeSelectedCollision(){
    if(objectTappedOn.isNotEmpty){
      for(int i = 0; i < objectTappedOn.length;i++){
        collisions.removeAt(objectTappedOn[i].animation);
      }
      objectTappedOn = [];
      currentSize = null;
    }
  }
  void removeCollision(List<int> sprite){
    sprite.sort();
    for(int i = sprite.length-1; i >= 0;i--){
      collisions.removeAt(sprite[i]);
      objectTappedOn = [];
      currentSize = null;
    }
  }

  void addSprite(SpriteImage sprite) async{
    spriteOffset = Offset(sprite.section.left,sprite.section.top);
    await _getImage(sprite.sprite,sprite.section).then((value){
      sprite.sprite = value;
      sprites.add(sprite);
      update();
    });
  }
  void removeSprite(List<int> sprite) {
    sprite.sort();
    for(int i = sprite.length-1; i >= 0;i--){
      sprites.removeAt(sprite[i]);
      objectTappedOn = [];
      currentSize = null;
    }
  }

  void update() {
    if (onUpdate != null) onUpdate!();
    if(!loaded && _onStartUp != null){
      _onStartUp!();
    }
  }
  void clear(){
    sprites = [];
    isClicked = false;
    objectTappedOn = [];
    prevObjectTappedOn = [];
  }
  // Mark needs update texture
  void updateTapLocation(Offset details) {
    print(details);
    if(!isControlPressed){
      objectTappedOn = [];
      currentSize = null;
      isClicked = false;
    }
    tapLocation = details;
    update();
  }
  void combineSprites(List<int> combine){
    int? x1;
    int? y1;
    int? x2;
    int? y2;
    combine.sort();
    Vector3 newPos = sprites[combine[0]].position;
    double cameraX = camera.position.x;
    double cameraY = camera.position.y;

    for(int i = 0; i < combine.length; i++){
      int widthS = sprites[combine[i]].sprite.width;
      int heightS = sprites[combine[i]].sprite.height;

      int positionX = (sprites[combine[i]].position.x*100-(cameraX*100)).round();
      int positionY = (sprites[combine[i]].position.y*-100+(cameraY*100)).round();

      if(x1 == null || x1 > positionX){
        x1 = positionX;
        newPos.x = sprites[combine[i]].position.x;
      }
      if(y1 == null || y1 > positionY){
        y1 = positionY;
        newPos.y = sprites[combine[i]].position.y;
      }

      if(x2 == null || widthS+positionX > x2){
        x2 = widthS+positionX;
      }
      if(y2 == null || heightS+positionY > y2){
        y2 = heightS+positionY;
      }
    }
    Offset offset = Offset(-x1!*1.0,-y1!*1.0);
    _generateImage(Size((x2!-x1)*1.0,(y2!-y1)*1.0), combine, offset).then((value){
      sprites.add(
        SpriteImage(
          sprite: value,
          name: sprites[combine[0]].name,
          position: newPos
        )
      );
      for(int i = combine.length-1; i >= 0; i--){
        sprites.removeAt(combine[i]);
      }
    });
    updateTapLocation(const Offset(0,0));
  }
  void updateSprites(String path, String name) {
    if(sprites.isEmpty  && !kIsWeb){
      fileName = name;
    }
    else{
      fileName = 'untitled';
    }
      
    _loadImage(path).then((value){
      sprites.add(
        SpriteImage(
          sprite: value,
          name: name
        )
      );
      update();
    });
  }
  List<Rect> getspriteLocations(){
    List<Rect> rect = [];
    for(int i = 0; i < sprites.length; i++){
      rect.add(
        sprites[i].section
      );
    }
    return rect;
  }
  List<Rect> getCollisionLocations(){
    List<Rect> rect = [];
    for(int i = 0; i < collisions.length; i++){
      Vector3 newPosition = camera.relativeLocation(collisions[i].position, const Offset(8,8));
      rect.add(
        Rect.fromLTWH(
          newPosition.x, 
          newPosition.y, 
          collisions[i].size.width.toDouble(), 
          collisions[i].size.height.toDouble()
        )
      );
    }
    return rect;
  }
  void setCollisions(List<Rect> rect){
    for(int i = 0; i < rect.length; i++){
      Size size = Size(rect[i].width,rect[i].height);
      Vector3 pos = Converter.toVector3(camera.position, Offset(rect[i].left,rect[i].top));
      collisions.add(
        Object(
          position: pos,
          size: size
        )
      );
    }
  }
  void seperateSprites() async{
    if(objectTappedOn.length == 1){
      int loc = objectTappedOn[0].animation;
      origionalPos = sprites[loc].position;
      Image img = sprites[loc].sprite;
      ByteData? byteData = await img.toByteData();
      Uint8List pixels = byteData!.buffer.asUint8List();
      //Color bgColor = _getBackGroundColor(pixels);
      List<Rectangle> startingRect = [];

      bool start = false;
      int iStart = 0;
      
      for(int i = 0; i < img.height;i++){
        bool allZeros = true;
        for (int j = 0; j < img.width;j++){
          Color color = Color.fromARGB(pixels[j*4+i*img.width*4], pixels[(j*4+i*img.width*4)+1], pixels[(j*4+i*img.width*4)+2], pixels[(j*4+i*img.width*4)+3]);
          if(color != const Color.fromARGB(0,0,0,0)){
            allZeros = false;
            if(!start){
              start = true;
              iStart = i;
            }
            break;
          }
        }

        if((allZeros && start) || (i == img.height-1 && start)){
          start = false;
          startingRect.add(Rectangle(x: 0,y: iStart,height: (i-iStart),width: img.width));
        }
      }

      start = false;

      for(int k = 0; k < startingRect.length; k++){
        int height = startingRect[k].height;
        int width = startingRect[k].width;
        int x = 0;

        for(int i = 0; i < width;i++){
          bool allZeros = true;
          
          for (int j = startingRect[k].y; j < startingRect[k].y+height; j++){
            Color color = Color.fromARGB(pixels[j*width*4+i*4], pixels[(j*width*4+i*4)+1], pixels[(j*width*4+i*4)+2], pixels[(j*width*4+i*4)+3]);
            
            if(color != const Color.fromARGB(0,0,0,0)){
              allZeros = false;
              if(!start){
                start = true;
                x = i;
              }
              break;
            }
          }

          if((allZeros && start) || (i == width-1 && start)){
            start = false;
            Rect rects = Rect.fromLTWH(x.toDouble(), startingRect[k].y.toDouble(), i-x.toDouble(),height.toDouble());
            x = i;
            Offset off = Converter.toOffset(camera.position, sprites[loc].position);
            Offset offset = Offset(rects.left,rects.top)+off;

            await _generateImage(Size(rects.width,rects.height), [loc], -offset).then((value){
              Vector3 newPosition = Converter.toVector3(camera.position, offset);
              sprites.add(
                SpriteImage(
                  sprite: value,
                  name: i.toString(),
                  position: newPosition,
                  section: rects
                )
              );
            });
          }
        }
      }

      removeSprite([loc]);
      updateTapLocation(const Offset(0,0));
    }
    update();
  }

  Future<Image> _getImage(Image init,Rect area) async{
    final recorder = PictureRecorder();

    final canvas = Canvas(
      recorder,
      area
    );

    canvas.drawImage(
      init, 
      Offset(area.left,area.top), 
      Paint()
    );

    return await recorder.endRecording().toImage(area.width.toInt(), area.height.toInt());
  }
  Future<Image> _loadImage(String fileName) {
    final c = Completer<Image>();
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
    return c.future;
  }
  Future<Image> _generateImage(Size size, List<int> spriteLocations,[Offset direction = const Offset(0,0), Offset offset = const Offset(0,0)]) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(offset.dx,offset.dy,size.width, size.height)
    );

    Vector3 newCameraPosition = Vector3.copy(camera.position);
    newCameraPosition.applyMatrix4(camera.lookAtMatrix);
    if(sprites.isNotEmpty){
      for(int i = 0; i < spriteLocations.length;i++){
        double cameraX = camera.position.x;
        double cameraY = camera.position.y;

        canvas.drawImage(sprites[spriteLocations[i]].sprite, Offset((sprites[spriteLocations[i]].position.x*100-(cameraX*100))+direction.dx, (sprites[spriteLocations[i]].position.y*-100+(cameraY*100))+direction.dy), Paint());
      }
    }

    return await recorder.endRecording().toImage(size.width.floor(), size.height.floor());
  }
}

