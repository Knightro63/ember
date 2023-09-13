import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import 'material.dart';

class Vertex{
  Vertex({
    required this.indicies,
    required this.vertex
  });

  List<Vector3> vertex;
  List<Triangle> indicies;
}

class Triangle{
  Triangle(this.vertexes,this.normals,this.texture,[this.z = 0, this.showFace = false]);
  List<int> vertexes;
  List<int>? normals;
  List<int>? texture;

  double z;
  bool showFace;

  List<int> copyVertexes() => vertexes;
  List<int>? copyNormals() => normals;
  List<int>? copyTextures() => texture;
  void copyFromArray(List<int> array) {
    vertexes = array;
    normals = array;
    texture = array;
  }
}

class Mesh {
  Mesh({
    List<Vector3>? vertices,
    List<Vector3>? normals, 
    List<Offset>? texcoords, 
    List<Triangle>? indices,
    List<Color>? colors,
    this.texture,
    this.hasTexture = false,
    Rect? textureRect, 
    this.texturePath,
    Material? material, 
    this.name,
  }) {
    this.vertices = vertices ?? <Vector3>[];
    this.normals = normals ?? <Vector3>[];
    this.texcoords = texcoords ?? <Offset>[];
    this.colors = colors ?? <Color>[];
    this.indices = indices ?? <Triangle>[];
    this.material = material ?? Material();
    this.textureRect = textureRect ?? Rect.fromLTWH(0, 0, texture==null?1.0:texture!.width.toDouble(), texture==null?1.0:texture!.height.toDouble());
  }
  late List<Vector3> vertices;
  late List<Vector3> normals;
  late List<Offset>? texcoords;
  late List<Color> colors;
  late List<Triangle> indices;
  bool hasTexture;
  Image? texture;
  Rect? textureRect;
  late Material material;
  String? texturePath;
  String? name;
}

/// Load the texture image file and rebuild vertices and texcoords to keep the same length.
Future<List<Mesh>> buildMesh(
  List<Vector3> vertices,
  List<Vector3> normals,
  List<Offset> texcoords,
  List<Triangle> triangles,
  Map<String, Material>? materials,
  List<String> elementNames,
  List<String> elementMaterials,
  List<int> elementOffsets,
  String basePath,
  bool isAsset,
) async {
  if (elementOffsets.isEmpty) {
    elementNames.add('');
    elementMaterials.add('');
    elementOffsets.add(0);
  }

  final List<Mesh> meshes = <Mesh>[];
  for (int index = 0; index < elementOffsets.length; index++) {
    int faceStart = elementOffsets[index];
    int faceEnd = (index + 1 < elementOffsets.length) ? elementOffsets[index + 1] : triangles.length;

    var newVertices = <Vector3>[];
    var newNormals = <Vector3>[];
    var newTexcoords = <Offset>[];
    var newTriangles = <Triangle>[];

    if (faceStart == 0 && faceEnd == triangles.length) {
      newVertices = vertices;
      newNormals = normals;
      newTexcoords = texcoords;
      newTriangles = triangles;
    } 
    else {
      _copyRangeIndices(faceStart, faceEnd, vertices, normals, texcoords ,triangles, newVertices, newNormals, newTexcoords, newTriangles);
    }

    // load texture image from assets.
    final Material? material = (materials != null) ? materials[elementMaterials[index]] : null;
    final MapEntry<String, Image>?imageEntry = await loadTexture(material, basePath,isAsset: false);

    // fix zero texture area
    if (imageEntry != null){
      _remapZeroAreaUVs(newTexcoords, newTriangles, imageEntry.value.width.toDouble(), imageEntry.value.height.toDouble());
    }
    // If a vertex has multiple different texture coordinates,
    // then create a vertex for each texture coordinate.
    _rebuildVertices(newVertices, newNormals, newTexcoords, newTriangles);
    final Mesh mesh = Mesh(
      vertices: newVertices,
      normals: newNormals,
      texcoords: newTexcoords,
      indices: newTriangles,
      texture: imageEntry?.value,
      texturePath: imageEntry?.key,
      name: elementNames[index],
    );

    meshes.add(mesh);
  }

  return meshes;
}
/// Copy a mesh from the obj
void _copyRangeIndices(
  int start, 
  int end, 
  List<Vector3> fromVertices, 
  List<Vector3> fromNormals, 
  List<Offset> fromText,
  List<Triangle> fromIndices, 
  List<Vector3> toVertices, 
  List<Vector3> toNormals, 
  List<Offset> toText,
  List<Triangle> toIndices
) {
  if (start < 0 || end > fromIndices.length) return;
  final viMap = List<int?>.filled(fromVertices.length, null);
  final niMap = List<int?>.filled(fromNormals.length, null);
  final tiMap = List<int?>.filled(fromText.length, null);
  for (int i = start; i < end; i++) {
    final List<int> newVi = List<int>.filled(fromIndices[i].vertexes.length, 0);
    final List<int> newNi = List<int>.filled(fromIndices[i].normals!.length, 0);
    final List<int> newTi = List<int>.filled(fromIndices[i].texture!.length, 0);

    final List<int> vi = fromIndices[i].copyVertexes();
    final List<int>? ni = fromIndices[i].copyNormals();
    final List<int>? ti = fromIndices[i].copyTextures();

    for (int j = 0; j < vi.length; j++) {
      //vert
      int indexV = vi[j];
      int indexN = ni![j];
      int indexT = ti![j];

      if (indexV < 0) indexV = fromVertices.length - 1 + indexV;
      if (indexN < 0) indexN = fromNormals.length - 1 + indexN;
      if (indexT < 0) indexT = fromText.length - 1 + indexT;

      int? v = viMap[indexV];
      int? n = niMap[indexN];
      int? t = tiMap[indexT];

      if (v == null) {
        newVi[j] = toVertices.length;
        viMap[indexV] = toVertices.length;
        toVertices.add(fromVertices[indexV]);
      }
      else{
        newVi[j] = v;
      }
      
      if(n == null){
        newNi[j] = toNormals.length;
        niMap[indexN] = toNormals.length;
        toNormals.add(fromNormals[indexN]);
      }
      else{
        newNi[j] = n;
      }

      if(t == null){
        newTi[j] = toText.length;
        tiMap[indexT] = toText.length;
        toText.add(fromText[indexT]);
      }
      else{
        newTi[j] = t;
      }
      
    }
    toIndices.add(Triangle(newVi,newNi,newTi));
  }
}

/// Remap the UVs when the texture area is zero.
void _remapZeroAreaUVs(List<Offset> texcoords, List<Triangle> textureIndices, double textureWidth, double textureHeight) {
  for (int index = 0; index < textureIndices.length; index++) {
    Triangle p = textureIndices[index];
    if (texcoords[p.texture![0]] == texcoords[p.texture![1]] && texcoords[p.texture![0]] == texcoords[p.texture![2]]) {
      double u = (texcoords[p.texture![0]].dx * textureWidth).floorToDouble();
      double v = (texcoords[p.texture![0]].dy * textureHeight).floorToDouble();
      double u1 = (u + 1.0) / textureWidth;
      double v1 = (v + 1.0) / textureHeight;
      u /= textureWidth;
      v /= textureHeight;
      int texindex = texcoords.length;
      texcoords.add(Offset(u, v));
      texcoords.add(Offset(u, v1));
      texcoords.add(Offset(u1, v));
      for(int j = 0; j < p.texture!.length;j++){
        p.texture![j] = texindex+j;
      }
    }
  }
}

/// Rebuild vertices and texture coordinates to keep the same length.
void _rebuildVertices(List<Vector3> vertices, List<Vector3> normals, List<Offset> texcoords, List<Triangle> vertexIndices) {
  int texcoordsCount = texcoords.length;
  if (texcoordsCount == 0) return;
  List<Vector3> newVertices = <Vector3>[];
  List<Vector3> newNormals = <Vector3>[];
  List<Offset> newTexcoords = <Offset>[];
  HashMap<int, int> indexMap = HashMap<int, int>();
  for (int i = 0; i < vertexIndices.length; i++) {
    List<int> vi = vertexIndices[i].copyVertexes();
    List<int>? vn = vertexIndices[i].copyNormals();
    List<int>? ti = vertexIndices[i].copyTextures();
    List<int> face = List<int>.filled(vi.length, 0);
    for (int j = 0; j < vi.length; j++) {
      int vIndex = vi[j];
      int? vnIndex = vn!=null?vn[j]:null;
      int tIndex = ti![j];
      int vtIndex = vIndex * texcoordsCount + tIndex;
      int? v = indexMap[vtIndex];
      if (v == null) {
        face[j] = newVertices.length;
        indexMap[vtIndex] = face[j];
        newVertices.add(vertices[vIndex].clone());
        if(vnIndex!=null)newNormals.add(normals[vnIndex].clone());
        newTexcoords.add(texcoords[tIndex]);
      } 
      else{
        face[j] = v;
      }
    }
    vertexIndices[i].copyFromArray(face);
  }
  vertices
    ..clear()
    ..addAll(newVertices);
  if(newNormals.isNotEmpty){
    normals
    ..clear()
    ..addAll(newNormals);
  }
  texcoords
    ..clear()
    ..addAll(newTexcoords);
}

Vertex removeDuplicates(List<Vector3> fromVertices,List<Triangle> fromIndices){
  List<Triangle> toIndices = [];
  List<Vector3> toVertices = fromVertices.toSet().toList();

  for(int i = 0; i < fromIndices.length;i++){
    List<int> vertexes = [];
    List<int> normals = [];
    List<int> texture = [];
    for(int j = 0; j < fromIndices[i].vertexes.length; j++){
      for(int k = 0; k < toVertices.length;k++){
        if(fromVertices[fromIndices[i].vertexes[j]] == toVertices[k]){
          vertexes.add(k);
          texture.add(k);
          normals.add(k);
        }
      }
    }
    toIndices.add(
      Triangle(vertexes,normals,texture)
    );
  }
  return Vertex(
    vertex: toVertices,
    indicies: toIndices
  );
}

/// Calcunormal vector
Vector3 normalVector(Vector3 a, Vector3 b, Vector3 c) {
  return (b - a).cross(c - a).normalized();
}

/// Scale the model size to 1
List<Mesh> normalizeMesh(List<Mesh> meshes) {
  double maxLength = 0;
  for (Mesh mesh in meshes) {
    final List<Vector3> vertices = mesh.vertices;
    for (int i = 0; i < vertices.length; i++) {
      final storage = vertices[i].storage;
      final double x = storage[0];
      final double y = storage[1];
      final double z = storage[2];
      if (x > maxLength) maxLength = x;
      if (y > maxLength) maxLength = y;
      if (z > maxLength) maxLength = z;
    }
  }

  maxLength = 0.5 / maxLength;
  for (Mesh mesh in meshes) {
    final List<Vector3> vertices = mesh.vertices;
    for (int i = 0; i < vertices.length; i++) {
      vertices[i].scale(maxLength);
    }
  }
  return meshes;
}

Future<Uint32List> getImagePixels(Image image) async {
  final c = Completer<Uint32List>();
  image.toByteData(format: ImageByteFormat.rawRgba).then((data) {
    c.complete(data!.buffer.asUint32List());
  }).catchError((error) {
    c.completeError(error);
  });
  return c.future;
}