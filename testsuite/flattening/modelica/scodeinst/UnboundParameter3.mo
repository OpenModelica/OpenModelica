// name: UnboundParameter3
// keywords:
// status: correct
//

model UnboundParameter3
  type T = Real(start = 1.0);
  parameter T x[3];
end UnboundParameter3;

// Result:
// class UnboundParameter3
//   parameter Real x[1](start = 1.0);
//   parameter Real x[2](start = 1.0);
//   parameter Real x[3](start = 1.0);
// end UnboundParameter3;
// [flattening/modelica/scodeinst/UnboundParameter3.mo:8:3-8:19:writable] Warning: Parameter x has no value, and is fixed during initialization (fixed=true), using available start value (start=fill(1.0, 3)) as default value.
//
// endResult
