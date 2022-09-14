import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';

import 'levelEditor.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../editors/other.dart';
import 'package:vector_math/vector_math_64.dart' hide Triangle;

class JLELoader{
  static Grid _getGrid(dynamic gird){
    return Grid(
      height: gird['y'],
      width: gird['x'],
      color: Color(gird['color']),
      lineWidth: gird['stroke']
    );
  }
  static Vector3? jsonToVector3(Map<String,dynamic>? data){
    if(data == null || data['x'] == null || data['y'] == null) return null;
    return Vector3(
      data['x'],
      data['y'],
      data['z']??0
    );
  }
  static List<Object> _getObjects(dynamic objectList, LevelScene scene){
    List<Object> objects = [];
    
    if(objectList != null){
      for(String object in objectList.keys){
        Rect? atlas;
        List<Offset>? textcoords;
        int imageLocation = objectList[object]['image'];
        Vector3? rotation = jsonToVector3(objectList[object]['rotation']);
        Size size = Size(objectList[object]['size']['w'],objectList[object]['size']['h']);
        Vector3? scale = jsonToVector3(objectList[object]['scale']);
        Vector3? position = jsonToVector3(objectList[object]['position']);
        int type = objectList[object]['type'];
        if(objectList[object]['atlas'] != null){
          atlas = Rect.fromLTWH(
            objectList[object]['atlas']['x'], 
            objectList[object]['atlas']['y'], 
            objectList[object]['atlas']['w'], 
            objectList[object]['atlas']['h']
          );
          //double off = scene.loadedObjects[imageLocation].offsetHeight.toDouble();
          textcoords = [            
            Offset(atlas.left,atlas.top),
            Offset(atlas.right,atlas.top),
            Offset(atlas.right,atlas.bottom),
            Offset(atlas.left,atlas.bottom)
          ];
        }
        else if(SelectedType.values[type] == SelectedType.image){
          LoadedObject lo =  scene.loadedObjects[imageLocation];
          double off = lo.offsetHeight.toDouble();
          atlas = Rect.fromLTWH(
            0, 
            0, 
            lo.size.width, 
            lo.size.height
          );
          textcoords = [
            Offset(atlas.left,atlas.top+off),
            Offset(atlas.right,atlas.top+off),
            Offset(atlas.right,atlas.bottom+off),
            Offset(atlas.left,atlas.bottom+off)
          ];
        }
        objects.add(
          createObject(
            type: SelectedType.values[type], 
            position: position, 
            rotation: rotation,
            scale: scale,
            size: size, 
            name: objectList[object]['name'], 
            layer: objectList[object]['layer'], 
            imageLocation: imageLocation, 
            color: Color(objectList[object]['color']), 
            textcoords: textcoords, 
            textureRect: atlas,
          )
        );
      }
    }

    return objects;
  }
  static List<TileAnimations> _getAnimations(dynamic animationList){
    List<TileAnimations> animations = [];
    if(animationList != null){
      for(String animation in animationList.keys){
        List<Rect> rects = [];
        for(String rect in animationList[animation]['rects'].keys){
          rects.add(
            Rect.fromLTWH(
              animationList[animation]['rects'][rect]['x'], 
              animationList[animation]['rects'][rect]['y'], 
              animationList[animation]['rects'][rect]['w'], 
              animationList[animation]['rects'][rect]['h']
            )
          );
        }
        animations.add(
          TileAnimations(
            tileSet: animationList[animation]['set'],
            rects: rects,
            timing: animationList[animation]['timing'],
          )
        );
      }
    }

    return animations;
  }
  static List<TileLayers> _getTileLayers(dynamic layerList){
    List<TileLayers> layers = [];
    if(layerList != null){
      for(String layer in layerList.keys){
        int length = layerList[layer]['length'];
        List<TileRects> tiles = List<TileRects>.filled(length, TileRects());
        if(layerList[layer]['tiles'] != null){
          for(String tile in layerList[layer]['tiles'].keys){
            dynamic temp = layerList[layer]['tiles'][tile]['position'];
            List<int> positon = [];

            if(temp.isNotEmpty){
              positon = [temp[0],temp[1]];
            }

            tiles[layerList[layer]['tiles'][tile]['location']] = TileRects(
              tileSet: layerList[layer]['tiles'][tile]['set'],
              isAnimation: layerList[layer]['tiles'][tile]['isAnimation'],
              useAnimation: layerList[layer]['tiles'][tile]['useAnimation'],
              rect: Rect.fromLTWH(
                layerList[layer]['tiles'][tile]['rect']['x'], 
                layerList[layer]['tiles'][tile]['rect']['y'], 
                layerList[layer]['tiles'][tile]['rect']['w'], 
                layerList[layer]['tiles'][tile]['rect']['h']
              ),
              position: positon,
              transform: RSTransform(
                layerList[layer]['tiles'][tile]['transform']['scos'], 
                layerList[layer]['tiles'][tile]['transform']['ssin'], 
                layerList[layer]['tiles'][tile]['transform']['tx'], 
                layerList[layer]['tiles'][tile]['transform']['ty']
              )
            );
          }
        }

        layers.add(
          TileLayers(
            name: layer,
            length: length,
            tiles: tiles,
          )
        );
      }
    }

    return layers;
  }
  static List<List<Rect>>? _getTileCollicions(Map<String,dynamic>? collisionsList,int? length){
    if(length == null) return null;
    List<List<Rect>> collisions = List.filled(length, []);
    if(collisionsList != null && length > 0){
      for(String key in collisionsList.keys){
        int loc = int.parse(key.split('_')[1]);
        List<Rect> col = [];
        for(String collider in collisionsList[key].keys){
          col.add(
            Rect.fromLTWH(
              collisionsList[key][collider]['x'], 
              collisionsList[key][collider]['y'], 
              collisionsList[key][collider]['width'], 
              collisionsList[key][collider]['height']
            )
          );
        }
        collisions[loc] = col;
      }
    }
    return collisions;
  }
  static Future<void> load(String file, LevelScene scene) async{
    String data;
    if(kIsWeb){
      data = file;//utf8.decode(file.bytes);
    }
    else{
      data = await File(file).readAsString();
    }

    dynamic convert = json.decode(data);

    for(String keys in convert.keys){
      switch (keys) {
        case 'tileSets':
        if(convert[keys] == null) break;
          for(String set in convert[keys].keys){
            final Map<String,dynamic> grid = convert[keys][set]['grid'];
            int width = grid['width'];
            int height = grid['height'];
            await scene.updateTileset(
              path:convert[keys][set]['image'], 
              name:convert[keys][set]['name'],
              gridUpdate:true,
              type: GridType.values[grid['type']],
              gridWidth: width,
              gridHeight: height,
              collisions: _getTileCollicions(grid['collisions'],grid['length'])
            );
          }
          break;
        case 'loadedObjects':
          if(convert[keys] == null) break;
          for(String set in convert[keys].keys){
            List<Rect> locations = [];
            List<String>? names = [];
            List<double>? scales = [];

            if(convert[keys][set]['objectScale'] != null){
              List<dynamic> temp = convert[keys][set]['objectScale'];
              for(int i = 0; i < temp.length; i++){
                scales.add(double.parse(temp[i].toString()));
              }
            }
            else{
              scales = null;
            }

            if(convert[keys][set]['spriteNames'] != null){
              List<dynamic> temp = convert[keys][set]['spriteNames'];
              for(int i = 0; i < temp.length; i++){
                names.add(temp[i].toString());
              }
            }
            else{
              names = null;
            }

            if(convert[keys][set]['spriteLocations'] != null){
              for(String location in convert[keys][set]['spriteLocations'].keys){
                locations.add(
                  Rect.fromLTWH(
                    convert[keys][set]['spriteLocations'][location]['x'], 
                    convert[keys][set]['spriteLocations'][location]['y'], 
                    convert[keys][set]['spriteLocations'][location]['w'], 
                    convert[keys][set]['spriteLocations'][location]['h']
                  )
                );
              }
            }
            await scene.loadObject(
              convert[keys][set]['image'],
              LoadedType.values[convert[keys][set]['loadedType']],
              show: convert[keys][set]['visible'],
              locations: locations,
              scales: scales,
              objType: ObjectType.values[convert[keys][set]['objectType']],
              names: names
            );
          }
          break;
        case 'levels':
          List<Levels> levels = [];
          for(String level in convert[keys].keys){
            print(level);
            Grid grid = _getGrid(convert[keys][level]['grid']);
            levels.add(Levels(
              name: convert[keys][level]['name'],
              tileLayer: _getTileLayers(convert[keys][level]['tileLayer']),
              animations: _getAnimations(convert[keys][level]['animations']),
              objects: _getObjects(convert[keys][level]['objects'],scene),
              maxGridSize: Size(convert[keys][level]['maxGridWidth'].toDouble(),convert[keys][level]['maxGridHeight'].toDouble()),
              grid: grid
            ));
          }
          if(levels.isNotEmpty){
            scene.importLevels(levels);
          }
          break;
        default:
      }
    }
  }
} 