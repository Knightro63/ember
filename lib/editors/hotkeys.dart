import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HotKeyTypes{
delete,
edit,
all,
rotate,
translate,
scale,
save,
newSheet,
open,
undo,
redo,
copy,
paste,
cut,
control,
move,
directionX,
directionY,
none,
number,
enter,
backSpace
}

class HotKeys{
  HotKeys({
    this.directionPressed = false,
    this.movePressed = false,
    this.scalePressed = false,
    this.rotatePressed = false,
    this.currentMove = ''
  });
  
  bool movePressed;
  bool directionPressed;
  bool scalePressed;
  bool rotatePressed;
  bool isDirectionX = false;
  String currentMove;

  bool isNumberPressed(String? number){
    if((number != null && int.tryParse(number) != null) || number == '-'){
      return true;
    }
    return false;
  }

  void reset(){
    scalePressed = false;
    rotatePressed = false;
    movePressed = false;
    directionPressed = false;
    currentMove = '';
  }

  HotKeyTypes getHotKeyType(RawKeyEvent event){
    int keyId = event.logicalKey.keyId;

    if(event.isControlPressed && event.isShiftPressed){
      switch (keyId) {
        case 122:
          return  HotKeyTypes.redo;
        default:
      }
    }
    else if(event.isControlPressed){
      switch (keyId) {
        case 118:
          return  HotKeyTypes.paste;
        case 99:
          return  HotKeyTypes.copy;
        case 121:
          return  HotKeyTypes.redo;
        case 120:
          return  HotKeyTypes.cut;
        case 122:
          return  HotKeyTypes.undo;
        case 115:
          return  HotKeyTypes.save;
        case 110:
          return  HotKeyTypes.newSheet;
        case 111:
          return  HotKeyTypes.open;
        default:
          return HotKeyTypes.control;
      }
    }
    else{
      switch (keyId) {
        case 4294967423:
          return  HotKeyTypes.delete;
        case 4294967304:
          return  HotKeyTypes.backSpace;
        case 4295426091:
          return  HotKeyTypes.edit;
        case 4294967309:
          return  HotKeyTypes.enter;
        case 115:
          scalePressed = true;
          return  HotKeyTypes.scale;
        case 97:
          return  HotKeyTypes.all;
        case 114:
          rotatePressed = true;
          return  HotKeyTypes.rotate;
        case 109:
          movePressed = true;
          return  HotKeyTypes.move;
        case 120:
          if(movePressed || scalePressed){
            directionPressed = true;
            isDirectionX = true;
          }
          return HotKeyTypes.none;
        case 121:
          if(movePressed || scalePressed){
            directionPressed = true;
            isDirectionX = false;
          }
          return HotKeyTypes.none;
        default:
          if(event.character != null && isNumberPressed(event.character!)){
            return HotKeyTypes.number;
          }
      }
    }
    return HotKeyTypes.none;
  }
}