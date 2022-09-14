import 'package:vector_math/vector_math_64.dart';
import 'other.dart';
import 'dart:ui';

class CameraControls{
  CameraControls({
    this.zoom = true,
    this.panX = true,
    this.panY = true,
    this.orbitX = true,
    this.orbitY = true,
  });
  bool zoom;
  bool panX;
  bool panY;
  bool orbitX;
  bool orbitY;
}

class Camera {
  Camera({
    Vector3? position,
    double zoom = 1.0,
    this.fov = 80.0,
    this.near = 0.001,
    this.far = 10000,
    this.viewportWidth = 100.0,
    this.viewportHeight = 100.0,
    CameraControls? cameraControls,
  }) {
    if (position != null) position.copyInto(this.position);
    this.cameraControls = cameraControls ?? CameraControls();
    _zoom = zoom;
    _zoomStart = zoom;
  }

  late CameraControls cameraControls;
  Quaternion q = Quaternion.identity();

  final Vector3 position = Vector3(0.0, 0.0, 0.0);
  final Vector3 rotation = Vector3(0.0, 0.0, 0.0);
  final Vector3 scale = Vector3(100,-100,100);
  final Matrix4 transform = Matrix4.identity();

  final Vector2 _from = Vector2(0,0);

  double fov;
  double near;
  double far;
  late double _zoom;
  late double _zoomStart;
  double get zoom => _zoom;
  Size get size => Size(viewportWidth,viewportHeight);
  double viewportWidth;
  double viewportHeight;
  double get aspectRatio => viewportWidth / viewportHeight;

  Matrix4 get lookAtMatrix {
    Quaternion q = Quaternion.euler(radians(rotation.x), radians(rotation.y),radians(rotation.z));
    final m =  Matrix4.compose(Vector3(viewportWidth/2, viewportHeight/2, 0.0), q, scale)..translate(position.x,position.y,position.z);   
    transform.setFrom(m);
    return transform;
  }
  Vector3 relativeLocation(Vector3 objectPosition, Offset offset){
    Vector3 zero = Vector3.zero();
    zero.applyMatrix4(lookAtMatrix);
    Vector3 newPosition = Converter.toVector3(objectPosition, offset);
    newPosition.applyMatrix4(lookAtMatrix);
    return Vector3.copy(newPosition-zero);
  }
  void reset(){
    position.x = -7.5;
    position.y = 4.5;
    position.z = 0;

    rotation.x = 0;
    rotation.y = 0;
    rotation.z = 0;

    _zoom = _zoomStart; 
  }
  void zoomCamera(double zoom,[Vector2? to,Vector2? offset,double sensitivity = 1.0]){
    // if(true||to != null){
    //   Vector2 toMove = to;
    //   print(to);
    //   toMove.x = (to.x+(position.x*100))/100-_pan.x+offset.x;
    //   toMove.y = (to.y-(position.y*100))/-100-_pan.y+offset.y;
    //   print(toMove);
    //   panCamera(toMove,sensitivity);
    // }
    _zoom = zoom;
  }
  void panCameraStart(Vector2 to){
    _from.x = to.x;
    _from.y = to.y;
  }
  void panCamera(Vector2 to, [double sensitivity = 1.0]){
    final double x = (!cameraControls.panX)?0:((to.x - _from.x)/100 * sensitivity);
    final double y = (!cameraControls.panY)?0:((to.y - _from.y)/100 * sensitivity);

    position.x += x;
    position.y -= y;

    _from.x = to.x;
    _from.y = to.y;
  }
  void trackBall(Vector2 to, [double sensitivity = 1.0]) {
    final double x = (!cameraControls.orbitX)?0:-(to.x - _from.x)/100 * sensitivity;
    final double y = (!cameraControls.orbitY)?0:(to.y - _from.y)/100 * sensitivity;
    rotation.x += x;
    rotation.y += y;
    _from.x = to.x;
    _from.y = to.y;
  }
}
