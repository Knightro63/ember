import 'dart:ui';
import 'package:flutter/material.dart' hide Image;

import 'package:ember/ember.dart';
import '../src/styles/globals.dart';
import '../src/styles/widgets.dart';
import '../src/navigation/highlight.dart';

enum CreatObjects{collision,object}

class LevelModifers extends StatefulWidget{
  const LevelModifers({
    Key? key,
    required this.scene,
    this.height,
    this.width = 100,
    this.update = true,
    this.callback
  }):super(key: key);

  final LevelScene scene;
  final double? height;
  final double width;
  final bool update;
  final Function({required LSICallbacks call})? callback;

  @override
  _LevelModifersState createState() => _LevelModifersState();
}

class _LevelModifersState extends State<LevelModifers>{
  String _brush = 'BrushStyles.move';
  double height = 0;
  String hovering = '';
  int? selected;
  late HighLight highLight;
  List<TextEditingController> controller = [];
  List<GlobalKey> key = [];

  @override
  void initState() {
    for(int i = 0; i < widget.scene.levelInfo.length;i++){
      controller.add(TextEditingController());
      controller[i].text = widget.scene.levelInfo[i].name;
    }
    for(int i = 0; i < BrushStyles.values.length+CreatObjects.values.length;i++){
      if(i < BrushStyles.values.length){
        key.add(
          LabeledGlobalKey(BrushStyles.values[i].toString())
        );
      }
      else{
        key.add(
          LabeledGlobalKey(CreatObjects.values[i-(BrushStyles.values.length)].toString())
        );
      }
    }
    key.add(LabeledGlobalKey('Save'));
    height = (widget.height==null)? 50:widget.height!;
    highLight = HighLight(context: context);
    super.initState();
  }
  @override
  void dispose() {
    highLight.closeMenu();
    super.dispose();
  }

  void nameChange(int i){
    widget.scene.levelInfo[i].name = controller[i].text;
  }

  Widget snapButton(String brush, IconData icon,GlobalKey key,[Function? function]){
    return InkWell(
        onTap: (){
          setState(() {
            if(brush.contains('BrushStyles')){
              _brush = brush;
            }
          });
          if(function != null){
            function();
          }
        },
        child: MouseRegion(
          onEnter: (details){
            highLight.openMenu(brush.split('.')[1].toUpperCase(),key);
          },
          onExit: (details){
            highLight.closeMenu();
          },
          child: Container(
            margin: const EdgeInsets.only(left:2,right:2),
            child: Icon(
              icon,
              key: key,
              size: 15,
              color: _brush == brush? Theme.of(context).secondaryHeaderColor:null,
            ),
          )
      )
    );
  }
  Widget tabs(){
    List<Widget> widgets = [];
    for(int i = 0; i < widget.scene.levelInfo.length;i++){
      if(controller.length < widget.scene.levelInfo.length){
        controller.add(TextEditingController());
        controller[controller.length-1].text = widget.scene.levelInfo[controller.length-1].name;
      }
      widgets.add(
        InkWell(
          onTap: (){
            //widget.onTap();
            widget.scene.selectedLevel = i;
            widget.scene.update();
          },
          child: MouseRegion(
            onEnter: (PointerEvent details){
              setState(() {
                hovering = i.toString();
              });
            },
            onExit: (PointerEvent details){
              setState(() {
                hovering = '';
              });
            },
            onHover: (val){
              //widget.onHover();
            },
            child: Container(
              height: 25,
              alignment: Alignment.bottomCenter,
              margin: const EdgeInsets.fromLTRB(5, 5, 0, 0),
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              decoration: BoxDecoration(
                color: (hovering != i.toString() && widget.scene.selectedLevel != i)?Theme.of(context).cardColor:Theme.of(context).secondaryHeaderColor,
                borderRadius: const BorderRadius.only(topLeft:Radius.circular(5),topRight:Radius.circular(5)),
                //border: border
              ),
              child:Row(children: [
                EnterTextFormField(
                  label: 'Level Name',
                  width: 80,
                  height: 25,
                  maxLines: 1,
                  color: (hovering != i.toString() && widget.scene.selectedLevel != i)?Theme.of(context).cardColor:Theme.of(context).secondaryHeaderColor,
                  onChanged: (val){
                    if(val != ''){
                      nameChange(i);
                      widget.scene.update();
                    }
                  },
                  onEditingComplete: (){
                    
                  },
                  onSubmitted: (val){
                    nameChange(i);
                    widget.scene.update();
                  },
                  onTap: (){

                  },
                  controller: controller[i]..selection = TextSelection.fromPosition(TextPosition(offset: controller[i].text.length)),
                ),
                InkWell(
                  onTap: (){
                    widget.scene.removeLevel(i);
                    if(controller.length == 1){
                      controller[i].text = widget.scene.levelInfo[i].name;
                    }
                    else{
                      controller.removeAt(i);
                    }
                  },
                  child: const Icon(Icons.delete,size:15),
                )
              ],)
            ),
          )
        )
      );
    }

    widgets.add(
      InkWell(
        onTap: (){
          widget.scene.addLevel();
          if(controller.length < widget.scene.levelInfo.length){
            controller.add(TextEditingController());
            controller[controller.length-1].text = widget.scene.levelInfo[controller.length-1].name;
          }
          else{
            for(int i = controller.length-1; i > widget.scene.levelInfo.length;i--){
              controller.removeAt(i);
            }
          }
        },
        child: MouseRegion(
          onEnter: (PointerEvent details){
            setState(() {
              hovering = 'add';
            });
          },
          onExit: (PointerEvent details){
            setState(() {
              hovering = '';
            });
          },
          onHover: (val){
            //widget.onHover();
          },
          child: Container(
            height: 25,
            alignment: Alignment.bottomCenter,
            margin: const EdgeInsets.fromLTRB(5, 5, 0, 0),
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: BoxDecoration(
              color: (hovering != 'add')?Colors.white.withAlpha(50):Theme.of(context).secondaryHeaderColor,
              borderRadius: const BorderRadius.only(topLeft:Radius.circular(5),topRight:Radius.circular(5)),
              //border: border
            ),
            child:const Icon(Icons.add,size:20),
          ),
        )
      )
    );
    return Row(children: widgets,);
  }
  Widget tilePaint(){
    List<Widget> widgets = [];
    IconData getIcon(BrushStyles style){
      switch (style) {
        case BrushStyles.erase:
          return Icons.remove_circle_outline_sharp;
        case BrushStyles.fill:
          return Icons.format_color_fill_outlined;
        case BrushStyles.stamp:
          return Icons.format_paint;
        default:
          return Icons.control_camera;
      }
    }
    for(int i = 0; i < BrushStyles.values.length;i++){
      widgets.add(
        snapButton(
          BrushStyles.values[i].toString(),
          getIcon(BrushStyles.values[i]),
          key[i],
          (){
            widget.scene.brushStyle = BrushStyles.values[i];
            widget.scene.tapLocation = null;
          }
        )
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: widgets,
    );
  }
  Widget objectCreate(){
    List<Widget> widgets = [];
    List<Function> function = [
      (){
        widget.scene.addObject(Object(
          color: Colors.green.withAlpha(180),
          type: SelectedType.collision,
          size: const Size(50,5),
        ));
      },
      (){
        widget.scene.addObject(Object(
          type: SelectedType.object
        ));
      }
    ];
    IconData getIcon(CreatObjects style){
      switch (style) {
        case CreatObjects.collision:
          return Icons.add_alert_outlined;
        case CreatObjects.object:
          return Icons.add_box;
        default:
        return Icons.cancel;
      }
    }
    for(int i = 0; i < CreatObjects.values.length;i++){
      widgets.add(
        snapButton(
          CreatObjects.values[i].toString(),
          getIcon(CreatObjects.values[i]),
          key[i+BrushStyles.values.length],
          function[i]
        )
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: widgets,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      color: Theme.of(context).canvasColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            tilePaint(),
            Container(margin:const EdgeInsets.only(left:5,right:5),width: 2,height: 36,color: Colors.white,),
            objectCreate(),
            Container(margin:const EdgeInsets.only(left:5,right:5),width: 2,height: 36,color: Colors.white,),
            snapButton(
              '.Save',
              Icons.save,
              key.last,
              ()async{
                await LevelExporter.export(widget.scene);
              }
            ),
            Container(margin:const EdgeInsets.only(left:5,right:5),width: 2,height: 36,color: Colors.white,),
          ],),
          tabs()
      ],)
    );
  }
}

class ImagePainter extends CustomPainter {
  Image image;
  double width;
  double height;
  Offset offset;

  ImagePainter({
    required this.image,
    required this.width,
    required this.height,
    required this.offset
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(canvas: canvas, rect: Rect.fromLTWH(offset.dx, offset.dy, width, height), image: image);
  }
  @override
  bool shouldRepaint(ImagePainter oldDelegate){
    return true;
  }
}