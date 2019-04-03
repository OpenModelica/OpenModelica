// name:      Colered Point Legal Mod
// keywords: <insert keywords here>
// status:   correct
//
// Test the public and protected access keywords together with inheritance
// If the keyword protected is used in front of an extends clause, all
// inherited elements from the superclass become protected elements of the
// subclass. If an extends clause is a public element, all elements of the
// superclass are inherited with their own protection.
//
// Drmodelica: 4.1 Public Respectively Protected Elements (p. 117)
//
record ColorData
  Real dummy;
protected
  Real red;
  parameter Real blue;
  parameter Real green;
end ColorData;

class Color
  extends ColorData(blue = 3.5, green = 5);
equation
  red + blue + green = 1;
end Color;

class Point
public
  parameter Real x;
protected
  parameter Real y;
  parameter Real z;
end Point;

class ColoredPoint
protected
  extends Color;   // red, blue and green from ColorData become
public       // protected fields
  extends Point;   // y and z from Point stay protected
end ColoredPoint;

class A
  Real a,b,c;
  ColoredPoint cp;
equation
  a = cp.x;       //Should work since x is public
end A;

// Result:
// class A
//   Real a;
//   Real b;
//   Real c;
//   protected Real cp.dummy;
//   protected Real cp.red;
//   protected parameter Real cp.blue = 3.5;
//   protected parameter Real cp.green = 5.0;
//   parameter Real cp.x;
//   protected parameter Real cp.y;
//   protected parameter Real cp.z;
// equation
//   cp.red + cp.blue + cp.green = 1.0;
//   a = cp.x;
// end A;
// endResult
