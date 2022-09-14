import 'package:flutter/material.dart';

class TextEdit{
  TextEdit({
    required this.context,
    this.width = 120,
    this.onEditingComplete
  });

  BuildContext context;
  Offset position = const Offset(0,0);
  double width;
  OverlayEntry? _overlayEntry;
  bool isOpen = false;
  late String itemName;
  void Function(String)? onEditingComplete;

  OverlayEntry _overlayEntryBuilder() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          top: position.dy,
          left: position.dx,
          height: 30,
          child: OverlayClass(
            theme: Theme.of(context),
            width: width,
            onEditingComplete: onEditingComplete,
            itemName: itemName,
          )
        );
      },
    );
  }

  void close(){
    if(isOpen && _overlayEntry != null){
      _overlayEntry!.remove();
      isOpen = !isOpen;
    }
  }

  void open(Offset offset,String name){
    if(!isOpen){
      itemName = name;
      position = offset;
      _overlayEntry = _overlayEntryBuilder();
      Overlay.of(context)!.insert(_overlayEntry!);
      isOpen = !isOpen;
    }
  }
}

class OverlayClass extends StatefulWidget {
  const OverlayClass({
    Key? key,
    required this.width,
    required this.theme,
    required this.onEditingComplete,
    required this.itemName,
  }):super(key: key);

  final ThemeData theme;
  final double width;
  final String itemName;
  final void Function(String)? onEditingComplete;

  @override
  _OverlayClassState createState() => _OverlayClassState();
}
class _OverlayClassState extends State<OverlayClass> {
  TextEditingController controller = TextEditingController();
  
  @override
  void initState() {
    controller.text =  widget.itemName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(top: 5,right: 5,left: 5),
        alignment: Alignment.center,
        height: 50,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [BoxShadow(
            color: widget.theme.shadowColor,
            blurRadius: 5,
            offset: const Offset(2,2),
          ),]
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          width: 200,
          height: 45,
          alignment: Alignment.center,
          child: TextField(
            maxLines: 1,
            onChanged: widget.onEditingComplete,
            onEditingComplete: (){
              
            },
            onSubmitted: widget.onEditingComplete,
            onTap: (){

            },
            controller: controller,
            style: Theme.of(context).primaryTextTheme.bodyText2,
            decoration: InputDecoration(
              isDense: true,
              //labelText: label,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                borderSide: BorderSide(
                    width: 0, 
                    style: BorderStyle.none,
                ),
              ),
            ),
          )
        )
      )
    );
  }
}