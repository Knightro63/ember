import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart' hide Image, Material;
import 'package:vector_math/vector_math_64.dart' hide Triangle hide Colors;
import '../editors/editors.dart';
import 'level_editor.dart';

enum ObjectType{landscape,charcter,item}
enum LoadedType{sheet,single}
enum GridType{manual,auto}

class TileRects{
  TileRects({
    this.tileSet = 0,
    this.rect = const Rect.fromLTWH(0, 0, 0, 0),
    RSTransform? transform,
    List<int>? position,
    this.isAnimation = false,
    this.useAnimation = 0
  }){
    this.position = position??[];
    this.transform = transform ??RSTransform.fromComponents(rotation: 0, scale: 0, anchorX: 0, anchorY: 0, translateX: 0, translateY: 0);
  }

  late List<int> position;
  int tileSet;
  Rect rect;
  late RSTransform transform;
  bool isAnimation;
  int useAnimation;
}
class TileLayers{
  TileLayers({
    this.visible = true,
    List<TileRects>? tiles,
    required this.length,
    this.name = 'Layer'
  }){
    this.tiles = tiles ?? List<TileRects>.filled(length, TileRects(),growable: true);
  }

  bool visible;
  String name;
  int length;
  late List<TileRects> tiles;
}
class TileAnimations{
  TileAnimations({
    this.tileSet = 0,
    required this.rects,
    this.timing = 0.4,
    this.useFrame = 0
  });

  double timing;
  int tileSet;
  List<Rect> rects;
  int useFrame;
}
class TileAtlas{
  TileAtlas({
    this.location = 0,
    this.isTileSet = true,
    List<Rect>? rect,
    List<RSTransform>? transform,
  }){
    this.rect = rect ?? [];
    this.transform = transform ?? [];
  }

  int location;
  bool isTileSet;
  late List<Rect> rect;
  late List<RSTransform> transform;
}
class Levels{
  Levels({
    this.name = '',
    List<TileLayers>? tileLayer,
    List<TileAnimations>? animations,
    List<Object>? objects,
    Grid? grid,
    this.selectedTileLayer = 0,
    Size? maxGridSize
  }){
    this.grid = grid ?? Grid();
    this.maxGridSize = maxGridSize ?? Size(this.grid.width.toDouble(),this.grid.height.toDouble());
    this.tileLayer = tileLayer??[TileLayers(length: currentGridLength)];
    this.animations = animations??[];
    this.objects = objects??[];
  }

  String name;
  int selectedTileLayer;
  late List<TileLayers> tileLayer;
  late List<TileAnimations> animations;
  late List<Object> objects;
  late Grid grid;

  late Size maxGridSize;
  int get currentGridLength => grid.width*grid.height;
  bool get hasImageData => _hasImageData();
  bool _hasImageData(){
    bool hasImage = false;
    for(int i = 0; i < tileLayer[selectedTileLayer].tiles.length;i++){
      if(tileLayer[selectedTileLayer].tiles[i].rect != const Rect.fromLTWH(0, 0, 0, 0)){
        hasImage = true;
        break;
      }
    }
    if(objects.isNotEmpty){
      hasImage = true;
    }
    return hasImage;
  }
  
  void hideTiles(){
    for(int i = 0; i < tileLayer.length;i++){
      tileLayer[i].visible = false;
    }
  }
  void showTiles(){
    for(int i = 0; i < tileLayer.length;i++){
      tileLayer[i].visible = true;
    }
  }
  void hideCollisions(){
    for(int i = 0; i < objects.length;i++){
      if(objects[i].type == SelectedType.collision){
        objects[i].visible = false;
      }
    }
  }
  void showCollisions(){
    for(int i = 0; i < objects.length;i++){
      if(objects[i].type == SelectedType.collision){
        objects[i].visible = true;
      }
    }
  }
  void hideObjects(){
    for(int i = 0; i < objects.length;i++){
      if(objects[i].type == SelectedType.object){
        objects[i].visible = false;
      }
    }
  }
  void showObjects(){
    for(int i = 0; i < objects.length;i++){
      if(objects[i].type == SelectedType.object){
        objects[i].visible = true;
      }
    }
  }
  void hideAtlas(){
    for(int i = 0; i < objects.length;i++){
      if(objects[i].type == SelectedType.atlas){
        objects[i].visible = false;
      }
    }
  }
  void showAtlas(){
    for(int i = 0; i < objects.length;i++){
      if(objects[i].type == SelectedType.atlas){
        objects[i].visible = true;
      }
    }
  }
  void addLayer(){
    tileLayer.add(TileLayers(length: currentGridLength));
  }
  void removeLayer(int layer){
    if(layer == selectedTileLayer){
      selectedTileLayer = 0;
    }
    if(tileLayer.length == 1){
      tileLayer[0] = TileLayers(length: currentGridLength);
    }
    else{
      tileLayer.removeAt(layer);
    }
  }
  void moveLayer(int from, int to){
    if(to >= 0 && to < tileLayer.length){
      TileLayers temp = tileLayer[from];
      tileLayer.removeAt(from);
      tileLayer.insert(to, temp);
      //selectedTileLayer += to-from;
    }
  }
  void updateTiles(int length){
    int i = selectedTileLayer;
    if(maxGridSize.width < grid.width){
      List<TileRects> newTiles = List<TileRects>.filled(length, TileRects(),growable: true);
      //for(int i = 0; i < tileLayer.length; i++){
        for(int j = 0; j < tileLayer[i].tiles.length; j++){
          if(tileLayer[i].tiles[j].position.isNotEmpty){
            int x = tileLayer[i].tiles[j].position[0];
            int y = tileLayer[i].tiles[j].position[1]*grid.width;
            newTiles[x+y] = tileLayer[i].tiles[j];
          }
        }
        tileLayer[i].tiles = newTiles;
      //}  
    }
    else{
      //for(int i = 0; i < tileLayer.length;i++){
        if(tileLayer[i].tiles.length < length){
          for(int j = tileLayer[i].tiles.length; j < length; j++){
            tileLayer[i].tiles.add(TileRects());
          }
        }
      //}
    }

    maxGridSize = Size(
      maxGridSize.width < grid.width?grid.width.toDouble():maxGridSize.width,
      maxGridSize.height < grid.height?grid.height.toDouble():maxGridSize.height
    );
  }
}
class TileImage{
  TileImage({
    Vector3? position,
    required this.size,
    this.name = '',
    this.path = '',
    this.color = const Color(0xffff0000),
    TileGrid? grid,
    required this.offsetHeight,
  }){
    this.position = position ??Vector3(0.0, 0.0, 0.0);
    this.grid = grid ??TileGrid();
  }

  int offsetHeight;
  Size size;
  String name;
  String path;
  late Vector3 position;
  Vector2 from = Vector2(0,0);
  Color color;
  late TileGrid grid;
  double _zoom = 1.0;
  double zoom(double view){
    _zoom = 1.0-(size.width-view)/size.width;
    return _zoom;
  }
  double height(){
    return size.height*_zoom;
  }
  
  void manualGrid(int gridWidth, int gridHeight) {
    Size sizeG = Size(size.width/gridWidth,size.height/gridHeight);
    List<Rect> rects = [];
    List<Vector3> positions = [];
    int j = 0;
    int k = 0;

    for(int i = 0; i < gridWidth*gridHeight; i++){
      if(i != 0 && i%gridWidth != 0){
        j++;
      }
      else if(i != 0 && i%gridWidth == 0){
        k++;
        j = 0;
      }

      rects.add(Rect.fromLTWH(j*sizeG.width, k*sizeG.height, sizeG.width, sizeG.height));

      Vector3 newPosition = 
      position+
      Converter.toVector3(Vector3(0,0,0), Offset(rects[i].left,rects[i].top));
      positions.add(newPosition);
    }

    grid = TileGrid(
      position: positions,
      rects: rects,
      type: GridType.manual,
      width: gridWidth,
      height: gridHeight
    );
    //updateTapLocation(Offset(0,0));
  }
  Future<void> autoGrid(Image image) async{
    //Image img = image;
    final Image img = await getImage(image);
    final ByteData? byteData = await img.toByteData();
    final Uint8List pixels = byteData!.buffer.asUint8List();
    List<Rect> startingRect = [];
    TileGrid? newGrids;

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
        startingRect.add(Rect.fromLTWH(0,iStart.toDouble(),img.width.toDouble(),(i-iStart).toDouble()));
      }
    }

    start = false;

    for(int k = 0; k < startingRect.length; k++){
      int height = startingRect[k].height.toInt();
      int width = startingRect[k].width.toInt();
      int x = 0;

      for(int i = 0; i < width;i++){
        bool allZeros = true;
        
        for (int j = startingRect[k].top.toInt();j < startingRect[k].top+height; j++){
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
          Rect rects = Rect.fromLTWH(x.toDouble(), startingRect[k].top,(i-x).toDouble(),height.toDouble());
          x = i;

          Vector3 newPosition = position+
          Converter.toVector3(Vector3(0,0,0), Offset(rects.left.toDouble(),rects.top.toDouble()));
          
          if(newGrids == null){
            newGrids = TileGrid(
              rects: [rects],
              position: [newPosition],
              type: GridType.auto
            );
          }
          else{
            newGrids.rects.add(rects);
            newGrids.position.add(
              newPosition
            );
          }
        }
      }
    }
    grid = newGrids!;
    grid.generateCollisions(newGrids.rects.length);
  }
  Future<Image> getImage(Image init) async{
    final recorder = PictureRecorder();

    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, -offsetHeight.toDouble(), size.width, size.height)
    );

    canvas.drawImage(
      init, 
      Offset(0,-offsetHeight.toDouble()), 
      Paint()
    );

    return await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
  }
  void updatePositionStart(Vector2 to){
    from.x = to.x;
    from.y = to.y;
  }
  void updatePosition(Vector2 to, [double sensitivity=1.0]){
    final double x = ((to.x - from.x))/100*sensitivity;
    final double y = ((to.y - from.y))/100*sensitivity;

    position.x += x;
    position.y -= y;

    from.x = to.x;
    from.y = to.y;
  }
  void move(int x, int y,[double sensitivity=1.0]){
    position.x += x/100*sensitivity;
    position.y -= y/100*sensitivity;
  }
}
class SelectedObjects{
  SelectedObjects({
    required this.objectLocation,
    required this.toColor
  });

  int objectLocation;
  int toColor;
}
class TileGrid{
  TileGrid({
    this.position = const [],
    List<Rect> rects = const [],
    List<List<Rect>>? collisions,
    this.type = GridType.manual,
    this.height = 0,
    this.width = 0
  }){
    _rects = rects;
    this.collisions = collisions ?? List.filled(rects.length, []);
  }

  int height;
  int width;
  GridType type;
  List<Vector3> position;
  late List<List<Rect>> collisions;
  late List<Rect> _rects;
  List<Rect> get rects => _rects;
  set rects(List<Rect> newRects){
    _rects = newRects;
    collisions = List.filled(rects.length, []);
  }

  void generateCollisions(int length){
    collisions = List.filled(length, []);
  }
}
class SelectedTile{
  SelectedTile({
    this.tileSet,
    this.rect,
    this.isAnimation = false,
    this.animationLocation = 0,
    this.gridLocation = 0
  });

  int? tileSet;
  Rect? rect;
  int animationLocation;
  bool isAnimation;
  int gridLocation;
}
class LoadedObject{
  LoadedObject({
    required this.size,
    required this.offsetHeight,
    required this.type,
    List<double>? objectScale,
    this.objectType = ObjectType.landscape,
    this.path = '',
    this.name = '',
    List<Rect>? spriteLocations,
     this.spriteNames,
    this.show = true,
    this.startingLayer = 1,
    this.object
  }){
    _spriteLocations = spriteLocations ?? [];
    this.objectScale = objectScale ?? (spriteLocations == null?[]:List<double>.filled(spriteLocations.length, 1.0));
  }

  Size size;
  String path;
  LoadedType type;
  ObjectType objectType;
  late List<Rect> _spriteLocations;
  set spriteLocations(List<Rect> locations){
    _spriteLocations = locations;
    objectScale = List<double>.filled(spriteLocations.length, 1.0);
  }
  List<Rect> get spriteLocations => _spriteLocations;
  List<String>? spriteNames;
  bool show;
  int startingLayer;
  int offsetHeight;
  late List<double> objectScale;
  String name;
  Object? object;
}
class Object {
  Object({
    List<Mesh>? mesh,
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
    Size? size,
    this.name = 'Object',
    this.visible = true,
    this.imageLocation = 0,
    this.type = SelectedType.image,
    this.color = Colors.red,
    this.layer = 1,
    this.scaleAllowed = true,
  }){
    if (position != null) position.copyInto(this.position);
    if (rotation != null) rotation.copyInto(this.rotation);
    if (scale != null) scale.copyInto(this.scale);
    updateTransform();
    this.size = size ?? const Size(50,50);
    if(type == SelectedType.collision){layer = 4;}
    else if(type == SelectedType.rect){layer = 2;}
    this.mesh = mesh??[Mesh(
      vertices: [
        Vector3(0,0,0),
        Vector3(this.size.width,0,0),
        Vector3(this.size.width,this.size.height,0),
        Vector3(0,this.size.height,0)
      ],
      indices: [Triangle([0,1,2], null, null),Triangle([2,3,0], null, null)],
      colors: [color,color]
    )];
  }

  late final Vector3 position = Vector3(0.0, 0.0, 0.0);
  late final Vector3 rotation = Vector3(0.0, 180.0, 0.0);
  late final Vector3 scale = Vector3(0.01, 0.01, 0.01);
  final Matrix4 transform = Matrix4.identity();

  bool visible;
  String name;
  Vector3 _tempPosition = Vector3.zero();
  late Size size;
  Vector2 from = Vector2(0,0);
  late List<Mesh> mesh;
  int imageLocation;
  SelectedType type;
  Color color;
  int layer;
  bool scaleAllowed;

  void changeColor(Color newColor){
    for(int i = 0; i < mesh.length;i++){
      for(int j = 0; j < mesh[i].colors.length;j++){
        mesh[i].colors[j] = newColor;
      }
    }
    color = newColor;
  }
  void updateTransform() {
    Quaternion q = Quaternion.euler(radians(rotation.x), radians(rotation.y),radians(rotation.z));
    final Matrix4 m = Matrix4.compose(position, q, scale);   
    transform.setFrom(m);
    //transform.rotateX(pi/2);
  }
  void updatePositionStart(Vector2 to){
    from.x = to.x;
    from.y = to.y;
  }
  void updatePosition(Vector2 to, [double sensitivity=1.0]){
    final double x = ((to.x - from.x))/100*sensitivity;
    final double y = ((to.y - from.y))/100*sensitivity;

    position.x += x;
    position.y -= y;

    from.x = to.x;
    from.y = to.y;

    updateTransform();
  }
  void move(int x, int y){
    position.x = _tempPosition.x+x/100;
    position.y = _tempPosition.y-y/100;
  }
  void savePosition(){
    _tempPosition = position;
  }
  void resetPosition(){
    position.copyInto(_tempPosition);
  }
  void flipHorizontal(){
    scale.y = -scale.y;
    updateTransform();
  }
  void filpVertical(){
    scale.x = -scale.x;
    updateTransform();
  }
  void scaleObject(int x, int y){
    //size = Size(size.width+x,size.height+y);
    scale.x += x;
    scale.y += y;
    updateTransform();
  }
  void scaleMouse(Vector2 to, [double sensitivity=1.0]){
    if(!scaleAllowed) return; 
    final double x = ((to.x - from.x))/10000*sensitivity;
    final double y = ((to.y - from.y))/10000*sensitivity;
    //size = Size(size.width+x,size.height+y);
    scale.x += x;
    scale.y += y;
    from.x = to.x;
    from.y = to.y;
    updateTransform();
  }
  void rotateMouse(Vector2 to, [double sensitivity=1.0]){
    final double x = ((to.x - from.x))*sensitivity;
    final double y = ((to.y - from.y))*sensitivity;

    rotation.z += x-y;

    from.x = to.x;
    from.y = to.y;

    updateTransform();
  }
}

Object createObject({
  required SelectedType type, 
  Vector3? position, 
  Vector3? rotation,
  Vector3? scale,
  required Size size, 
  required String name, 
  required int layer,
  required int imageLocation, 
  Color? color, 
  List<Offset>? textcoords,
  Rect? textureRect,
}){
  color ??= Colors.red;
  return (type != SelectedType.atlas && type != SelectedType.image )?Object(
    position: position,
    rotation: rotation,
    scale: scale,
    mesh: [Mesh(
      vertices: [
        Vector3(0,0,0),
        Vector3(size.width,0,0),
        Vector3(size.width,size.height,0),
        Vector3(0,size.height,0),
      ],
      hasTexture: textcoords == null?false:true,
      texcoords: textcoords,
      indices: [
        Triangle([0,1,2], null, textcoords != null?[0,1,2]:null),
        Triangle([2,3,0], null, textcoords != null?[2,3,0]:null),
      ],
      textureRect: textureRect
    )],
    size: size,
    name: name,
    layer: layer,
    imageLocation: imageLocation,
    type: type,
    color: color
  ):Object(
    position: position,
    rotation: rotation,
    scale: scale,
    mesh: [Mesh(
      vertices: [
        Vector3(0,0,0),
        Vector3(size.width,0,0),
        Vector3(size.width,size.height,0),
        Vector3(0,size.height,0),
      ],
      hasTexture: textcoords == null?false:true,
      texcoords: textcoords,
      indices: [
        Triangle([0,1,2], null, textcoords != null?[0,1,2]:null),
        Triangle([2,3,0], null, textcoords != null?[2,3,0]:null),
      ],
      textureRect: textureRect
    )],
    size: size,
    name: name,
    layer: layer,
    imageLocation: imageLocation,
    type: type,
    color: color
  );
}