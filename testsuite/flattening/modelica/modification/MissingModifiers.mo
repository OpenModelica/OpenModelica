// name:     MissingModifiers.mo [BUG: #3051]
// keywords: class modification handling
// status:   correct
//

model A
 type crazyT = Real(start=100);
end A;

model B
 extends A(crazyT(start=1.6));
end B;

model C
 extends B(crazyT(start=2.6));
end C;

model MissingModifiers
 parameter B.crazyT b;
 parameter C.crazyT c;
end MissingModifiers;

// Result:
// class MissingModifiers
//   parameter Real b(start = 1.6);
//   parameter Real c(start = 2.6);
// end MissingModifiers;
// [flattening/modelica/modification/MissingModifiers.mo:19:2-19:22:writable] Warning: Parameter b has no value, and is fixed during initialization (fixed=true), using available start value (start=1.6) as default value.
// [flattening/modelica/modification/MissingModifiers.mo:20:2-20:22:writable] Warning: Parameter c has no value, and is fixed during initialization (fixed=true), using available start value (start=2.6) as default value.
//
// endResult
