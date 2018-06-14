// name: OperatorOverloadError1
// keywords: operator overload
// status: incorrect
// cflags: -d=newInst
//
// Tests that unneccesary error messages are not printed. e.g. when trying to
// implicitly construct i to C on 'c1+i' to match '+'.self(), error messages
// about missing constructor should not be printed.
//

operator record C
  Real r;

  encapsulated operator '+'
    import C;

    function self
      input C i;
      input C j;
      output C o;
    algorithm
      o.r := i.r + j.r;
    end self;
  end '+';
end C;

model T
  C c1;
  C c2;
  Integer i = 0;
equation
  c1 = C(1);
  c2 = c1 + i;
end T;

// Result:
// Error processing file: OperatorOverloadError1.mo
// [flattening/modelica/scodeinst/OperatorOverloadError1.mo:33:3-33:14:writable] Error: Cannot resolve type of expression c1 + i. The operands have types C, Integer in component <NO_COMPONENT>.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
