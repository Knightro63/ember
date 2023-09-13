import 'package:flutter/material.dart';
import 'package:ember/ember.dart';

import 'ui/tileset.dart';
import 'ui/level_modifers.dart';
import 'src/styles/globals.dart';

class UIScreen extends StatefulWidget {
  const UIScreen({Key? key}):super(key: key);
  @override
  _UIPageState createState() => _UIPageState();
}

class _UIPageState extends State<UIScreen> {
  double deviceWidth = 0;
  double deviceHeight = 0;
  bool resetNav = false;
  bool updateTileScene = false;
  late LevelScene levelScene;
  //int selectedAnimation;
  int selectedTab = 0;
  String info = '';
  LevelEditorCallbacks? prevLevelCall;

  Grid get grid => Grid();

  @override
  void initState(){
    levelScene = LevelScene(
      onStartUp: () => setState((){
        _onLevelSceneCreated();
      }
    ));
    
    levelScene.updateTileset(
      path: 'assets/tiled/tileset.png',
      name: 'Dungeon',
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
      'assets/tiled/pirate.png',
      LoadedType.sheet,
      objType: ObjectType.charcter,
      
    );
    levelScene.loadObject(
      'assets/tiled/tree.png',
      LoadedType.sheet,
      objType: ObjectType.item
    );
    // levelScene.loadObject(
    //   'assets/test_landscapes.png',
    //   LoadedType.sheet,
    //   objType: ObjectType.landscape
    // );
    super.initState();
  }
  @override
  void dispose(){
    super.dispose();
  }

  void jleCallback({required LevelEditorCallbacks call, Offset? details}){
    if(prevLevelCall != null && prevLevelCall == call && call != LevelEditorCallbacks.onTap) return;
    prevLevelCall = call;
    switch (call) {
      case LevelEditorCallbacks.onTap:
        setState(() {
          resetNav = true;
        });
        break;
      case LevelEditorCallbacks.newObject:
        levelScene.clear();
        break;
      case LevelEditorCallbacks.open:
        levelScene.clear();
        break;
      case LevelEditorCallbacks.save:
        break;
      case LevelEditorCallbacks.removeObject:
        setState(() {
          if(levelScene.objectTappedOn.isNotEmpty){

          }
        });
        break;
      default:
    }
  }
  void callBacks({LSICallbacks? call, int? location}){
    switch (call) {
      case LSICallbacks.updatedNav:
        setState(() {
          resetNav = !resetNav;
        });
        break;
      case LSICallbacks.clear:
        setState(() {
          resetNav = !resetNav;
          levelScene.clear();
        });
        break;
      case LSICallbacks.updateLevel:
        setState(() {
          updateTileScene = !updateTileScene;
          levelScene.update();
        });
        break;
      default:
    }
  }

  void _onLevelSceneCreated(){
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      if(!levelScene.loaded){
        levelScene.camera.position.x = -7.5;
        levelScene.camera.position.y = 4.5;
        levelScene.rayCasting = true;
        levelScene.camera.cameraControls = CameraControls(
          panX: true,
          panY: true,
          zoom: true
        );
        levelScene.loaded = true;
        levelScene.update();
        setState(() {});
      }
    });
  }

  Widget levelSheetEditor(){
    return Column(
      children:[
        Container(
          height: 30,
          width: deviceWidth,
          padding: const EdgeInsets.fromLTRB(5,0,5,0),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            //borderRadius: BorderRadius.all(Radius.circular(5)),
            boxShadow: [BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 5,
              offset: const Offset(2,2),
            ),]
          ),
          child: LevelModifers(
            scene: levelScene,
            height: 30,
            width: deviceWidth,
          ),
        ),
        Row(
          children: [
            Stack(children:[
              SizedBox(
                height: deviceHeight-5,
                width: deviceWidth-240,
                child: LevelEditor(
                  scene: levelScene,
                  interactive: true,
                  callback: jleCallback,
                )
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: 
                SizedBox(
                  height: 25,
                  width: deviceWidth-240,
                  child: Text(info)
                )
              )
            ]),
            Container(
              height: deviceHeight-10,
              width: 240,
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.fromLTRB(5,0,5,5),
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                boxShadow: [BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 5,
                  offset: const Offset(2,2),
                ),]
              ),
              child: ListView(
                children: [
                  Tileset(
                    scene: levelScene,
                    width: 240,
                    height: deviceHeight/3,
                    update: updateTileScene,
                    callback: callBacks,
                  )
                ],
              )
            )
        ]
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    double safePadding = MediaQuery.of(context).padding.top;
    deviceHeight = MediaQuery.of(context).size.height-safePadding-25;

    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: levelSheetEditor()
      ),
    );
  }
}