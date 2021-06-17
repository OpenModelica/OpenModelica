// name: PartialFunction2
// keywords:
// status: correct
// cflags: -d=newInst
//

partial function f
  input Real x;
  output Real y;
end f;

class PartialFunction2
  Real x = f(time) if false;
end PartialFunction2;

// Result:
// class PartialFunction2
// end PartialFunction2;
// endResult
