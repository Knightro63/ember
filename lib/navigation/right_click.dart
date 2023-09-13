import 'package:flutter/material.dart';

enum RightClickOptions{
  addAnimation,
  removeAnimation,
  addFrame,
  removeFrame,
  cutoutArea,
  copyArea,
  removeArea,
  addCollision,
  addObject,
  remove,
  clearTile,
  bringToFront,
  sendToBack,
  editName,
  changeColor,
  flipHorizontal,
  flipVertical,
  copy,
  paste,
  cut,
  none
}

class RightClick{
  RightClick({
    required BuildContext context,
    double width = 150,
    TextStyle? style,
    required this.onTap,
  }){
    _context = context;
    _style = style ?? const TextStyle(fontSize: 10);
    _width = width;
  }

  List<RightClickOptions>? acceptedOptions;
  late BuildContext _context;
  late String text;
  late double _width;
  late TextStyle _style;
  late OverlayEntry _overlayEntry;
  late Offset _offset;
  bool isMenuOpen = false;
  List<RightClickOptions> _showOptions = [RightClickOptions.none];
  void Function(RightClickOptions call) onTap;

  OverlayEntry _overlayEntryBuilder() {
    return OverlayEntry(
      builder: (context) {
        context = _context;
        return Positioned(
          top: _offset.dy,
          left: _offset.dx,
          width: _width,
          //height: 30,
          child: OverlayClass(
            theme: Theme.of(_context),
            style: _style,
            width: _width,
            function: onTap,
            show: _showOptions,
          )
        );
      },
    );
  }

  void dispose(){
    closeMenu();
  }

  void closeMenu(){
    if(isMenuOpen){
      _overlayEntry.remove();
      isMenuOpen = !isMenuOpen;
    }
  }

  void openMenu(String text,Offset offset, List<RightClickOptions> showOptions){
    if(isMenuOpen){
      closeMenu();
    }
    _offset = offset;
    _showOptions = showOptions;
    text = text;
    _overlayEntry = _overlayEntryBuilder();
    Overlay.of(_context).insert(_overlayEntry);
    isMenuOpen = !isMenuOpen;
  }
}

class OverlayClass extends StatefulWidget {
  OverlayClass({
    required this.style,
    required this.width,
    required this.theme,
    required this.function,
    required this.show,
  });

  final ThemeData theme;
  final TextStyle style;
  final double width;
  final Function(RightClickOptions call) function;
  final List<RightClickOptions> show;

  @override
  _OverlayClassState createState() => _OverlayClassState();
}
class _OverlayClassState extends State<OverlayClass> {
  RightClickOptions? hoverdOn;

  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose(){
    super.dispose();
  }

  String commands(RightClickOptions option){
    switch (option) {
      case RightClickOptions.cut:
        return 'Ctrl+X';
      case RightClickOptions.copy:
        return 'Ctrl+C';
      case RightClickOptions.paste:
        return 'Ctrl+V';
      default:
        return '';
    }
  }

  Widget button(RightClickOptions option){
    return InkWell(
      onHover: (hover){
        if(hover){
          hoverdOn = option;
        }
        else{
          hoverdOn = null;
        }
        setState(() {});
      },
      onTap: (){
        widget.function(option);
      },
      child: Container(
        color: hoverdOn == option?Colors.blue[900]:Colors.transparent,
        padding: const EdgeInsets.only(left:10,right:10),
        height: 25,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              option.toString().replaceAll('RightClickOptions.', '').replaceAll('_', ' ').toUpperCase(),
              style: widget.style
            ),
            Text(
              commands(option),
              style: widget.style
            ),
        ],),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = [];

    if(widget.show[0] != RightClickOptions.none){
      for(int i = 0; i < widget.show.length; i++){
        buttons.add(button(widget.show[i]));
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(top: 5),
        alignment: Alignment.center,
        //height: 30,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [BoxShadow(
            color: widget.theme.shadowColor,
            blurRadius: 5,
            offset: const Offset(2,3),
          ),]
        ),
        child: Column(
          children: buttons
        )
      )
    );
  }
}