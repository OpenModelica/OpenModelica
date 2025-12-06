// name: UnboundParameter5
// keywords:
// status: correct
//

model UnboundParameter5
  type E = enumeration(a, b, c, d);

  parameter Real r1;
  parameter Real r2(min = 1.0, max = 3.0);
  parameter Real r3(min = -3.0, max = -1.0);
  parameter Integer i1;
  parameter Integer i2(min = 1, max = 3);
  parameter Integer i3(min = -3, max = -1);
  parameter Boolean b1;
  parameter String s1;
  parameter E e1;
  parameter E e2(min = E.c);
  annotation(__OpenModelica_commandLineOptions="--allowNonStandardModelica=implicitParameterStartAttribute");
end UnboundParameter5;

// Result:
// class UnboundParameter5
//   parameter Real r1 = 0.0;
//   parameter Real r2(min = 1.0, max = 3.0) = 1.0;
//   parameter Real r3(min = -3.0, max = -1.0) = -1.0;
//   parameter Integer i1 = 0;
//   parameter Integer i2(min = 1, max = 3) = 1;
//   parameter Integer i3(min = -3, max = -1) = -1;
//   parameter Boolean b1 = false;
//   parameter String s1 = "";
//   parameter enumeration(a, b, c, d) e1 = E.a;
//   parameter enumeration(a, b, c, d) e2(min = E.c) = E.c;
// end UnboundParameter5;
// [flattening/modelica/scodeinst/UnboundParameter5.mo:9:3-9:20:writable] Error: Parameter r1 has neither binding nor start value, and is fixed during initialization (fixed=true).
// [flattening/modelica/scodeinst/UnboundParameter5.mo:10:3-10:42:writable] Error: Parameter r2 has neither binding nor start value, and is fixed during initialization (fixed=true).
// [flattening/modelica/scodeinst/UnboundParameter5.mo:11:3-11:44:writable] Error: Parameter r3 has neither binding nor start value, and is fixed during initialization (fixed=true).
// [flattening/modelica/scodeinst/UnboundParameter5.mo:12:3-12:23:writable] Error: Parameter i1 has neither binding nor start value, and is fixed during initialization (fixed=true).
// [flattening/modelica/scodeinst/UnboundParameter5.mo:13:3-13:41:writable] Error: Parameter i2 has neither binding nor start value, and is fixed during initialization (fixed=true).
// [flattening/modelica/scodeinst/UnboundParameter5.mo:14:3-14:43:writable] Error: Parameter i3 has neither binding nor start value, and is fixed during initialization (fixed=true).
// [flattening/modelica/scodeinst/UnboundParameter5.mo:15:3-15:23:writable] Error: Parameter b1 has neither binding nor start value, and is fixed during initialization (fixed=true).
// [flattening/modelica/scodeinst/UnboundParameter5.mo:16:3-16:22:writable] Error: Parameter s1 has neither binding nor start value, and is fixed during initialization (fixed=true).
// [flattening/modelica/scodeinst/UnboundParameter5.mo:17:3-17:17:writable] Error: Parameter e1 has neither binding nor start value, and is fixed during initialization (fixed=true).
// [flattening/modelica/scodeinst/UnboundParameter5.mo:18:3-18:28:writable] Error: Parameter e2 has neither binding nor start value, and is fixed during initialization (fixed=true).
//
// endResult
