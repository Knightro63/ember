import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';
import 'level_editor.dart';
import '../editors/other.dart';

class LevelExporter{
  static Future<String> export(LevelScene scene,[ExportType exportType = ExportType.ember]) async{
    if(exportType == ExportType.json){
      return _exportJSON(scene);
    }
    else{
      return _exportEmber(scene);
    }
  }
  static dynamic _getCollisions(TileImage tileSet){
    Map<String,dynamic> allCol = {};
    if(tileSet.grid.collisions.isNotEmpty){
      for(int i = 0; i < tileSet.grid.collisions.length;i++){
        Map<String,dynamic> col = {};
        for(int j = 0; j < tileSet.grid.collisions[i].length;j++){
          col['collision_$j'] = {
            'x': tileSet.grid.collisions[i][j].left,
            'y': tileSet.grid.collisions[i][j].top,
            'width': tileSet.grid.collisions[i][j].width,
            'height': tileSet.grid.collisions[i][j].height
          };
        }
        if(col.isNotEmpty){
          allCol['tile_$i'] = col;
        }
      }
    }
    return allCol;
  }
  static dynamic _getTileSets(LevelScene scene){
    dynamic tileSets = {};
    for(int i = 0; i < scene.tileSets.length;i++){
      tileSets['set_$i'] = {
        'image': scene.tileSets[i].path,
        'name' : scene.tileSets[i].name,
        'grid' : {
          'type': scene.tileSets[i].grid.type.index,
          'width': scene.tileSets[i].grid.width,
          'height': scene.tileSets[i].grid.height,
          'length': scene.tileSets[i].grid.rects.length,
          'collisions': _getCollisions(scene.tileSets[i])
        },
        'size': {
          'w': scene.tileSets[i].size.width,
          'h': scene.tileSets[i].size.height
        },
        'position': {
          'x':scene.tileSets[i].position.x,
          'y':scene.tileSets[i].position.y
        }
      };
    }

    return tileSets;
  }
  static dynamic _getObjectSheets(LevelScene scene){
    dynamic loadedObjects = {};
    for(int i = 0; i < scene.loadedObjects.length;i++){
      dynamic spriteLocations = {};
      if(scene.loadedObjects[i].spriteLocations.isNotEmpty){
        for(int j = 0; j < scene.loadedObjects[i].spriteLocations.length;j++){
          spriteLocations['location_$j'] = {
            'w': scene.loadedObjects[i].spriteLocations[j].width,
            'h': scene.loadedObjects[i].spriteLocations[j].height,
            'x': scene.loadedObjects[i].spriteLocations[j].left,
            'y': scene.loadedObjects[i].spriteLocations[j].top,
          };
        }
      }
      loadedObjects['sheet_$i'] = {
        'objectType': scene.loadedObjects[i].objectType.index,
        'spriteNames': scene.loadedObjects[i].spriteNames,
        'objectScale': scene.loadedObjects[i].objectScale,
        'image': scene.loadedObjects[i].path,
        'loadedType': scene.loadedObjects[i].type.index,
        'visible': scene.loadedObjects[i].show,
        'offsetHeight': scene.loadedObjects[i].offsetHeight,
        'size': {
          'w': scene.loadedObjects[i].size.width,
          'h': scene.loadedObjects[i].size.height
        },
        'spriteLocations': spriteLocations
      };
    }

    return loadedObjects;
  }
  static dynamic _getObjects(List<Object> objects){
    dynamic object = {};
    dynamic getAtlas(int i){
      if(objects[i].type != SelectedType.atlas){ return null;}
      else{
        double off = objects[i].mesh.first.texcoords!.last.dy-objects[i].mesh.first.texcoords!.first.dy;
        return {
          'x': objects[i].mesh.first.texcoords!.first.dx,
          'y': objects[i].mesh.first.texcoords!.first.dy,
          'w': objects[i].mesh.first.texcoords![1].dx-objects[i].mesh.first.texcoords![0].dx,
          'h': off
        };
      }
    }
    for(int i = 0; i < objects.length;i++){
      object['object_$i'] ={
          'visible': objects[i].visible,
          'scaleAllowed': objects[i].scaleAllowed,
          'name': objects[i].name,
          'image': objects[i].imageLocation,
          'type': objects[i].type.index,
          'color': objects[i].color.value,
          'layer': objects[i].layer,
          'size': {
            'w': objects[i].size.width,
            'h': objects[i].size.height
          },
          'position':{
            'x': objects[i].position.x,
            'y': objects[i].position.y,
            'z': objects[i].position.z,
          },
          'rotation':{
            'x': objects[i].rotation.x,
            'y': objects[i].rotation.y,
            'z': objects[i].rotation.z,
          },
          'scale':{
            'x': objects[i].scale.x,
            'y': objects[i].scale.y,
            'z': objects[i].scale.z,
          },
          'atlas':getAtlas(i),
        };
    }

    return object;
  }
  static dynamic _getTiles(List<TileRects> tiles){
    dynamic tile;
    Rect temp = const Rect.fromLTWH(0, 0, 0, 0);
    for(int i = 0; i < tiles.length; i++){
      if(tile == null && tiles[i].rect != temp){
        tile = {
          'tile_$i': {
            'location': i,
            'set': tiles[i].tileSet,
            'isAnimation': tiles[i].isAnimation,
            'useAnimation': tiles[i].useAnimation,
            'rect': {
              'x': tiles[i].rect.left,
              'y': tiles[i].rect.top,
              'w': tiles[i].rect.width,
              'h': tiles[i].rect.height
            },
            'position': tiles[i].position,
            'transform':{
              'tx': tiles[i].transform.tx,
              'ty': tiles[i].transform.ty,
              'scos': tiles[i].transform.scos,
              'ssin': tiles[i].transform.ssin
            }
          }
        };
      }
      else if(tile != null && tiles[i].rect != temp){
        tile['tile_$i'] = {
          'location': i,
          'set': tiles[i].tileSet,
          'isAnimation': tiles[i].isAnimation,
          'useAnimation': tiles[i].useAnimation,
          'rect': {
            'x': tiles[i].rect.left,
            'y': tiles[i].rect.top,
            'w': tiles[i].rect.width,
            'h': tiles[i].rect.height
          },
          'position': tiles[i].position,
          'transform':{
            'tx': tiles[i].transform.tx,
            'ty': tiles[i].transform.ty,
            'scos': tiles[i].transform.scos,
            'ssin': tiles[i].transform.ssin
          }
        };
      }
    }

    return tile;
  }
  static dynamic _getTileLayer(List<TileLayers> layers){
    dynamic layer;
    for(int i = 0; i < layers.length; i++){
      if(layer == null){
        layer = {
          'layer_$i': {
            'name': layers[i].name,
            'tiles': _getTiles(layers[i].tiles),
            'length': layers[i].length,
          }
        };
      }
      else{
        layer['layer_$i'] = {
          'name': layers[i].name,
          'tiles': _getTiles(layers[i].tiles),
          'length': layers[i].length,
        };
      }
    }

    return layer;
  }
  static dynamic _getRects(List<Rect> rects){
    dynamic rect;
    for(int i = 0; i < rects.length; i++){
      if(rect == null){
        rect = {
          'rect_$i': {
            'x': rects[i].left,
            'y': rects[i].top,
            'w': rects[i].width,
            'h': rects[i].height
          }
        };
      }
      else{
        rect['rect_$i'] = {
          'x': rects[i].left,
          'y': rects[i].top,
          'w': rects[i].width,
          'h': rects[i].height
        };
      }
    }

    return rect;
  }
  static dynamic _getAnimations(List<TileAnimations> animations){
    dynamic animation;
    for(int i = 0; i < animations.length; i++){
      if(animation == null){
        animation = {
          'animation_$i': {
            'set': animations[i].tileSet,
            'timing': animations[i].timing,
            'rects': _getRects(animations[i].rects),
          }
        };
      }
      else{
        animation['animation_$i'] = {
          'set': animations[i].tileSet,
          'timing': animations[i].timing,
          'rects': _getRects(animations[i].rects),
        };
      }
    }

    return animation;
  }

  static Future<String> _exportEmber(LevelScene scene) async{
    // List<Levels> levelInfo = [];
    dynamic tileSets = _getTileSets(scene);
    dynamic loadedObjects = _getObjectSheets(scene);
    dynamic levels = {};
    final length = scene.levelInfo.length;
    for(int i = 0; i < length;i++){
      levels['level_$i'] = {
        'name': scene.levelInfo[i].name,
        'tileLayer': _getTileLayer(scene.levelInfo[i].tileLayer),
        'animations': _getAnimations(scene.levelInfo[i].animations),
        'objects': _getObjects(scene.levelInfo[i].objects),
        'maxGridWidth': scene.levelInfo[i].maxGridSize.width,
        'maxGridHeight': scene.levelInfo[i].maxGridSize.height,
        'grid': {
          'color': scene.levelInfo[i].grid.color.value,
          'x': scene.levelInfo[i].grid.width,
          'y': scene.levelInfo[i].grid.height,
          'width': scene.levelInfo[i].grid.boxSize.width,
          'height': scene.levelInfo[i].grid.boxSize.height,
          'stroke': scene.levelInfo[i].grid.lineWidth
        }
      };
    }
    dynamic data = {
      'tileSets': tileSets,
      'loadedObjects': loadedObjects,
      'levels': levels,
      'meta': {
        "app": "Ember Level Editor",
        "version": "0.0.1",
        "name": scene.fileName,
        "format": "RGBA8888",
      },
    };

    return json.encode(data);
  }

  static Future<String> _exportJSON(LevelScene scene) async{
    int i = scene.selectedLevel;
    dynamic tileSets = _getTileSets(scene);
    dynamic loadedObjects = _getObjectSheets(scene);
    dynamic level;

    level = {
      'name': scene.levelInfo[i].name,
      'tileLayer': _getTileLayer(scene.levelInfo[i].tileLayer),
      'animations': _getAnimations(scene.levelInfo[i].animations),
      'objects': _getObjects(scene.levelInfo[i].objects),
      'grid': {
        'x': scene.levelInfo[i].grid.width,
        'y': scene.levelInfo[i].grid.height,
        'width': scene.levelInfo[i].grid.boxSize.width,
        'height': scene.levelInfo[i].grid.boxSize.height,
      }
    };
    dynamic data = {
      'tileSets': tileSets,
      'loadedObjects': loadedObjects,
      'level': level,
      'meta': {
        "app": "Ember Level Editor",
        "version": "0.0.1",
        "name": scene.fileName,
        "format": "RGBA8888",
      },
    };

    return json.encode(data);
  }

  static Future<Uint8List?> exportPNG(String filePath, LevelScene scene) async{
    if(scene.levelImage != null){
      final val = await scene.levelImage!.toByteData(format: ImageByteFormat.png);
      return val!.buffer.asUint8List();
    }
    return null;
  }
}