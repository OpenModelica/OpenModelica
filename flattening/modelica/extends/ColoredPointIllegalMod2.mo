// name:      Colered Point Illegal Mod 2
// keywords: <insert keywords here>
// status:   incorrect
//
// Test the public and protected access keywords together with inheritance
// If the keyword protected is used in front of an extends clause, all
// inherited elements from the superclass become protected elements of the
// subclass. If an extends clause is a public element, all elements of the
// superclass are inherited with their own protection.

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
  a = cp.dummy;   //Should NOT work, since dummy becomes proteced in class
                  //ColoredPoint

end A;

