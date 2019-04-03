// name: OperatorOverloadConstructor1
// keywords: operator overload constructor
// status: correct
// cflags: -d=newInst,-nfEvalConstArgFuncs
//
//

operator record C
  Real r1;
  Real r2;

  encapsulated operator function 'constructor'
    import C;

    input Real r;
    output C o(r1 = r, r2 = 1.0);
  end 'constructor';
end C;

model OperatorOverloadConstructor1
  C c;
equation
  c = C(1.0);
end OperatorOverloadConstructor1;


// Result:
// function C "Automatically generated record constructor for C"
//   input Real r1;
//   input Real r2;
//   output C res;
// end C;
//
// function C.'constructor'
//   input Real r;
//   output C o;
// end C.'constructor';
//
// class OperatorOverloadConstructor1
//   Real c.r1;
//   Real c.r2;
// equation
//   c = C.'constructor'(1.0);
// end OperatorOverloadConstructor1;
// endResult
