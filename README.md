# ember

[![Pub Version](https://img.shields.io/pub/v/ember)](https://pub.dev/packages/ember)
[![analysis](https://github.com/Knightro63/ember/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63/ember/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin designed for flutter flame and bonfire to allow users to create their own levels using tile sheets and sprite sheets.

<picture>
  <img alt="Image of how ember works." src="https://github.com/Knightro63/ember/blob/main/images/readmeImage1.png">
</picture>

<picture>
  <img alt="Image of how ember works." src="https://github.com/Knightro63/ember/blob/main/images/readmeImage2.png">
</picture>

## Getting started

To get started with ember add the package to your pubspec.yaml file.

## Usage

This project is a basic Tiled generator that is able to be placed directly into a flutter flame or bonfire game as a create level section. 

In this plugin there are two main scenes the LevelEditor scene and the ImageEditor scene. These two scenes work with each other to create the desired level with all the information available.

### LevelEditor
The LevelEditor is the main scene that has all of the tile locations and objects that will be generated in the game. The loader for bonfire uses the names of the objects to place them accordingly e.g.(player will be put in the player spot, and enemy1 will be put in enemy 1 slot and so on). If they do not have names or are just the generic name they will be placed as landscapes or beckgorund objects. Make sure all of the layering is correct as well. 

If a .ember (json file with a ember designation) file is generated and placed in your assets folder just load that and it will place all of the initial creations in the correct spot. If a json is saved it will be only that level, which will not include any other level saved and is used for bonfire loader only.

To get started add LevelScene and Grid at the top of you file and in the init either load a ember file or load everything individually.

```dart
  late LevelScene levelScene;
  Grid get grid => Grid();

  @override
  void initState(){
    levelScene = LevelScene(
      onStartUp: () => setState((){
        _onLevelSceneCreated();
      }
    ));
    
    levelScene.updateTileset(
      path: 'assets/test_tileset.png',
      name: 'TileSet',
      gridHeight: 32,
      gridWidth: 32,
      type: GridType.manual,
      gridUpdate: true
    ).then((value){
      levelScene.update();
      updateTileScene = true;
      setState(() {});
    });

    levelScene.loadObject(
      'assets/test_charcters.png',
      LoadedType.sheet,
      objType: ObjectType.charcter
    );
    levelScene.loadObject(
      'assets/test_objects.png',
      LoadedType.sheet,
      objType: ObjectType.item
    );
    levelScene.loadObject(
      'assets/test_landscapes.png',
      LoadedType.sheet,
      objType: ObjectType.landscape
    );
    super.initState();
  }
```
Lastly add the LevleEditor widget to your widget tree.

```dart
  LevelEditor(
    scene: levelScene,
    interactive: true,
    callback: callback,
  );
```

### ImageEditor
The ImageEditor is the secondary scene and the helping scene. It is able to add collisions to tiles or seperate your sprites in your sprite sheet (If this was done already in you .ember file it will load directly and this only needs to be done once. This portion is mainly for editor uses not for the user if possible.) and view the tiles for selection to be placed in the LevelScene.

To get started add TileScene at the top of you file and in the initadd the LevelScene variable.

```dart
  late TileScene tileScene;

  @override
  void initState() {
    tileScene = TileScene(
      onUpdate:() => setState(() {
        _onSceneCreated();
      })
    );
  }
```

## Example app

A basic example of this is located in the example folder. A more advanced version of the example can be found [here](https://github.com/Knightro63/level_editor).

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/ember/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/ember/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/ember/pulls) directly.

## Additional Information

This plugin is only for creating tiled or object levels, it is not a game engine. While it will work as a stand alone project like the example it was made to work with bonfire and flame.
