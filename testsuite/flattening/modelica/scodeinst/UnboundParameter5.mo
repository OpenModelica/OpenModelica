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
// endResult
