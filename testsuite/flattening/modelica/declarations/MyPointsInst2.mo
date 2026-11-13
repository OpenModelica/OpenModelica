// name:     MyPointsInst2
// keywords: class declaration
// status:   correct
//
//
// Drmodelica: 2.2  Declaring Instances of Classes (p. 26)
//

model Point                "Point in a three-dimensional space"
  public
    parameter Real x(fixed = false);
    parameter Real y(fixed = false);
    parameter Real z(fixed = false);
end Point;

model MyPoints
  Point point1(x = 1, y = 2, z = 3);
  Point point2;
  Point point3;
end MyPoints;

model MyPointsInst2
  MyPoints pts(point1.x = 1, point1.y = 2, point1.z = 3);
  Real x=pts.point1.x;
  Real y=pts.point1.y;
  Real z=pts.point1.z;
end MyPointsInst2;



// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// Result:
// class MyPointsInst2
//   parameter Real pts.point1.x(fixed = false) = 1.0;
//   parameter Real pts.point1.y(fixed = false) = 2.0;
//   parameter Real pts.point1.z(fixed = false) = 3.0;
//   parameter Real pts.point2.x(fixed = false);
//   parameter Real pts.point2.y(fixed = false);
//   parameter Real pts.point2.z(fixed = false);
//   parameter Real pts.point3.x(fixed = false);
//   parameter Real pts.point3.y(fixed = false);
//   parameter Real pts.point3.z(fixed = false);
//   Real x = pts.point1.x;
//   Real y = pts.point1.y;
//   Real z = pts.point1.z;
// end MyPointsInst2;
// endResult
