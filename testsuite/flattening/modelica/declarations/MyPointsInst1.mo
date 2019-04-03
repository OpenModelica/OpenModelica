// name:     MyPointsInst1
// keywords: class declaration
// status:   correct
//
// Drmodelica: 2.2  Declaring Instances of Classes (p. 26)
//

class Point                "Point in a three-dimensional space"
  public
    parameter Real x;
    parameter Real y;
    parameter Real z;
end Point;

class MyPoints
  Point point1(x = 1, y = 2, z = 3);
  Point point2;
  Point point3;
end MyPoints;

class MyPointsInst1
  MyPoints pts(point1(x= 1, y = 2, z = 3));
  Real x=pts.point1.x;
  Real y=pts.point1.y;
  Real z=pts.point1.z;
end MyPointsInst1;



// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// Result:
// class MyPointsInst1
//   parameter Real pts.point1.x = 1.0;
//   parameter Real pts.point1.y = 2.0;
//   parameter Real pts.point1.z = 3.0;
//   parameter Real pts.point2.x;
//   parameter Real pts.point2.y;
//   parameter Real pts.point2.z;
//   parameter Real pts.point3.x;
//   parameter Real pts.point3.y;
//   parameter Real pts.point3.z;
//   Real x = pts.point1.x;
//   Real y = pts.point1.y;
//   Real z = pts.point1.z;
// end MyPointsInst1;
// endResult
