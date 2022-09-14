//Original algorithm by J. Dunlap queuelinearfloodfill.aspx
//Java port by Owen Kaluza
//Android port by Darrin Smith (Standard Android)
//Flutter port by Garlen Javier
import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import '../editors/editors.dart';
import 'package:vector_math/vector_math_64.dart' hide Triangle, Vector4, Colors;
import '../levelEditor/levelEditor.dart';

class QueueLinearFloodFiller {

  QueueLinearFloodFiller(
    this.tiles, 
    this.allTiles,
    this.selected,
    Size size,
    this.boxSize,
    this.camera
  ) {
    _width = size.width.toInt();
    _height = size.height.toInt();
  }

  TileRects tiles;
  List<TileRects> allTiles;
  Camera camera;
  late int _width = 0;
  late int _height = 0;
  Size boxSize;
  SelectedTile selected;
  
  late List<bool> _pixelsChecked;
  late Queue<_FloodFillRange> _ranges;
  void setTile(int x, int y){
    int pxIdx = (_width * y) + x;
    Vector3 newPosition = Converter.toVector3(camera.position,Offset(x*boxSize.width,y*boxSize.height));
    newPosition.applyMatrix4(camera.lookAtMatrix);
    final Rect rect = Rect.fromLTWH(
      newPosition.x+newPosition.x*(camera.zoom-1), 
      newPosition.y+newPosition.y*(camera.zoom-1), 
      boxSize.width*(camera.zoom),
      boxSize.height*(camera.zoom)
    );
    allTiles[pxIdx] = TileRects(
      isAnimation: selected.isAnimation,
      position: [x,y],
      tileSet: selected.tileSet!,
      rect: selected.rect!,
      transform: RSTransform.fromComponents(rotation: 0, scale: camera.zoom, anchorX: 0, anchorY: 0, translateX: rect.left, translateY: rect.top)
    );
  }
  void _prepare() {
    // Called before starting flood-fill
    _pixelsChecked = List<bool>.filled(_width * _height, false);
    _ranges = Queue<_FloodFillRange>();
  }
  // Fills the specified point on the bitmap with the currently selected fill
  // color.
  // int x, int y: The starting coords for the fill
  Future<void> floodFill(int x, int y) async {
    // Setup
    _prepare();
    // ***Do first call to floodfill.
    _linearFill(x, y);
    // ***Call floodfill routine while floodfill _ranges still exist on the
    // queue
    _FloodFillRange range;
    while (_ranges.length > 0) {
      // **Get Next Range Off the Queue
      range = _ranges.removeFirst();
      // **Check Above and Below Each Pixel in the Floodfill Range
      int downPxIdx = (_width * (range.y + 1)) + range.startX;
      int upPxIdx = (_width * (range.y - 1)) + range.startX;
      int upY = range.y - 1; // so we can pass the y coord by ref
      int downY = range.y + 1;
      for (int i = range.startX; i <= range.endX; i++) {
        // *Start Fill Upwards
        // if we're not above the top of the bitmap and the pixel above
        // this one is within the color tolerance
        if (range.y > 0 && (!_pixelsChecked[upPxIdx]) && _checkPixel(i, upY)) {
          _linearFill(i, upY);
        }
        // *Start Fill Downwards
        // if we're not below the bottom of the bitmap and the pixel
        // below this one is within the color tolerance
        if (range.y < (_height - 1) &&
            (!_pixelsChecked[downPxIdx]) &&
            _checkPixel(i, downY)) {
          _linearFill(i, downY);
        }
        downPxIdx++;
        upPxIdx++;
      }
    }
  }
  // Finds the furthermost left and right boundaries of the fill area
  // on a given y coordinate, starting from a given x coordinate, filling as
  // it goes.
  // Adds the resulting horizontal range to the queue of floodfill _ranges,
  // to be processed in the main loop.
  //
  // int x, int y: The starting coords
  void _linearFill(int x, int y) {
    // ***Find Left Edge of Color Area
    int lFillLoc = x; // the location to check/fill on the left
    int pxIdx = (_width * y) + x;
    while (true) {
      // **fill with the color
      //pixels[pxIdx] = _fillColor;
      setTile(lFillLoc, y);
      // **indicate that this pixel has already been checked and filled
      _pixelsChecked[pxIdx] = true;
      // **de-increment
      lFillLoc--; // de-increment counter
      pxIdx--; // de-increment pixel index
      // **exit loop if we're at edge of bitmap or color area
      if (lFillLoc < 0 ||
          (_pixelsChecked[pxIdx]) ||
          !_checkPixel(lFillLoc, y)) {
        break;
      }
    }
    lFillLoc++;
    // ***Find Right Edge of Color Area
    int rFillLoc = x; // the location to check/fill on the left
    pxIdx = (_width * y) + x;
    while (true) {
      // **fill with the color
      setTile(rFillLoc, y);
      // **indicate that this pixel has already been checked and filled
      _pixelsChecked[pxIdx] = true;
      // **increment
      rFillLoc++; // increment counter
      pxIdx++; // increment pixel index
      // **exit loop if we're at edge of bitmap or color area
      if (rFillLoc >= _width ||
          _pixelsChecked[pxIdx] ||
          !_checkPixel(rFillLoc, y)) {
        break;
      }
    }
    rFillLoc--;
    // add range to queue
    _FloodFillRange r = new _FloodFillRange(lFillLoc, rFillLoc, y);
    _ranges.add(r);
  }
  // Sees if a pixel is within the color tolerance range.
  bool _checkPixel(int x, int y) {
    int i = x+y*_width;
    return tiles.rect == allTiles[i].rect;
  }
}
// Represents a linear range to be filled and branched from.
class _FloodFillRange {
  int startX;
  int endX;
  int y;
  _FloodFillRange(this.startX, this.endX, this.y);
}