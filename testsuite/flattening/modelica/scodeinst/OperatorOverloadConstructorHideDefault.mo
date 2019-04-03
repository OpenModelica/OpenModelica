// name: OperatorOverloadConstructorHideDefault
// keywords: operator overload constructor
// status: correct
// cflags: -d=newInst,-nfEvalConstArgFuncs
//
// Checks that overloaded constructor has precedence over deafault constructor 
// which would otherwise cause ambiguity. 

operator record C
  Real r;

  encapsulated operator 'constructor'
    import C;

    function fromReal
      input Real r;
      output C o;
    algorithm
      o.r := r;
    end fromReal;
  end 'constructor';
end C;

model OperatorOverloadConstructorHideDefault
  C c;
equation
  c = C(1.0);
end OperatorOverloadConstructorHideDefault;


// Result:
// function C "Automatically generated record constructor for C"
//   input Real r;
//   output C res;
// end C;
//
// function C.'constructor'.fromReal
//   input Real r;
//   output C o;
// algorithm
//   o.r := r;
// end C.'constructor'.fromReal;
//
// class OperatorOverloadConstructorHideDefault
//   Real c.r;
// equation
//   c = C.'constructor'.fromReal(1.0);
// end OperatorOverloadConstructorHideDefault;
// endResult
