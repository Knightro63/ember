import 'dart:ui';
import 'package:flutter/material.dart' hide Image;
import 'package:vector_math/vector_math_64.dart' hide Triangle, Vector4, Colors;

enum SelectedType{rect,image,tile,collision,atlas,animation,object}
enum ExportType{ember,json}
enum SnapGrid{center,all,corners,none}//TopLeft,TopRght,BottomLeft,BottomRight,

class Converter{
  Converter();
  static Offset toOffset(Vector3 cameraPosition,Vector3 position,[Offset offset = const Offset(0,0)]){
    double cameraX = cameraPosition.x;
    double cameraY = cameraPosition.y;
    return Offset((position.x*100-(cameraX*100))+offset.dx, (position.y*-100+(cameraY*100))+offset.dy);
  }
  static Vector3 toVector3(Vector3 cameraPosition,Offset position){
    double cameraX = cameraPosition.x;
    double cameraY = cameraPosition.y;
    return Vector3(
      (position.dx+(cameraX*100))/100,
      (position.dy-(cameraY*100))/-100,
      0
    );
  }
}
class CanvasRects{
  CanvasRects({
    required this.color,
    required this.rect,
    this.name,
    required this.type,
    this.imageLocation,
    this.layer = 0
  });

  Color color;
  Rect rect;
  String? name;
  SelectedType type;
  int layer;
  int? imageLocation;
}
class Grid{
  Grid({
    this.show = true,
    this.height = 18,
    this.width = 30,
    this.boxSize = const Size(50,50),
    this.lineWidth = 0.25,
    this.color = const Color(0x55ffffff),
    this.snap = SnapGrid.none,
  });

  bool show;
  Size boxSize;
  int height;
  int width;
  double lineWidth;
  Color color;
  SnapGrid snap;
  Offset offset = const Offset(0,0);
}