import 'dart:ui';
import 'package:flutter/material.dart' hide Image;
import 'package:vector_math/vector_math_64.dart' hide Triangle hide Colors;
import '../editors/editors.dart';

class SelectedObjects{
  SelectedObjects({
    required this.type,
    required this.animation,
    this.frame,
    this.toColor
  });

  SelectedType type;
  int animation;
  int? frame;
  int? toColor;
}
class Object {
  Object({
    Vector3? position,
    Size? size,
  }){
    this.position = position ?? Vector3(0.0, 0.0, 0.0);
    this.size = size ?? const Size(5,5);
    savePosition();
  }

  late Vector3 position;
  Vector3 _tempPosition = Vector3.zero();
  late Size size;
  Vector2 _from = Vector2(0,0);

  void updatePositionStart(Vector2 to){
    _from.x = to.x;
    _from.y = to.y;
  }
  void updatePosition(Vector2 to, [double sensitivity=1.0]){
    final double x = (to.x - _from.x)/100*sensitivity;
    final double y = (to.y - _from.y)/100*sensitivity;

    position.x += x;
    position.y -= y;

    _from.x = to.x;
    _from.y = to.y;
  }
  void move(int x, int y){
    position.x = _tempPosition.x+x/100;
    position.y = _tempPosition.y-y/100;
  }
  void savePosition(){
    _tempPosition = position;
  }
  void resetPosition(){
    position = _tempPosition;
  }
  void scale(int x, int y){
    size = Size(size.width+x,size.height+y);
  }
  void scaleMouse(Vector2 to, [double sensitivity=1.0]){
    final double x = ((to.x - _from.x))*sensitivity;
    final double y = ((to.y - _from.y))*sensitivity;

    size = Size(size.width+x,size.height+y);

    _from.x = to.x;
    _from.y = to.y;
  }
}
class SpriteImage{
  SpriteImage({
    required this.sprite,
    Vector3? position,
    Rect? section,
    this.name = '',
    this.color = const Color(0xffff0000),
  }){
    this.section = section ?? Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble());
    this.position = position ?? Vector3(0.0, 0.0, 0.0);
    savePosition();
  }

  Image sprite;
  late Rect section;
  String name;
  late Vector3 position;
  Vector3 _tempPosition = Vector3.zero();
  Vector2 _from = Vector2(0,0);
  Color color;

  void updatePositionStart(Vector2 to){
    _from.x = to.x;
    _from.y = to.y;
  }
  void updatePosition(Vector2 to, [double sensitivity=1.0]){
    final double x = ((to.x - _from.x))/100*sensitivity;
    final double y = ((to.y - _from.y))/100*sensitivity;

    position.x += x;
    position.y -= y;

    _tempPosition = position;

    _from.x = to.x;
    _from.y = to.y;
  }
  void move(int x, int y){
    position.x = _tempPosition.x+x/100;
    position.y = _tempPosition.y-y/100;
  }
  void savePosition(){
    _tempPosition = position;
  }
  void resetPosition(){
    position = _tempPosition;
  }
}
