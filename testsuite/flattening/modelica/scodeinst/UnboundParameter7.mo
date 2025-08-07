// name: UnboundParameter7
// keywords:
// status: correct
//

model A
  replaceable parameter Real x(start = 1.0);
end A;

model UnboundParameter7
  extends A(redeclare Real x = 1.0);
end UnboundParameter7;

// Result:
// class UnboundParameter7
//   parameter Real x(start = 1.0) = 1.0;
// end UnboundParameter7;
// endResult
