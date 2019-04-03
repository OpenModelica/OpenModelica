// name:     Colors
// keywords: extends, equation
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

model Colors
  Color c(red=0.7,blue=0.1);
  Real k;
equation
  k = c.green;
end Colors;
// Result:
// class Colors
//   parameter Real c.red = 0.7;
//   parameter Real c.blue = 0.1;
//   Real c.green;
//   Real k;
// equation
//   c.red + c.blue + c.green = 1.0;
//   k = c.green;
// end Colors;
// endResult
