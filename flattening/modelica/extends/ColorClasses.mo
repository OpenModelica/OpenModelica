// name:     ColorClasses
// keywords: extends, replaceable, equation
// status:   correct
//
// Drmodelica: 4.1 Public Respectively Protected Elements (p. 117)
//
record ColorData "Superclass of Color"
  parameter Real red;
  parameter Real blue;
  Real green;
end ColorData;

class Color "Subclass of ColorData"
  extends ColorData;
equation
  red + blue + green = 1;
end Color;

class C1
  replaceable Color obj1(red=0.8, blue=0.2);
end C1;

class C2
  replaceable class P = Color(red=0.3);
  P obj1(blue=0.5);
end C2;

class C12 = C1(redeclare Color obj1(red=0.2, blue=0.6));
class C22 = C2(redeclare class P = Color(red=0.5));

model ColorClasses
  Real a,b,c,d;
equation
  a = C1.obj1.green;
  b = C2.obj1.green;
  c = C12.obj1.green;
  d = C22.obj1.green;
end ColorClasses;
