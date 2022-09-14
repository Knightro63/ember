import 'dart:ui';
import 'package:flutter/material.dart' hide Image, Material;
import '../levelEditor.dart';
import 'package:vector_math/vector_math_64.dart' hide Triangle, Colors;
import 'dart:typed_data';
import '../../editors/editors.dart';
import 'light.dart';

enum RenderType{Wireframe,Normal}
enum SortingType{Painters,HSR}

typedef ObjectCreatedCallback = void Function(Object object);

class RotateRect{
  RotateRect({
    required double angle,
    required this.off,
    required this.rect
  }){
    _angle = angle; 
  }

  late double _angle;
  double get angle => _angle/57.3;
  double off;
  Rect rect;
  double get cx => rect.left+off;
  double get cy => rect.top+(off > 0?off:(off*-1));
}

class ModelRender extends LevelEditor{

  ModelRender(
    LevelScene scene
  ):super(
    scene: scene
  );

  Light light = Light();
  BlendMode blendMode = BlendMode.srcOver;
  BlendMode textureBlendMode = BlendMode.srcOver;
  int vertexCount = 0;
  int faceCount = 0;

  SortingType sortingType = SortingType.HSR;

  // calcuthe total number of vertices and facese
  void _calculateVertices(Object o) {
    for (int i = 0; i < o.mesh.length; i++){
      vertexCount += o.mesh[i].vertices.length;
      faceCount += o.mesh[i].indices.length;
    }
  }
  
  RenderMesh _makeRenderMesh(List<Object> objects, Image? texture){
    vertexCount = 0;
    faceCount = 0;
    for(int i = 0; i < objects.length;i++){
      _calculateVertices(objects[i]);
    }
    final renderMesh = RenderMesh(vertexCount, faceCount);
    renderMesh.texture = texture;
    return renderMesh;
  }
  double _areaOfTriangle(List<double> x,List<double> y){
    return 1/2*((x[1] - x[0]) * (y[2] - y[0]) - (x[2] - x[0]) * (y[1] - y[0]));
  }
  void _selectCheck(
    int i,
    List<double> x,
    List<double> y,
  ){
    final Offset v = Offset(scene.camera.viewportWidth,scene.camera.viewportHeight);
    final double area = _areaOfTriangle(x,y).abs();
    bool isAllowed = false;
    bool isDifferent = true;

    if(scene.objectTappedOn.isNotEmpty && scene.isControlPressed || scene.objectTappedOn.isEmpty){
      isAllowed = true;
    }

    if(scene.objectTappedOn.isNotEmpty && scene.isControlPressed){
      for(int k = 0; k < scene.objectTappedOn.length;k++){
        if(scene.objectTappedOn[k].objectLocation == i){
          isDifferent = false;
          break;
        }
      }
    }
    if(scene.tapLocation != null && _isBelow(scene.tapLocation!, x, y, v) && scene.brushStyle == BrushStyles.move){
      scene.isClicked = true;
      if(scene.currentSize == null){
        scene.currentSize = area;
        scene.objectTappedOn.add(SelectedObjects(objectLocation: i, toColor: i));
        scene.updateMinMap = true;
      }
      else if(isAllowed && isDifferent){
        scene.objectTappedOn.add(SelectedObjects(objectLocation: i, toColor: i));
      }
      else if(scene.currentSize! > area || isAllowed){
        scene.currentSize = area;
        if(scene.objectTappedOn.length == 1 && !isAllowed){
          scene.objectTappedOn[0] = SelectedObjects(objectLocation: i, toColor: i);
        }
      }
      else if(isAllowed && isDifferent){
        scene.objectTappedOn.add(SelectedObjects(objectLocation: i, toColor: i));
      }
    }
    if(scene.hoverLocation != null && _isBelow(scene.hoverLocation!, x, y, v)){
      scene.objectHoveringOn = SelectedObjects(objectLocation: i,toColor: i);
    }
  }
  bool _isBackFace(List<double> x, List<double> y) {
    double area = (x[1] - x[0]) * (y[2] - y[0]) - (x[2] - x[0]) * (y[1] - y[0]);
    return area <= 0;
  }
  bool _isClippedFace(List<double> x, List<double> y, List<double> z) {
    // clip if at least one vertex is outside the near and far plane
    if (z[0] < 0 || z[0] > 1 || z[1] < 0 || z[1] > 1 || z[2] < 0 || z[2] > 1) return true;
    // clip if the face's bounding box does not intersect the viewport
    double left;
    double right;
    if (x[0] < x[1]) {
      left = x[0];
      right = x[1];
    } 
    else {
      left = x[1];
      right = x[0];
    }
    if (left > x[2]) left = x[2];
    if (left > 1) return true;
    if (right < x[2]) right = x[2];
    if (right < -1) return true;
    
    double top;
    double bottom;
    if (y[0] < y[1]) {
      top = y[0];
      bottom = y[1];
    } 
    else {
      top = y[1];
      bottom = y[0];
    }
    if (top > y[2]) top = y[2];
    if (top > 1) return true;
    if (bottom < y[2]) bottom = y[2];
    if (bottom < -1) return true;
    return false;
  }
  bool _isBelow(Offset p, List<double> x, List<double> y,Offset v){
    double sign (double hx, double hy, double ix, double iy, double kx, double ky){
      return (hx - kx) * (iy - ky) - (ix - kx) * (hy - ky);
    }
    double d1, d2, d3;
    bool hasNeg, hasPos;

    d1 = sign(p.dx, p.dy ,((1.0+x[0])*v.dx/2), ((1.0-y[0])*v.dy/2), ((1.0+x[1])*v.dx/2), ((1.0-y[1])*v.dy/2));
    d2 = sign(p.dx, p.dy, ((1.0+x[1])*v.dx/2), ((1.0-y[1])*v.dy/2), ((1.0+x[2])*v.dx/2), ((1.0-y[2])*v.dy/2));
    d3 = sign(p.dx, p.dy, ((1.0+x[2])*v.dx/2), ((1.0-y[2])*v.dy/2), ((1.0+x[0])*v.dx/2), ((1.0-y[0])*v.dy/2));

    hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return !(hasNeg && hasPos);
  }
  int _paintersAlgorithm(Triangle? a, Triangle? b){
    //return b.sumOfZ.compareTo(a.sumOfZ);
    if(a == null) return -1;
    if(b == null) return -1;
    final double az = a.z;
    final double bz = b.z;
    //return (az-bz).round();
    if (bz > az) return 1;
    if (bz < az) return -1;
    return 0;
  }
  Float64List storage(Vector3 vertices, Matrix4 transform){
    final toDraw = Vector3.copy(vertices);
    
    transform.transform3(toDraw);
    toDraw.scale(scene.camera.zoom);
    return toDraw.storage;
  }

  List<Triangle> _getTriangles(RenderMesh renderMesh, Object o, int mesh, int currentObject) {
    if (!o.visible) return [];
    final Matrix4 model = o.transform;
    List<Triangle> triangles = [];
    final Matrix4 transform = scene.camera.lookAtMatrix*model;

    // apply transform and add vertices to renderMesh
    final double viewportWidth = scene.camera.viewportWidth;
    final double viewportHeight = scene.camera.viewportHeight;

    final Float32List positions = renderMesh.positions;
    final Float32List positionsZ = renderMesh.positionsZ;

    final List<Vector3> vertices = o.mesh[mesh].vertices;
    final List<Vector3> normals = o.mesh[mesh].normals;

    final int vertexOffset = renderMesh.vertexCount;
    final int vertexCount = vertices.length;
    
    renderMesh.vertexCount += vertexCount;

    // add faces to renderMesh
    final List<Triangle> indices = o.mesh[mesh].indices;
    final int indexCount = indices.length;

    //color information
    final Int32List renderColors = renderMesh.colors;
    final Matrix4 normalTransform = (model.clone()..invert()).transposed();
    final Vector3 viewPosition = Vector3.copy(scene.camera.rotation);
    final Material material = o.mesh[mesh].material;
    final List<Color> colors = o.mesh[mesh].colors;

    //texture information
    final Float32List renderTexcoords = renderMesh.texcoords;
    final List<Offset>? texcoords = o.mesh[mesh].texcoords;

    for (int i = 0; i < indexCount; i++){
      final Triangle p = indices[i];
      final int colorValue = (p.texture != null) ? 
        const Color.fromARGB(0,0,0,0).value :o.color.value;
      
      List<int> vertexes = [];
      List<double> x = [];
      List<double> y = [];
      List<double> z = [];

      double sumOfZ = 0;

      for(int j = 0; j < p.vertexes.length;j++){
        final vertex = vertexOffset + p.vertexes[j];
        vertexes.add(vertex);
        
        Float64List storage4 = storage(vertices[p.vertexes[j]], transform);
        double posx =  storage4[0]/(viewportWidth / 2)-1.0;
        double posy =  -(storage4[1]/((viewportHeight) / 2)-1.0);
        positionsZ[vertex] = storage4[2]/(scene.camera.far/2)+0.1;

        x.add(posx);
        y.add(posy);
        z.add(positionsZ[vertex]);

        positions[vertex * 2] = storage4[0];
        positions[vertex * 2 + 1] = storage4[1];
        //sumOfZ += -o.layer-((o.type == SelectedType.Image || o.type == SelectedType.Atlas) && p.texture == null?10:0);
        sumOfZ -= o.layer;
        if((o.type == SelectedType.image || o.type == SelectedType.atlas)&& p.texture == null){
          sumOfZ -= 10;
        }

        if (colors.isEmpty){
          renderColors[vertex] = colorValue;
        }
        else {
          renderColors[vertex] = colors[i].value;
        }
        
        if(texcoords != null && p.texture != null) {
          final Offset t = texcoords[p.texture![j]];
          final double x = t.dx;
          final double y = t.dy;
          renderTexcoords[vertex * 2] = x;
          renderTexcoords[vertex * 2 + 1] = y;
        } 
        else {
          renderTexcoords[vertex * 2] = 0;
          renderTexcoords[vertex * 2 + 1] = 0;
        }
      }

      final bool isFF = _isBackFace(x, y);

      bool showFace = false;
      if(isFF){
        showFace = true;
      }
      if (!_isClippedFace(x,y,z)){
        triangles.add(Triangle(vertexes,null,null,sumOfZ,showFace));
        _selectCheck(currentObject, x, y);
      }
    }
    renderMesh.indexCount += indexCount;

    // render children
    final List<Mesh> children = o.mesh;
    for (int i = 1; i < children.length; i++){
      triangles += _getTriangles(renderMesh, o, i,currentObject);
    }

    return triangles;
  } 
  List<Triangle> _renderObject(RenderMesh renderMesh, List<Object> objects){
    List<Triangle> triangles = [];
    for(int i = 0; i < objects.length;i++){
      triangles += _getTriangles(renderMesh, objects[i],0,i);
    }
    return triangles;
  }
  
  void render(Canvas canvas, Size size){
    List<RotateRect> selected = [];
    super.scene.render(canvas, size);
    // create render mesh from objects
    final renderMesh = _makeRenderMesh(scene.levelInfo[scene.selectedLevel].objects,scene.allObjectImage);
    final List<Triangle> renderPolys = _renderObject(renderMesh,scene.levelInfo[scene.selectedLevel].objects);
    final int indexCount = renderPolys.length; 
    final Uint16List indices = Uint16List(indexCount * 3);

    // renderPolys.sort((Triangle a, Triangle b){
    //   return _paintersAlgorithm(a,b);
    // });

    for (int i = 0; i < indexCount; i++) {
      if(renderPolys[i] != null){
        final int index0 = i * 3;
        final int index1 = index0 + 1;
        final int index2 = index0 + 2;
        final Triangle triangle = renderPolys[i];

        indices[index0] = triangle.vertexes[0];
        indices[index1] = triangle.vertexes[1];
        indices[index2] = triangle.vertexes[2];
      }

      if(i < scene.objectTappedOn.length){
        int sel = scene.objectTappedOn[i].objectLocation;
        final Object obj = scene.levelInfo[scene.selectedLevel].objects[sel];
        final Vector3 newPosition = Vector3.copy(obj.position)+Vector3((obj.scale.x < 0?0.04:-0.04),(obj.scale.y > 0?0.04:-0.04),0);
        newPosition.applyMatrix4(scene.camera.lookAtMatrix);

        selected.add(
          RotateRect(
            angle: obj.rotation.z, 
            off: (obj.scale.x < 0?-8/2:8/2)*scene.camera.zoom,
            rect: Rect.fromLTWH(
              newPosition.x+newPosition.x*(scene.camera.zoom-1), 
              newPosition.y+newPosition.y*(scene.camera.zoom-1), 
              (obj.size.width*obj.scale.x*100+(obj.scale.x < 0?-8:8))*scene.camera.zoom, 
              (obj.size.height*obj.scale.y*100+(obj.scale.y > 0?8:-8))*scene.camera.zoom
            )
          )
        );
      }
    }

    final Rect totalRect = Rect.fromLTWH(0, 0, scene.camera.viewportWidth, scene.camera.viewportHeight);
    canvas.saveLayer(totalRect,Paint());

    _drwaVert(
      canvas,
      renderMesh.positions,
      renderMesh.texcoords,
      renderMesh.colors,
      indices,
      renderMesh.texture
    );

    if(selected.isNotEmpty){
      final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.blue
      ..strokeWidth = 2
      ..blendMode = BlendMode.srcOver;

      for(int i = 0; i < selected.length;i++){
        canvas.save();
        rotate(
          canvas,
          selected[i].cx,
          selected[i].cy,
          selected[i].angle
        );
        canvas.drawRect(selected[i].rect, paint);
        canvas.restore();
      }

    }
    canvas.restore();

    scene.tapLocation = null;
  }
  void rotate(Canvas canvas,double cx,double cy,double angle) {
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(-cx, -cy);
  }
  void _drwaVert(Canvas canvas, Float32List positions, Float32List texCoord,Int32List colors, Uint16List indices, Image? texture){
    final vertices = Vertices.raw(
      VertexMode.triangles,
      positions,
      textureCoordinates: texCoord,
      colors: colors,
      indices: indices,
    );

    final paint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.white
    ..strokeWidth = 1
    ..blendMode = BlendMode.srcOver;
    
    if (texture != null) {
      final matrix4 = Matrix4.identity().storage;
      final shader = ImageShader(texture, TileMode.clamp, TileMode.clamp, matrix4, filterQuality: FilterQuality.low);
      paint.shader = shader;
    }
    
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }
  void generateMap(Canvas canvas, Size size, List<Object> objects, Image? texture) async {
    final renderMesh = _makeRenderMesh(objects, texture);
    final List<Triangle> renderPolys = _renderObject(renderMesh,objects);
    final int indexCount = renderPolys.length;
    final Uint16List indices = Uint16List(indexCount * 3);

    for (int i = 0; i < indexCount; i++) {
      if(renderPolys[i] != null){
        final int index0 = i * 3;
        final int index1 = index0 + 1;
        final int index2 = index0 + 2;
        final Triangle triangle = renderPolys[i];

        indices[index0] = triangle.vertexes[0];
        indices[index1] = triangle.vertexes[1];
        indices[index2] = triangle.vertexes[2];
      }
    }
    _drwaVert(
      canvas, 
      renderMesh.positions, 
      renderMesh.texcoords,
      renderMesh.colors, 
      indices,
      renderMesh.texture
    );
  }
  Future<Image> generateImage(Size size, List<Object> objects, Image texture) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0,0,size.width, size.height)
    );
    // create render mesh from objects
    final renderMesh = _makeRenderMesh(objects, texture);
    final List<Triangle> renderPolys = _renderObject(renderMesh,objects);
    final int indexCount = renderPolys.length;
    final Uint16List indices = Uint16List(indexCount * 3);

    for (int i = 0; i < indexCount; i++) {
      if(renderPolys[i] != null){
        final int index0 = i * 3;
        final int index1 = index0 + 1;
        final int index2 = index0 + 2;
        final Triangle triangle = renderPolys[i];

        indices[index0] = triangle.vertexes[0];
        indices[index1] = triangle.vertexes[1];
        indices[index2] = triangle.vertexes[2];
      }
    }
    _drwaVert(
      canvas, 
      renderMesh.positions, 
      renderMesh.texcoords,
      renderMesh.colors, 
      indices,
      renderMesh.texture
    );
    return await recorder.endRecording().toImage(size.width.ceil(), size.height.ceil());
  }
}

class RenderMesh {
  RenderMesh(int vertexCount, int faceCount) {
    positions = Float32List(vertexCount * 2);
    positionsZ = Float32List(vertexCount);
    texcoords = Float32List(vertexCount * 2);
    colors = Int32List(vertexCount);
    indices = List<Triangle?>.filled(faceCount, null);
  }
  late Float32List positions;
  late Float32List positionsZ;
  late Float32List texcoords;
  late Int32List colors;
  late List<Triangle?> indices;
  Image? texture;
  int vertexCount = 0;
  int indexCount = 0;
}
