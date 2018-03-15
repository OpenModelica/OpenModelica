// name: OperatorOverloadConstrutorSimple
// keywords: operator constructor overload
// status: correct
// cflags: -d=newInst
//
// Tests simple overloaded construction.
//



operator record C
  Real r;
  operator 'constructor'
    function fromNone
      output C o;
    algorithm
      o.r := 1;
    end fromNone;
  end 'constructor';
end C;

model T
  C c;
equation
  c = C();
end T;


// Result:
// function C.'constructor'.fromNone
//   output C o;
// algorithm
//   o.r := 1.0;
// end C.'constructor'.fromNone;
//
// class T
//   Real c.r;
// equation
//   c = C.'constructor'.fromNone();
// end T;
// endResult
