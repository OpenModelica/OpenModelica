// name: OperatorOverloadConstructorDefault1
// keywords: operator overload constructor
// status: correct
// cflags: -d=newInst
//
// Checks that the default constructor is used when an overloaded constructor is
// not defined.
//

operator record C
  Real r;
end C;

model OperatorOverloadConstructorDefault1
  C c;
equation
  c = C(1.0);
end OperatorOverloadConstructorDefault1;


// Result:
// function C "Automatically generated record constructor for C"
//   input Real r;
//   output C res;
// end C;
//
// class OperatorOverloadConstructorDefault1
//   Real c.r;
// equation
//   c = C(1.0);
// end OperatorOverloadConstructorDefault1;
// endResult
