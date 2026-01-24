// name: UnboundParameter6
// keywords:
// status: correct
//

model UnboundParameter6
  parameter Real x[3](each start = 1.0);
end UnboundParameter6;

// Result:
// class UnboundParameter6
//   parameter Real x[1](start = 1.0) = 1.0;
//   parameter Real x[2](start = 1.0) = 1.0;
//   parameter Real x[3](start = 1.0) = 1.0;
// end UnboundParameter6;
// [flattening/modelica/scodeinst/UnboundParameter6.mo:7:3-7:40:writable] Warning: Parameter x has no binding, and is fixed during initialization (fixed=true), using available start value (start=1.0) as default value.
//
// endResult
