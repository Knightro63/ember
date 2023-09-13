import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart' hide Image, Material;
import 'package:flutter/services.dart';
import 'package:ember/ember.dart';
import '../src/navigation/highlight.dart';
import 'package:vector_math/vector_math_64.dart' hide Triangle hide Colors;
import '../src/styles/widgets.dart';
import '../src/styles/globals.dart';

class Tileset extends StatefulWidget{
  const Tileset({
    Key? key,
    required this.scene,
    this.height,
    this.width = 100,
    this.update = false,
    this.callback
  }):super(key: key);

  final LevelScene scene;
  final double? height;
  final double width;
  final bool update;
  final void Function({LSICallbacks call})? callback;

  @override
  _TilesetState createState() => _TilesetState();
}

class _TilesetState extends State<Tileset>{
  double height = 0;
  int? selected;
  int? selectedObject;
  int? selectedAnimation;
  ScrollController setTileSetsController = ScrollController();
  ScrollController setObjectController = ScrollController();
  late TileScene tileScene;
  List<TextEditingController> controller = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNodeImage = FocusNode();
  Timer? _timer;
  late HighLight highLight;
  
  final List<GlobalKey> _key = [
    LabeledGlobalKey('fabCreateGridManual'),
    LabeledGlobalKey('fabCreateGridAuto'),
    LabeledGlobalKey('fabAddLayer'),
    LabeledGlobalKey('fabCreateAnimation'),
    LabeledGlobalKey('fabCreateCollision'),
    LabeledGlobalKey('fabLayerUp'),
    LabeledGlobalKey('fabLayerDown'),
    LabeledGlobalKey('fabObjectType'),
  ];
  List<TextEditingController> tileTC = [];
  List<TextEditingController> objectTC = [];
  String selectedDropDown = 'Landscape';
  late List<DropdownMenuItem<String>> objectDropDown;
  List<int> frames = [];
  bool updateAnimation = true;

  List<bool> dropDown = [false,false,false,false,false,false];
  List<bool> view = [false,false,false,false];

  @override
  void initState() {
    objectDropDown = setDropDownItems(['Landscape','Charcter','Item']);
    height = (widget.height==null)? 36*4.0+15:widget.height!;
    highLight = HighLight(
      context: context
    );
    tileScene = TileScene(
      onUpdate:() => setState(() {
        //_onSceneCreated();
      })
    );
    const tSec = Duration(milliseconds: 500);
    _timer = Timer.periodic(tSec, (Timer timer){
      widget.scene.update();
      updateAnimation = true; 
      setState(() {});
    });
    _tileSteup();
    super.initState();
  }
  @override
  void dispose() {
    highLight.closeMenu();
    _timer?.cancel();
    super.dispose();
  }
  static List<DropdownMenuItem<String>> setDropDownItems(List<String> info){
    List<DropdownMenuItem<String>> items = [];
    for (int i =0; i < info.length;i++) {
      items.add(DropdownMenuItem(
          value: info[i],
          child: Text(
            info[i], 
            overflow: TextOverflow.ellipsis,
          )
      ));
    }
    return items;
  }
  void _tileSteup(){
    for(int i = 0; i < widget.scene.levelInfo[widget.scene.selectedLevel].animations.length;i++){
      frames.add(widget.scene.levelInfo[widget.scene.selectedLevel].animations[i].rects.length);
    }

    for(int i = 0; i < widget.scene.levelInfo[widget.scene.selectedLevel].tileLayer.length;i++){
      tileTC.add(TextEditingController());
      tileTC[i].text = widget.scene.levelInfo[widget.scene.selectedLevel].tileLayer[i].name;
    }
    
    for(int i = 0; i < widget.scene.levelInfo[widget.scene.selectedLevel].objects.length;i++){
      objectTC.add(TextEditingController());
      objectTC[i].text = widget.scene.levelInfo[widget.scene.selectedLevel].objects[i].name;
    }

    widget.scene.selectedTile = [];
    tileScene.tileSets = widget.scene.tileSets;
    tileScene.allTileImage = widget.scene.allTileImage;
    tileScene.camera.viewportHeight = height-36-25;
    tileScene.camera.viewportWidth = widget.width-20;
    tileScene.camera.panCamera(Vector2(-tileScene.camera.viewportWidth/2,-tileScene.camera.viewportHeight/2));
    tileScene.update();
  }
  
  int _getObjectType(String val){
    for(int i = 0; i < ObjectType.values.length;i++){
      if(ObjectType.values[i].toString().replaceAll('ObjectType.', '') == val.toLowerCase()){
        return i;
      }
    }
    return 0;
  }
  double _getMiniMapHeight(){
    double mmHeight = tileScene.camera.viewportHeight;
    double zoom = widget.scene.levelImage!.width > 320?1.0-(widget.scene.levelImage!.width-240)/widget.scene.levelImage!.width:1.0;

    if(widget.scene.levelImage!.height.toDouble()*zoom < tileScene.camera.viewportHeight){
      mmHeight = widget.scene.levelImage!.height.toDouble()*zoom;
    }

    return mmHeight;
  }

  Widget _createTileCollision(int loc){
    ImageScene spriteScene = ImageScene();
    Rect selectedRect = tileScene.tileTappedOn[0].rect!;
    double off = widget.scene.tileSets[loc].offsetHeight.toDouble();
    void onSceneCreated(ImageScene scene){
      WidgetsBinding.instance.addPostFrameCallback((_) { 
        if(!spriteScene.loaded){
          double zoom = 1.0-(selectedRect.height-240)/selectedRect.height;

          spriteScene.camera.zoomCamera(zoom);
          spriteScene.rayCasting = true;
          spriteScene.camera.cameraControls.zoom = false;
          spriteScene.loaded = true;

          spriteScene.camera.position.x = -selectedRect.width/200;
          spriteScene.camera.position.y = selectedRect.height/200;

          spriteScene.addSprite(
            SpriteImage(
              sprite: tileScene.allTileImage!,
              section: Rect.fromLTWH(
                -selectedRect.left, 
                -off-selectedRect.top,
                selectedRect.width,
                selectedRect.height
              ),
              position: Vector3(-selectedRect.width/200,selectedRect.height/200,0),
            )
          );
          int loc = tileScene.tileTappedOn[0].gridLocation;
          spriteScene.setCollisions(tileScene.tileSets[tileScene.selectedTileSet].grid.collisions[loc]);
          spriteScene.update();
          setState(() {});
        }
      });
    }
    return StatefulBuilder(builder: (context, setState) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: 320+60.0,
          width: 320,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: const [BoxShadow(
              color: Colors.black,
              blurRadius: 5,
              offset: Offset(2,2),
            ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:[
            SizedBox(
              height: 320,
              width: 320,
              child: RawKeyboardListener(
              focusNode: _focusNodeImage,
              onKey: (key){
                spriteScene.isControlPressed = key.isControlPressed;
              },
              child: ImageEditor(
                  scene: spriteScene,
                  interactive: true,
                  onSceneCreated: onSceneCreated,
                )
              )
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              SquareButton(
                text:'Add',
                onTap: (){
                  spriteScene.addCollision();
                },
                textColor: Theme.of(context).cardColor,
                buttonColor: Theme.of(context).primaryTextTheme.bodyMedium!.color!,
                height: 30,
                radius: 30/2,
                width: 300/3-10,
              ),
              SquareButton(
                text:'remove',
                onTap: (){
                  spriteScene.removeSelectedCollision();
                },
                textColor: Theme.of(context).cardColor,
                buttonColor: Theme.of(context).primaryTextTheme.bodyMedium!.color!,
                height: 30,
                radius: 30/2,
                width: 300/3-10,
              ),
              SquareButton(
                text:'Save',
                onTap: (){
                  setState((){});
                  int loc = tileScene.tileTappedOn[0].gridLocation;
                  tileScene.tileSets[tileScene.selectedTileSet].grid.collisions[loc] = spriteScene.getCollisionLocations();
                  Navigator.of(context).pop();
                },
                textColor: Theme.of(context).cardColor,
                buttonColor: Theme.of(context).primaryTextTheme.bodyMedium!.color!,
                height: 30,
                radius: 30/2,
                width: 300/3-10,
              ),
            ])
          ]),
        )
      );
    }
    );
  }
  Widget editGrid(){
    return StatefulBuilder(builder: (context, setState) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: 150,
          width: 240,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: const [BoxShadow(
              color: Colors.black,
              blurRadius: 5,
              offset: Offset(2,2),
            ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                const Text('Height:'),
                EnterTextFormField(
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  label: 'Height',
                  width: 120,
                  height: 25,
                  maxLines: 1,
                  color: Theme.of(context).canvasColor,
                  onChanged: (val){

                  },
                  onEditingComplete: (){
                    
                  },
                  onSubmitted: (val){
                    
                  },
                  onTap: (){

                  },
                  //margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                  //padding: EdgeInsets.all(7),
                  controller: controller[0],
                )
              ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                const Text('Width:'),
                EnterTextFormField(
                  label: 'Width',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  width: 120,
                  height: 25,
                  maxLines: 1,
                  color: Theme.of(context).canvasColor,
                  onChanged: (val){
                    
                  },
                  onEditingComplete: (){
                    
                  },
                  onSubmitted: (val){
                    
                  },
                  onTap: (){

                  },
                  //margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                  //padding: EdgeInsets.all(7),
                  controller: controller[1],
                )
              ]),
              SquareButton(
                text:'Save',
                onTap: (){
                  setState((){});
                  if(controller[1].text != '' && controller[0].text != ''){
                    tileScene.tileSets[tileScene.selectedTileSet].manualGrid(int.parse(controller[1].text), int.parse(controller[0].text));
                  }
                  widget.scene.tileSets = tileScene.tileSets;
                  Navigator.of(context).pop();
                },
                textColor: Theme.of(context).cardColor,
                buttonColor: Theme.of(context).primaryTextTheme.bodyMedium!.color!,
                height: 30,
                radius: 30/2,
                width: 300/3-10,
              ),
          ]),
        )
      );
    });
  }
  Widget seperateImageOptions(int loc){
    ImageScene spriteScene = ImageScene();

    void onSceneCreated(ImageScene scene){
      WidgetsBinding.instance.addPostFrameCallback((_) { 
        if(!spriteScene.loaded){

          double zoom = widget.scene.loadedObjects[loc].size.height > 320?1.0-(widget.scene.loadedObjects[loc].size.height-240)/widget.scene.loadedObjects[loc].size.height:1.0;
          //if(widget.scene.loadedObjects[loc].size.height < widget.scene.loadedObjects[loc].size.width)
            //zoom = widget.scene.loadedObjects[loc].size.width > 320?1.0-(widget.scene.loadedObjects[loc].size.width-240)/widget.scene.loadedObjects[loc].size.width:1.0;
          spriteScene.camera.zoomCamera(zoom);
          spriteScene.rayCasting = true;
          spriteScene.camera.cameraControls.zoom = false;
          spriteScene.loaded = true;

          spriteScene.camera.position.x = -1;//-widget.scene.loadedObjects[loc].size.width+520;
          spriteScene.camera.position.y = 1;//widget.scene.loadedObjects[loc].size.height+520;

          spriteScene.addSprite(
            SpriteImage(
              sprite: widget.scene.allObjectImage!,
              section: Rect.fromLTWH(
                0, 
                -widget.scene.loadedObjects[loc].offsetHeight.toDouble(),
                widget.scene.loadedObjects[loc].size.width,
                widget.scene.loadedObjects[loc].size.height
              ),
              position: Vector3(-widget.scene.loadedObjects[loc].size.width/1000,widget.scene.loadedObjects[loc].size.height/1000,0),
            )
          );
          spriteScene.update();
          setState(() {});
        }
      });
    }
    return StatefulBuilder(builder: (context, setState) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: 320+60.0,
          width: 320,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: const [BoxShadow(
              color: Colors.black,
              blurRadius: 5,
              offset: Offset(2,2),
            ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:[
            SizedBox(
              height: 320,
              width: 320,
              child: RawKeyboardListener(
              focusNode: _focusNodeImage,
              onKey: (key){
                spriteScene.isControlPressed = key.isControlPressed;
              },
              child: ImageEditor(
                  scene: spriteScene,
                  interactive: true,
                  onSceneCreated: onSceneCreated,
                )
              )
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              SquareButton(
                text:'seperate',
                onTap: (){
                  spriteScene.seperateSprites();
                },
                textColor: Theme.of(context).cardColor,
                buttonColor: Theme.of(context).primaryTextTheme.bodyMedium!.color!,
                height: 30,
                radius: 30/2,
                width: 300/3-10,
              ),
              SquareButton(
                text:'combine',
                onTap: (){
                  List<int> com = [];
                  for(int i = 0; i < spriteScene.objectTappedOn.length;i++){
                    com.add(spriteScene.objectTappedOn[i].animation);
                  }
                  spriteScene.combineSprites(com);
                },
                textColor: Theme.of(context).cardColor,
                buttonColor: Theme.of(context).primaryTextTheme.bodyMedium!.color!,
                height: 30,
                radius: 30/2,
                width: 300/3-10,
              ),
              SquareButton(
                text:'Save',
                onTap: (){
                  setState((){});
                  widget.scene.loadedObjects[loc].spriteLocations = spriteScene.getspriteLocations();
                  widget.scene.loadedObjects[loc].spriteNames = List<String>.filled(widget.scene.loadedObjects[loc].spriteLocations.length, 'Object Name');
                  Navigator.of(context).pop();
                },
                textColor: Theme.of(context).cardColor,
                buttonColor: Theme.of(context).primaryTextTheme.bodyMedium!.color!,
                height: 30,
                radius: 30/2,
                width: 300/3-10,
              ),
            ])
          ]),
        )
      );
    }
    );
  }

  List<Widget> tileDD(){
    Levels level = widget.scene.levelInfo[widget.scene.selectedLevel];
    List<Widget> widgets = [      
      Container(
        margin: const EdgeInsets.only(left:5, right: 5, top:10),
        padding: const EdgeInsets.only(left:5, right: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 5,
            offset: const Offset(2,2),
          ),]
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              InkWell(
                onTap: (){
                  setState(() {
                    dropDown[0] = !dropDown[0];
                  });
                },
                child: Icon(
                  dropDown[0]?Icons.arrow_drop_up_outlined:Icons.arrow_drop_down_outlined,
                  size:20
                ),
              ),
              const Text('Tile Layers'),
              InkWell(
                onTap: (){
                  setState(() {
                    view[0] = !view[0];
                    if(view[0]){
                      level.showTiles();
                    }
                    else{
                      level.hideTiles();
                    }
                  });
                },
                child: const Icon(
                  Icons.visibility,
                  size:20
                ),
              )
            ],)
          ]
        ),
      ),
    ];
    if(dropDown[0]){
      for(int i = 0; i < level.tileLayer.length; i++){
        widgets.add(
          Container(
            margin: const EdgeInsets.only(left:15, right: 5, top:10),
            padding: const EdgeInsets.only(left:5, right: 5),
            decoration: BoxDecoration(
              color: widget.scene.levelInfo[widget.scene.selectedLevel].selectedTileLayer != i?Theme.of(context).cardColor:Theme.of(context).secondaryHeaderColor,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
              boxShadow: [BoxShadow(
                color: Theme.of(context).shadowColor,
                blurRadius: 5,
                offset: const Offset(2,2),
              ),]
            ),
            child: InkWell(
              onTap: (){
                widget.scene.levelInfo[widget.scene.selectedLevel].selectedTileLayer = i;
                widget.scene.update();
                setState(() {});
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                InkWell(
                  onTap: (){
                    level.tileLayer[i].visible = !level.tileLayer[i].visible;
                    widget.scene.update();
                    setState(() {});
                  },
                  child: Icon(!level.tileLayer[i].visible?Icons.visibility:Icons.visibility_off,size: 15,),
                ),
                const Text('Tile Map'),
                EnterTextFormField(
                  label: 'name',
                  width: 70,
                  height: 25,
                  maxLines: 1,
                  color: Theme.of(context).canvasColor,
                  onChanged: (val){
                    widget.scene.levelInfo[widget.scene.selectedLevel].tileLayer[i].name = val;
                  },
                  onEditingComplete: (){
                    
                  },
                  onSubmitted: (val){
                    widget.scene.levelInfo[widget.scene.selectedLevel].tileLayer[i].name = val;
                  },
                  onTap: (){

                  },
                  //margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                  padding: const EdgeInsets.all(7),
                  controller: tileTC[i],
                ),
                (level.tileLayer.length > 1)?Column(children:[
                  InkWell(
                    onTap: (){
                      level.moveLayer(i, i-1);
                      widget.scene.update();
                      setState(() {});
                    },
                    child: const Icon(Icons.add,size: 10,),
                  ),
                  InkWell(
                    onTap: (){
                      level.moveLayer(i, i+1);
                      widget.scene.update();
                      setState(() {});
                    },
                    child: const Icon(Icons.remove,size: 10,),
                  )
                ]):Container(),
                InkWell(
                  onTap: (){
                    level.removeLayer(i);
                    widget.scene.update();
                    setState(() {});
                  },
                  child: const Icon(Icons.delete,size: 15,),
                ),
              ],)
            ),
          )
        );
      }
    }
    return widgets;
  }
  List<Widget> objectsDD(){
    List<Widget> widgets = [];
    Levels level = widget.scene.levelInfo[widget.scene.selectedLevel];

    List<Widget> landscape = [      
      Container(
        margin: const EdgeInsets.only(left:5, right: 5, top:10),
        padding:const EdgeInsets.only(left:5, right: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 5,
            offset: const Offset(2,2),
          ),]
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              InkWell(
                onTap: (){
                  setState(() {
                    dropDown[3] = !dropDown[3];
                  });
                },
                child: Icon(
                  dropDown[3]?Icons.arrow_drop_up_outlined:Icons.arrow_drop_down_outlined,
                  size:20
                ),
              ),
              const Text('Landscapes'),
              InkWell(
                onTap: (){
                  setState(() {
                    view[1] = !view[1];
                    if(view[1]){
                      level.showAtlas();
                    }
                    else{
                      level.hideAtlas();
                    }
                  });
                },
                child: const Icon(
                  Icons.visibility,
                  size:20
                ),
              )
            ],)
          ]
        ),
      ),
    ];
    List<Widget> charcters = [      
      Container(
        margin: const EdgeInsets.only(left:5, right: 5, top:10),
        padding: const EdgeInsets.only(left:5, right: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 5,
            offset: const Offset(2,2),
          ),]
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              InkWell(
                onTap: (){
                  setState(() {
                    dropDown[4] = !dropDown[4];
                  });
                },
                child: Icon(
                  dropDown[4]?Icons.arrow_drop_up_outlined:Icons.arrow_drop_down_outlined,
                  size:20
                ),
              ),
              const Text('Charcters'),
              InkWell(
                onTap: (){
                  setState(() {
                    view[1] = !view[1];
                    if(view[1]){
                      level.showAtlas();
                    }
                    else{
                      level.hideAtlas();
                    }
                  });
                },
                child: const Icon(
                  Icons.visibility,
                  size:20
                ),
              )
            ],)
          ]
        ),
      ),
    ];
    List<Widget> items = [      
      Container(
        margin: const EdgeInsets.only(left:5, right: 5, top:10),
        padding: const EdgeInsets.only(left:5, right: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 5,
            offset: const Offset(2,2),
          ),]
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              InkWell(
                onTap: (){
                  setState(() {
                    dropDown[5] = !dropDown[5];
                  });
                },
                child: Icon(
                  dropDown[5]?Icons.arrow_drop_up_outlined:Icons.arrow_drop_down_outlined,
                  size:20
                ),
              ),
              const Text('Items'),
              InkWell(
                onTap: (){
                  setState(() {
                    view[1] = !view[1];
                    if(view[1]){
                      level.showAtlas();
                    }
                    else{
                      level.hideAtlas();
                    }
                  });
                },
                child: const Icon(
                  Icons.visibility,
                  size:20
                ),
              )
            ],)
          ]
        ),
      ),
    ];
    List<Widget> objects = [
      Container(
        margin: const EdgeInsets.only(left:5, right: 5, top:10),
        padding: const EdgeInsets.only(left:5, right: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 5,
            offset: const Offset(2,2),
          ),]
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              InkWell(
                onTap: (){
                  setState(() {
                    dropDown[1] = !dropDown[1];
                  });
                },
                child: Icon(
                  dropDown[1]?Icons.arrow_drop_up_outlined:Icons.arrow_drop_down_outlined,
                  size:20
                ),
              ),
              const Text('Objects'),
              InkWell(
                onTap: (){
                  setState(() {
                    view[2] = !view[2];
                    if(view[2]){
                      level.showObjects();
                    }
                    else{
                      level.hideObjects();
                    }
                  });
                },
                child: const Icon(
                  Icons.visibility,
                  size:20
                ),
              )
            ],)
          ]
        ),
      ),
    ];
    List<Widget> collisions = [
      Container(
        margin: const EdgeInsets.only(left:5, right: 5, top:10),
        padding: const EdgeInsets.only(left:5, right: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 5,
            offset: const Offset(2,2),
          ),]
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              InkWell(
                onTap: (){
                  setState(() {
                    dropDown[2] = !dropDown[2];
                  });
                },
                child: Icon(
                  dropDown[2]?Icons.arrow_drop_up_outlined:Icons.arrow_drop_down_outlined,
                  size:20
                ),
              ),
              const Text('Collisions'),
              InkWell(
                onTap: (){
                  setState(() {
                    view[3] = !view[3];
                    if(view[3]){
                      level.showCollisions();
                    }
                    else{
                      level.hideCollisions();
                    }
                  });
                },
                child: const Icon(
                  Icons.visibility,
                  size:20
                ),
              )
            ],)
          ]
        ),
      ),
    ];

    for(int i = 0; i < level.objects.length; i++){
      if(objectTC.length-1 < i){
        objectTC.add(TextEditingController());
        objectTC[i].text = widget.scene.levelInfo[widget.scene.selectedLevel].objects[i].name;
      }

      Widget temp = Container(
          margin: const EdgeInsets.only(left:15, right: 5, top:5),
          padding: const EdgeInsets.only(left:5, right: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
            boxShadow: [BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 5,
              offset: const Offset(2,2),
            ),]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            InkWell(
              onTap: (){
                level.objects[i].visible = !level.objects[i].visible;
                widget.scene.update();
                setState(() {
                  
                });
              },
              child: Icon(!level.objects[i].visible?Icons.visibility:Icons.visibility_off,size: 15,),
            ),
            Text(level.objects[i].type.toString().replaceAll('SelectedType.', '')),
            EnterTextFormField(
              label: 'name',
              width: 70,
              height: 25,
              maxLines: 1,
              color: Theme.of(context).canvasColor,
              onChanged: (val){
                widget.scene.levelInfo[widget.scene.selectedLevel].objects[i].name = val;
              },
              onEditingComplete: (){
                
              },
              onSubmitted: (val){
                widget.scene.levelInfo[widget.scene.selectedLevel].objects[i].name = val;
              },
              onTap: (){

              },
              //margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
              padding: const EdgeInsets.all(7),
              controller: objectTC[i],
            ),
            Text(level.objects[i].layer.toString()),
            Column(children:[
              InkWell(
                onTap: (){
                  widget.scene.bringToFront(i);
                  widget.scene.update();
                  setState(() {});
                },
                child: const Icon(Icons.add,size: 10,),
              ),
              InkWell(
               onTap: (){
                  widget.scene.sendToBack(i);
                  widget.scene.update();
                  setState(() {});
                },
                child: const Icon(Icons.remove,size: 10,),
              )
            ]),
          ],),
        );
      
      if(level.objects[i].type == SelectedType.collision){
        collisions.add(temp);
      }
      else if(level.objects[i].type == SelectedType.object){
        objects.add(temp);
      }
      else{
        int loc = level.objects[i].imageLocation;
        ObjectType typ = widget.scene.loadedObjects[loc].objectType;
        if(typ == ObjectType.charcter){
          charcters.add(temp);
        }
        if(typ == ObjectType.landscape){
          landscape.add(temp);
        }
        else{
          items.add(temp);
        }
      }
    }

    if(landscape.length < 2 && items.length < 2 && charcters.length < 2 && objects.length < 2 && collisions.length < 2){
      return [Container()];
    }

    if(charcters.length > 1){
      if(dropDown[4]){
        widgets += charcters;
      }
      else{
        widgets.add(charcters[0]);
      }
    }
    if(landscape.length > 1){
      if(dropDown[3]){
        widgets += landscape;
      }
      else{
        widgets.add(landscape[0]);
      }
    }
    if(items.length > 1){
      if(dropDown[5]){
        widgets += items;
      }
      else{
        widgets.add(items[0]);
      }
    }
    if(objects.length > 1){
      if(dropDown[1]){
        widgets += objects;
      }
      else{
        widgets.add(objects[0]);
      }
    }
    if(collisions.length > 1){
      if(dropDown[2]){
        widgets += collisions;
      }
      else{
        widgets.add(collisions[0]);
      }
    }


    return widgets;
  }
  Widget sheetInfo(){
    return ListView(children: tileDD()+objectsDD());
  }

  Widget setTileSets(){
    if(tileScene.tileSets.isEmpty) return Container();
    List<Widget> widgets = [];

    for(int i = 0; i < tileScene.tileSets.length; i++){
      widgets.add(
        SizedBox(
          //width: 120,
          height: 45,
          child: InkWell(
            onTap: (){
              tileScene.selectedTileSet = i;
              widget.scene.selectedLoadedObject = null;
              //tileScene.seperateTiles(i);
              tileScene.update();
              setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              padding: const EdgeInsets.fromLTRB(5,2,5,2),
              alignment: Alignment.center,
              
              decoration: BoxDecoration(
                color: tileScene.selectedTileSet == i?Theme.of(context).secondaryHeaderColor:Theme.of(context).cardColor,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                boxShadow: [BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 5,
                  offset:const Offset(2,2),
                ),]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tileScene.tileSets[i].name.split('.')[0]
                  ),
              ],),
            ),
          )
        )
      );
    }

    return SizedBox(
      height: 36,
      width: 200,
      //margin: EdgeInsets.fromLTRB(5,0,5,0),
      child: GestureDetector(
        onHorizontalDragUpdate: (dragUpdateDetails){
          double pos = setTileSetsController.offset-dragUpdateDetails.delta.dx;
          setTileSetsController.jumpTo(pos);
        },
        child: ListView(
          scrollDirection: Axis.horizontal,
          controller: setTileSetsController,
          children: widgets,
        )
      )
    );
  }
  Widget tileAnimations(){
    if(widget.scene.levelInfo[widget.scene.selectedLevel].animations.isEmpty) return Container(height:0);
    List<Widget> widgets = [];
    for(int i = 0; i < widget.scene.levelInfo[widget.scene.selectedLevel].animations.length;i++){
      TileAnimations ani = widget.scene.levelInfo[widget.scene.selectedLevel].animations[i];
      final Size size = tileScene.tileSets.isNotEmpty && tileScene.tileSets[tileScene.selectedTileSet].grid.rects.isNotEmpty?Size(
        tileScene.tileSets[tileScene.selectedTileSet].grid.rects[i].width,
        tileScene.tileSets[tileScene.selectedTileSet].grid.rects[i].height
      )*tileScene.camera.zoom:const Size(25,25);
      
      if(updateAnimation){
        if(frames.length-1 < i || frames.isEmpty){
          frames.add(ani.rects.length-1);
        }
        frames[i]++;
        if(frames[i] >  ani.rects.length-1){
          frames[i] = 0;
        }
        ani.useFrame = frames[i];
      }
      //     
      widgets.add(
        InkWell(
          onTap: (){
            selectedAnimation = i;
            tileScene.tileTappedOn = [];
            widget.scene.selectedTile = [
              SelectedTile(
                tileSet: ani.tileSet,
                rect: ani.rects[0],
                isAnimation: true,
                animationLocation: i
              )
            ];
            setState(() {});
          },
          child: Stack(children: [
            CustomPaint(
              painter: SpritePainter(
                sprite: widget.scene.allTileImage!,
                src: Rect.fromLTWH(
                  ani.rects[frames[i]].left, 
                  ani.rects[frames[i]].top+widget.scene.tileSets[ani.tileSet].offsetHeight, 
                  size.width, 
                  size.height
                ),
                dst: Rect.fromLTWH(0, 0, size.width, size.height)
              )
            ),
            Container(
              width:  size.width,
              height: size.height,
              decoration: BoxDecoration(
                border: Border.all(color: selectedAnimation == i ?Theme.of(context).secondaryHeaderColor:Theme.of(context).cardColor,width: 2)
              ),
            ),
          ],)
        )
      );
    }
    if(updateAnimation){
      updateAnimation = false;
    }
    return Row(mainAxisAlignment:MainAxisAlignment.start,children: widgets);
  }
  Widget tileModifers(){
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:[
          InkWell(
            onTap: (){
              showDialog(
                context: context,
                builder: (BuildContext context){
                  return editGrid();
                }
              );
            },
            child: MouseRegion(
              onEnter: (PointerEvent details){
                setState(() {
                  highLight.openMenu('Crate Grid',_key[0]);
                });
              },
              onExit: (PointerEvent details){
                setState(() {
                  highLight.closeMenu();
                });
              },
              onHover: (val){
              },
              child: SizedBox( 
                height:20,
                key: _key[0],
                child: const Icon(Icons.grid_on_outlined,size: 20),
              )
            )
          ),
          InkWell(
            onTap: (){
              tileScene.tileSets[tileScene.selectedTileSet].autoGrid(widget.scene.allTileImage!);
              widget.scene.tileSets = tileScene.tileSets;
            },
            child: MouseRegion(
              onEnter: (PointerEvent details){
                setState(() {
                  highLight.openMenu('Auto Grid',_key[1]);
                });
              },
              onExit: (PointerEvent details){
                setState(() {
                  highLight.closeMenu();
                });
              },
              onHover: (val){
              },
              child: SizedBox( 
                height:20,
                key: _key[1],
                child: const Icon(Icons.grid_goldenratio_rounded,size: 20),
              )
            )
          ),
          InkWell(
            onTap: (){
              tileTC.add(TextEditingController());
              tileTC[tileTC.length-1].text = 'Layer';
              widget.scene.levelInfo[widget.scene.selectedLevel].addLayer();
              widget.scene.update();
            },
            child: MouseRegion(
              onEnter: (PointerEvent details){
                setState(() {
                  highLight.openMenu('Add Layer',_key[2]);
                });
              },
              onExit: (PointerEvent details){
                setState(() {
                  highLight.closeMenu();
                });
              },
              onHover: (val){
              },
              child: SizedBox( 
                height:20,
                key: _key[2],
                child: const Icon(Icons.add_box_outlined,size: 20),
              )
            )
          ),
          tileScene.tileSets.isNotEmpty && tileScene.tileSets[tileScene.selectedTileSet].grid.rects.isNotEmpty?InkWell(
            onTap: (){
              if(tileScene.tileTappedOn.length > 1){
                List<Rect> rects = [];
                for(int i = 0; i < tileScene.tileTappedOn.length;i++){
                  rects.add(tileScene.tileTappedOn[i].rect!);
                }
                widget.scene.levelInfo[widget.scene.selectedLevel].animations.add(
                  TileAnimations(
                    tileSet: tileScene.tileTappedOn[0].tileSet!,
                    rects: rects
                  )
                );
                frames.add(rects.length-1);
              }
            },
            child: MouseRegion(
              onEnter: (PointerEvent details){
                setState(() {
                  highLight.openMenu('Create Animation',_key[3]);
                });
              },
              onExit: (PointerEvent details){
                setState(() {
                  highLight.closeMenu();
                });
              },
              onHover: (val){
              },
              child: SizedBox( 
                height:20,
                key: _key[3],
                child: const Icon(Icons.video_call_rounded,size: 20),
              )
            )
          ):Container(),
          tileScene.tileSets.isNotEmpty && tileScene.tileSets[tileScene.selectedTileSet].grid.rects.isNotEmpty?InkWell(
            onTap: (){
              showDialog(
                context: context,
                builder: (BuildContext context){
                 return _createTileCollision(tileScene.selectedTileSet);
              });
            },
            child: MouseRegion(
              onEnter: (PointerEvent details){
                setState(() {
                  highLight.openMenu('Crate Collision',_key[4]);
                });
              },
              onExit: (PointerEvent details){
                setState(() {
                  highLight.closeMenu();
                });
              },
              onHover: (val){
              },
              child: SizedBox( 
                height:20,
                key: _key[4],
                child: const Icon(Icons.add_alert_outlined,size: 20),
              )
            )
          ):Container(),

      ])
    );
  }
  Widget tilePaint(){
    return Container(
      padding: const EdgeInsets.only(left: 5,right: 5),
      width: widget.width-10,
      alignment: Alignment.topLeft,
      child: CustomPaint(
        painter: _TilesetPainter(tileScene),
        size: (tileScene.tileSets.isEmpty)?Size(widget.width-10,widget.width-10):Size(widget.width-10, tileScene.tileSets[tileScene.selectedTileSet].height()),
        isComplex: true,
      )
    );
  }

  Widget sheetObjects(){
    List<Widget> widgets = [];
    if(selected != null && widget.scene.loadedObjects[selected!].spriteLocations.isNotEmpty){
      for(int i = 0; i < widget.scene.loadedObjects[selected!].spriteLocations.length;i++){
        widgets.add(
          InkWell(
            onTap: (){
              setState(() {
                selectedObject = i;
                controller[2].text = widget.scene.loadedObjects[selected!].spriteNames![selectedObject!];
                controller[4].text = widget.scene.loadedObjects[selected!].objectScale[selectedObject!].toString();
              });
            },
            child: Container(
              width: 45,
              height: 45,
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                //color: Theme.of(context).secondaryHeaderColor,
                border: Border.all(color: selectedObject == i?Theme.of(context).secondaryHeaderColor:Colors.grey,width: 2)
              ),
              child: Stack(children:[
                CustomPaint(
                  painter: SpritePainter(
                    sprite: widget.scene.allObjectImage!,
                    src: Rect.fromLTWH(
                      widget.scene.loadedObjects[selected!].spriteLocations[i].left, 
                      widget.scene.loadedObjects[selected!].spriteLocations[i].top+widget.scene.loadedObjects[selected!].offsetHeight, 
                      widget.scene.loadedObjects[selected!].spriteLocations[i].width, 
                      widget.scene.loadedObjects[selected!].spriteLocations[i].height
                    ),
                    dst: const Rect.fromLTWH(0, 0, 40, 40)
                  )
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    InkWell(
                      onTap: (){
                        double ratio = widget.scene.loadedObjects[selected!].spriteLocations[i].width.toDouble()/widget.scene.loadedObjects[selected!].spriteLocations[i].height.toDouble();
                        double scale = widget.scene.loadedObjects[selected!].objectScale[i];
                        Size size = Size(100,100/ratio)*scale;

                        double off = widget.scene.loadedObjects[selected!].offsetHeight.toDouble();
                        Rect updateRect = Rect.fromLTWH(
                          widget.scene.loadedObjects[selected!].spriteLocations[i].left, 
                          widget.scene.loadedObjects[selected!].spriteLocations[i].top+off, 
                          widget.scene.loadedObjects[selected!].spriteLocations[i].width, 
                          widget.scene.loadedObjects[selected!].spriteLocations[i].height
                        );
                        widget.scene.addObject(
                          createObject(
                            type: SelectedType.atlas, 
                            size: size,
                            name: widget.scene.loadedObjects[selected!].spriteNames![i], 
                            layer: widget.scene.loadedObjects[selected!].startingLayer, 
                            imageLocation: selected!,
                            color: Colors.white, 
                            textcoords:[Offset(updateRect.left,updateRect.top),
                              Offset(updateRect.right,updateRect.top),
                              Offset(updateRect.right,updateRect.bottom),
                              Offset(updateRect.left,updateRect.bottom)
                            ], 
                            textureRect: widget.scene.loadedObjects[selected!].spriteLocations[i], 
                          )
                        );
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.add_circle_outline_outlined,
                        size: 15,
                      ),
                    ),
                    InkWell(
                      onTap: (){
                        widget.scene.loadedObjects[selected!].spriteLocations.removeAt(i);
                        widget.scene.loadedObjects[selected!].spriteNames!.removeAt(i);
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.delete,
                        size: 15,
                      ),
                    ),
                  ],)
                  )
              ])
            )
          )
        );
      }
    }

    return Column(
      children: [
      SizedBox(
        height: tileScene.camera.viewportHeight-(selectedObject != null?36:2.0),
        child:widgets.isNotEmpty?ListView(
          children: [
            Wrap(alignment: WrapAlignment.spaceAround,children:widgets)
          ],
        ):Container()
      ),
      selectedObject != null?Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            EnterTextFormField(
              //formatter: [FilteringTextInputFormatter.digitsOnly],
              label: 'Object Name',
              width: 110,
              height: 25,
              maxLines: 1,
              color: Theme.of(context).canvasColor,
              onChanged: (val){
                widget.scene.loadedObjects[selected!].spriteNames![selectedObject!] = val;
              },
              onEditingComplete: (){},
              onSubmitted: (val){},
              onTap: (){},
              margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
              //padding: EdgeInsets.all(5),
              controller: controller[2],
            ),
            Row(children: [
              const Text('Scale:   '),
              EnterTextFormField(
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9_\.]'))],
                //label: 'width',
                width: 40,
                height: 25,
                maxLines: 1,
                color: Theme.of(context).canvasColor,
                onChanged: (val){
                  if(val != ''){
                    widget.scene.loadedObjects[selected!].objectScale[selectedObject!] = double.parse(val);
                  }
                },
                onEditingComplete: (){},
                onSubmitted: (val){},
                onTap: (){},
                margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                padding: const EdgeInsets.all(5),
                controller: controller[4],
              )
            ],)
          ],
        ),
      ):Container(height:0.0),
    ]);
  }
  Widget objects(){
    List<Widget> widgets = [];
    List<Widget> selections = [];

    for(int i = 0; i < objectDropDown.length; i++){
      selections.add(
        SizedBox(
          //width: 120,
          height: 45,
          child: InkWell(
            onTap: (){
              selectedDropDown = objectDropDown[i].value!;
              selectedObject = null;
              selected = null;
              setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              padding: const EdgeInsets.fromLTRB(5,2,5,2),
              alignment: Alignment.center,
              
              decoration: BoxDecoration(
                color:selectedDropDown == objectDropDown[i].value?Theme.of(context).secondaryHeaderColor:Theme.of(context).cardColor,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                boxShadow: [BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 5,
                  offset: const Offset(2,2),
                ),]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${objectDropDown[i].value!}'s"
                  ),
              ],),
            ),
          )
        )
      );
    }
    if(widget.scene.loadedObjects.isNotEmpty){
      if(selected != null && selected !> widget.scene.loadedObjects.length){
        selected = null;
        widget.scene.selectedLoadedObject = null;
      }

      for(int i = 0; i < widget.scene.loadedObjects.length;i++){
        if(widget.scene.loadedObjects[i].show 
          && widget.scene.loadedObjects[i].objectType.toString().replaceAll('ObjectType.', '') == selectedDropDown.toLowerCase()
        ){
          widgets.add(
            InkWell(
              onTap: (){
                setState(() {
                  widget.scene.selectedLoadedObject = i;
                  tileScene.updateTapLocation(null);
                  widget.scene.selectedTile = [];
                  selectedObject = null;
                  selected = i;
                  if(widget.scene.loadedObjects[selected!].type == LoadedType.single && widget.scene.loadedObjects[selected!].spriteNames != null){
                    controller[3].text = widget.scene.loadedObjects[selected!].spriteNames![0];
                    controller[5].text = widget.scene.loadedObjects[selected!].objectScale[0].toString();
                  }
                });
              },
              child: Container(
                width: widget.width/3-10,
                height: widget.width/3-10,
                margin: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: selected == i?Theme.of(context).secondaryHeaderColor:Colors.grey,
                  )
                ),
                child: Stack(children: [
                  CustomPaint(
                    painter: SpritePainter(
                      sprite: widget.scene.allObjectImage!,
                      src: Rect.fromLTWH(0, widget.scene.loadedObjects[i].offsetHeight.toDouble(), widget.scene.loadedObjects[i].size.width, widget.scene.loadedObjects[i].size.height),
                      dst: Rect.fromLTWH(0, 0, widget.width/3-15, widget.width/3-15)
                    )
                  ),
                  widget.scene.loadedObjects[i].type == LoadedType.sheet?Align(
                    alignment: Alignment.topCenter,
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      InkWell(
                        onTap: (){
                          showDialog(
                            context: context,
                            builder: (BuildContext context){
                              return seperateImageOptions(i);
                            }
                          );
                        },
                        child: const Icon(
                          Icons.photo_library_rounded,
                          size: 15
                        )
                      ),
                      Text(widget.scene.loadedObjects[i].startingLayer.toString())
                    ],)
                  ):Container(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        widget.scene.loadedObjects[i].type == LoadedType.single?InkWell(
                          onTap: (){
                            LoadedObject lo =  widget.scene.loadedObjects[i];
                            double width = lo.size.width;
                            double height = lo.size.height;
                            double ratio = width/height;
                            double scale = lo.objectScale.isEmpty?1.0:lo.objectScale[0];
                            Size size = Size(100,100/ratio)*scale;
                            double off = lo.offsetHeight.toDouble();
                            Rect updateRect = Rect.fromLTWH(
                              0, 
                              0, 
                              width, 
                              height
                            );

                            if(lo.type == LoadedType.single){
                              widget.scene.addObject(
                                createObject(
                                  type: SelectedType.image, 
                                  size: size,
                                  name: lo.spriteNames == null?'Object':lo.spriteNames![0], 
                                  layer: lo.startingLayer, 
                                  imageLocation: i, 
                                  color: Colors.white, 
                                  textcoords: [
                                    Offset(updateRect.left,updateRect.top+off),
                                    Offset(updateRect.right,updateRect.top+off),
                                    Offset(updateRect.right,updateRect.bottom+off),
                                    Offset(updateRect.left,updateRect.bottom+off)
                                  ], 
                                  textureRect: updateRect, 
                                )
                              );
                            }
                            else{
                              widget.scene.addObject(
                                widget.scene.loadedObjects[i].object!
                              );
                            }
                          },
                          child: const Icon(Icons.add_circle_outline,size:15),
                        ):Container(height:0),
                        InkWell(
                          onTap: (){
                            setState(() {
                              widget.scene.removeLoadedObject(i);
                              selected = null;
                            });
                          },
                          child: const Icon(Icons.delete,size: 15,),
                        )
                    ],)
                  )
                ],)
              )
            )
          );
          }
        }
    }

    widgets.add(Container(width: widget.width/3-10,));
    widgets.add(Container(width: widget.width/3-10,));
    return Column(children: [
      SizedBox(
        height: 36,
        width: 300,
        //margin: EdgeInsets.fromLTRB(5,0,5,0),
        child: GestureDetector(
          onHorizontalDragUpdate: (dragUpdateDetails){
            double pos = setObjectController.offset-dragUpdateDetails.delta.dx;
            setObjectController.jumpTo(pos);
          },
          child: ListView(
            scrollDirection: Axis.horizontal,
            controller: setObjectController,
            children: selections,
          )
        )
      ),
      SizedBox(
        height: tileScene.camera.viewportHeight-30,
        child: ListView(
          children: [
            Wrap(alignment: WrapAlignment.spaceAround,children:widgets)
          ],
        )
      ),
      selected != null?Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
            Column(children: [
              MouseRegion(
                onEnter: (PointerEvent details){
                  setState(() {
                    highLight.openMenu('Bring Foward',_key[5]);
                  });
                },
                onExit: (PointerEvent details){
                  setState(() {
                    highLight.closeMenu();
                  });
                },
                child: InkWell(
                  key: _key[5],
                  onTap:(){
                    widget.scene.loadedObjects[selected!].startingLayer++;
                    setState(() {});
                  },
                  child: const Icon(Icons.add,size: 10,)
                ),
              ),
              MouseRegion(
                onEnter: (PointerEvent details){
                  setState(() {
                    highLight.openMenu('Send Back',_key[6]);
                  });
                },
                onExit: (PointerEvent details){
                  setState(() {
                    highLight.closeMenu();
                  });
                },
                child: InkWell(
                  key: _key[6],
                  onTap:(){
                    widget.scene.loadedObjects[selected!].startingLayer--;
                    setState(() {});
                  },
                  child: const Icon(Icons.remove,size: 10,)
                ),
              )
            ],),
            MouseRegion(
              onEnter: (PointerEvent details){
                setState(() {
                  highLight.openMenu('Object Type',_key[7]);
                });
              },
              onExit: (PointerEvent details){
                setState(() {
                  highLight.closeMenu();
                });
              },
              child:Container(
                key: _key[7],
                alignment: Alignment.center,
                height:20,
                padding: const EdgeInsets.only(left:10),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    elevation: 0,
                    dropdownColor: Theme.of(context).canvasColor,
                    isExpanded: false,
                    items: objectDropDown,
                    value: selectedDropDown,//ddInfo[i],
                    focusColor: Colors.blue,
                    onChanged: (val){
                      setState(() {
                        if(val != null){
                          widget.scene.loadedObjects[selected!].objectType = ObjectType.values[_getObjectType(val as String)];
                          selectedDropDown = val ;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ],),
          widget.scene.loadedObjects[selected!].type == LoadedType.single?Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            EnterTextFormField(
              //formatter: [FilteringTextInputFormatter.digitsOnly],
              label: 'Object Name',
              width: 90,
              height: 25,
              maxLines: 1,
              color: Theme.of(context).canvasColor,
              onChanged: (val){
                  widget.scene.loadedObjects[selected!].spriteNames = [val];
              },
              onEditingComplete: (){},
              onSubmitted: (val){},
              onTap: (){},
              margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
              //padding: EdgeInsets.all(7),
              controller: controller[3],
            ),
            Row(children: [
              const Text('Scale:   '),
              EnterTextFormField(
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9_\.]'))],
                //label: 'Object Name',
                width: 40,
                height: 25,
                maxLines: 1,
                color: Theme.of(context).canvasColor,
                onChanged: (val){
                  if(val != ''){
                    widget.scene.loadedObjects[selected!].objectScale = [double.parse(val)];
                  }
                },
                onEditingComplete: (){},
                onSubmitted: (val){},
                onTap: (){},
                margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                padding: const EdgeInsets.all(5),
                controller: controller[5],
              )
            ],)
          ],):Container(height:0),
        ],),
      ):Container(height:0.0),
    ],);
  }

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;
    
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(widget.update){
        widget.scene.update();
        tileScene.tileSets = widget.scene.tileSets;
        tileScene.allTileImage = widget.scene.allTileImage;
        setState(() {});
        if(widget.callback != null){
          widget.callback!(call: LSICallbacks.updateLevel);
        }
      }
    });
    return SizedBox(
      child: Column(children: [
        widget.scene.levelImage != null?Container(
          width: widget.width,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            boxShadow: [BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 5,
              offset: const Offset(2,2),
            ),]
          ),
          child: Container(
            //color: Colors.red,
            padding: const EdgeInsets.only(left: 7.5,right:7.5),
            width: widget.width-15,
            alignment: Alignment.topLeft,
            child: CustomPaint(
              painter: _MiniMapPainter(widget.scene.levelImage!),
              size: Size(widget.width-15, _getMiniMapHeight()),
              isComplex: true,
            )
          )
        ):Container(height:0),
        widget.scene.allTileImage != null?Container(
          margin: const EdgeInsets.only(top: 10),
          width: widget.width,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            boxShadow: [BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 5,
              offset: const Offset(2,2),
            ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
            setTileSets(),
            RawKeyboardListener(
              focusNode: _focusNode,
              onKey: (key){
                tileScene.isControlPressed = key.isControlPressed;
              },
              child: Listener(
                onPointerDown: (details){
                  selectedAnimation = null;
                  FocusScope.of(context).requestFocus(_focusNode);
                  tileScene.updateTapLocation(details.localPosition-const Offset(0, 0));
                },
                onPointerUp: (details){
                  widget.scene.selectedTile = tileScene.tileTappedOn;
                },
                onPointerHover: (details){
                  tileScene.updateHoverLocation(details.localPosition-const Offset(0, 0));
                },
                child: tilePaint()
              )
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(5,0,5,10),
              child: tileAnimations()
            ),
            tileModifers()
          ]),
        ):Container(height:0),
        (widget.scene.loadedObjects.isNotEmpty)?Container(
          margin: const EdgeInsets.only(top: 10),
          height: tileScene.camera.viewportHeight+36+(selected != null && widget.scene.loadedObjects[selected!].type == LoadedType.single?30:0),
          width: widget.width,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            boxShadow: [BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 5,
              offset: const Offset(2,2),
            ),]
          ),
          child: InkWell(
            mouseCursor: MouseCursor.defer,
            onTap: (){
              setState(() {
                selected = null;
              });
            },
            child:objects(),
          ),
        ):Container(height:0),
        (selected != null && widget.scene.loadedObjects.isNotEmpty && widget.scene.loadedObjects[selected!].spriteLocations.isNotEmpty)?Container(
          margin: const EdgeInsets.only(top: 10),
          height: tileScene.camera.viewportHeight,
          width: widget.width,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            boxShadow: [BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 5,
              offset: const Offset(2,2),
            ),]
          ),
          child: sheetObjects(),
        ):Container(height:0),
        Container(
          margin: const EdgeInsets.only(top: 10),
          height: 360,
          width: widget.width,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            boxShadow: [BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 5,
              offset: const Offset(2,2),
            ),]
          ),
          child: sheetInfo(),
        ),
      ])
    );
  }
}

class _TilesetPainter extends CustomPainter {
  final TileScene _scene;
  const _TilesetPainter(this._scene);

  @override
  void paint(Canvas canvas, Size size) {
    _scene.render(canvas, size);
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(_TilesetPainter oldDelegate) {
    return true;
  }
}
class _MiniMapPainter extends CustomPainter {
  _MiniMapPainter(this._image);
  final Image? _image;
  @override
  void paint(Canvas canvas, Size size) {
    if(_image != null){
      paintImage(
        canvas: canvas, 
        rect: Rect.fromLTWH(0, 0, size.width, size.height), 
        image: _image!,
        fit: BoxFit.fitWidth,
      );
    }
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(_MiniMapPainter oldDelegate) {
    return true;
  }
}

class SpritePainter extends CustomPainter {
  Image sprite;
  Rect src;
  Rect dst;

  SpritePainter({
    required this.sprite,
    required this.src,
    required this.dst
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(sprite, src, dst, Paint()..color = Colors.green);
  }
  @override
  bool shouldRepaint(SpritePainter oldDelegate){
    return true;
  }
}