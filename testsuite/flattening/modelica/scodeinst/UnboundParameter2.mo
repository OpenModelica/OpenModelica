// name: UnboundParameter2
// keywords:
// status: correct
//

model UnboundParameter2
  parameter Real x(start = 1.0);
end UnboundParameter2;

// Result:
// class UnboundParameter2
//   parameter Real x(start = 1.0) = 1.0;
// end UnboundParameter2;
// [flattening/modelica/scodeinst/UnboundParameter2.mo:7:3-7:32:writable] Warning: Parameter x has no value, and is fixed during initialization (fixed=true), using available start value (start=1.0) as default value.
//
// endResult
