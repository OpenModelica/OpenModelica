// name: OperatorOverloadBinaryWithBuiltin
// keywords: operator overload constructor
// status: correct
// cflags: -d=newInst
//
// Tests binary overloaded operators with simple builtin types.

operator record C
  Real r;
  operator '+'
    function self
      input C i;
      input C j;
      output C o;
    algorithm
      o.r := i.r + j.r;
    end self;
    function rightInt
      input C i;
      input Integer j;
      output C o;
    algorithm
      o.r := i.r + j;
    end rightInt;
    function leftInt
      input Integer j;
      input C i;
      output C o;
    algorithm
      o.r := i.r + j;
    end leftInt;
  end '+';
end C;

model T
  C c1;
  C c2;
equation
  c2 = c1 + 1;
  c2 = 1 + c1;
end T;


// Result:
// function C.'+'.leftInt
//   input Integer j;
//   input C i;
//   output C o;
// algorithm
//   o.r := i.r + /*Real*/(j);
// end C.'+'.leftInt;
//
// function C.'+'.rightInt
//   input C i;
//   input Integer j;
//   output C o;
// algorithm
//   o.r := i.r + /*Real*/(j);
// end C.'+'.rightInt;
//
// class T
//   Real c1.r;
//   Real c2.r;
// equation
//   c2 = C.'+'.rightInt(c1, 1);
//   c2 = C.'+'.leftInt(1, c1);
// end T;
// endResult
