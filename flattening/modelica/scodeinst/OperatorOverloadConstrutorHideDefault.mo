// name: OperatorOverloadConstrutorHideDefault
// keywords: operator overload constructor
// status: correct
// cflags: -d=newInst
//
// Checks that overloaded constructor has precedence over deafault constructor 
// which would otherwise cause ambiguity. 

operator record C
  Real r;
  operator 'constructor'
    function fromReal
      input Real r;
      output C o;
    algorithm
      o.r := r;
    end fromReal;
  end 'constructor';
end C;

model T
  C c;
equation
  c = C(1.0);
end T;


// Result:
// function C.'constructor'.fromReal
//   input Real r;
//   output C o;
// algorithm
//   o.r := r;
// end C.'constructor'.fromReal;
//
// class T
//   Real c.r;
// equation
//   c = C.'constructor'.fromReal(1.0);
// end T;
// endResult
