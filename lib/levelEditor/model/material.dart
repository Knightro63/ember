import 'dart:async';
import 'dart:io';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'dart:ui';

class Material {
  Material()
      : name = '',
        ambient = Vector3.all(0.1),
        diffuse = Vector3.all(0.8),
        specular = Vector3.all(0.5),
        ke = Vector3.zero(),
        tf = Vector3.zero(),
        mapKa = '',
        mapKd = '',
        mapKe = '',
        mapBump = '',
        shininess = 0.8,
        ni = 0,
        opacity = 1.0,
        emissivity = 8;
  String name;
  Vector3 ambient;
  Vector3 diffuse;
  Vector3 specular;
  Vector3 ke;
  Vector3 tf;
  double shininess;
  double ni;
  double opacity;
  int emissivity;
  String mapKa;
  String mapKd;
  String mapKe;
  String mapBump;
}

/// load an image from asset
Future<Image> loadImageFromAsset(String fileName, {bool isAsset = true, bool makeGray = false}) {
  final c = Completer<Image>();
  var dataFuture;
  if (isAsset) 
    dataFuture = rootBundle.load(fileName).then((data) => data.buffer.asUint8List());
  else 
    dataFuture = File(fileName).readAsBytes();

  dataFuture.then((data) {
    // if(makeGray){
    //   img.Image image = img.grayscale(img.decodeJpg(data));
    //   data = img.encodeJpg(image);
    // }

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

/// load texture from asset
Future<MapEntry<String, Image>?> loadTexture(Material? material, String basePath, {bool isAsset = true}) async {
  // get the texture file name
  bool makeGray = false;
  if (material == null) return null;
  String fileName = material.mapKa;
  if (fileName == '') fileName = material.mapKd;
  if (fileName == ''){
    fileName = material.mapBump;
    makeGray = true;
  }
  if (fileName == '') return null;

  // try to load image from asset in subdirectories
  Image? image;
  final List<String> dirList = fileName.split(RegExp(r'[/\\]+'));
  while (dirList.isNotEmpty) {
    fileName = path.join(basePath, path.joinAll(dirList));
    try {
      image = await loadImageFromAsset(fileName, isAsset: isAsset, makeGray: makeGray);
    } catch (_) {}
    if (image != null) return MapEntry(fileName, image);
    dirList.removeAt(0);
  }
  return null;
}

/// Convert Vector3 to Color
Color toColor(Vector3 v, [double opacity = 1.0]) {
  return Color.fromRGBO((v.r * 255).toInt(), (v.g * 255).toInt(), (v.b * 255).toInt(), opacity);
}

/// Convert Color to Vector3
Vector3 fromColor(Color color) {
  return Vector3(color.red / 255, color.green / 255, color.blue / 255);
}
