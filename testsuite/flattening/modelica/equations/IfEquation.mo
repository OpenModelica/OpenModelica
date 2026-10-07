// name:     IfEquation
// keywords: if
// status:   correct
//
// Drmodelica: 8.2 Conditional Equations with if-Equations (p. 245)
//


class IfEquation
  parameter Real u;
  parameter Real uMax;
  parameter Real uMin;
  Real y;
equation
  if u > uMax then
    y = uMax;
  elseif u < uMin then
    y = uMin;
  else
    y = u;
  end if;
end IfEquation;

model Test
  IfEquation y1(u = 1.0, uMax = 2.0, uMin = 0.0);
  IfEquation y2(u = 0.0, uMax = 2.0, uMin = 0.0);
  IfEquation y3(u = 3.0, uMax = 2.0, uMin = 0.0);
end Test;

// Result:
// class Test
//   final parameter Real y1.u = 1.0;
//   final parameter Real y1.uMax = 2.0;
//   final parameter Real y1.uMin = 0.0;
//   Real y1.y;
//   final parameter Real y2.u = 0.0;
//   final parameter Real y2.uMax = 2.0;
//   final parameter Real y2.uMin = 0.0;
//   Real y2.y;
//   final parameter Real y3.u = 3.0;
//   final parameter Real y3.uMax = 2.0;
//   parameter Real y3.uMin = 0.0;
//   Real y3.y;
// equation
//   y1.y = 1.0;
//   y2.y = 0.0;
//   y3.y = 2.0;
// end Test;
// [flattening/modelica/equations/IfEquation.mo:10:3-10:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:11:3-11:22:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:12:3-12:22:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:13:3-13:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:15:3-21:9:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:10:3-10:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:11:3-11:22:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:12:3-12:22:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:13:3-13:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:15:3-21:9:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:10:3-10:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:11:3-11:22:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:12:3-12:22:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:13:3-13:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/IfEquation.mo:15:3-21:9:writable] Warning: Equation sections are deprecated in class.
//
// endResult
