// name: OperatorOverloadConstructorSimple
// keywords: operator constructor overload
// status: correct
// cflags: -d=newInst,-nfEvalConstArgFuncs
//
// Tests simple overloaded construction.
//

operator record C
  Real r;
  encapsulated operator 'constructor'
    import C;

    function fromNone
      output C o;
    algorithm
      o.r := 1;
    end fromNone;
  end 'constructor';
end C;

model OperatorOverloadConstructorSimple
  C c;
equation
  c = C();
end OperatorOverloadConstructorSimple;


// Result:
// function C "Automatically generated record constructor for C"
//   input Real r;
//   output C res;
// end C;
//
// function C.'constructor'.fromNone
//   output C o;
// algorithm
//   o.r := 1.0;
// end C.'constructor'.fromNone;
//
// class OperatorOverloadConstructorSimple
//   Real c.r;
// equation
//   c = C.'constructor'.fromNone();
// end OperatorOverloadConstructorSimple;
// endResult
