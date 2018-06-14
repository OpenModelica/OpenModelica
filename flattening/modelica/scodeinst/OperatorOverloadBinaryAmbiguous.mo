// name: OperatorOverloadBinaryAmbiguous
// keywords: operator overload constructor
// status: incorrect
// cflags: -d=newInst
//
// Tests that ambiguous overloads for a given operator are detected.
//

operator record C
  Real r;

  encapsulated operator '+'
    import C;

    function rightInt
      input C i;
      input Integer j;
      output C o;
    algorithm
      o.r := i.r + j;
    end rightInt;

    function anotherRightInt
      input C i;
      input Integer j;
      output C o;
    algorithm
      o.r := i.r + j;
    end anotherRightInt;
  end '+';
end C;

model OperatorOverloadBinaryAmbiguous
  C c1;
  C c2;
equation
  c1 = C(1.0);
  c2 = c1 + 1;
end OperatorOverloadBinaryAmbiguous;


// Result:
// Error processing file: OperatorOverloadBinaryAmbiguous.mo
// [flattening/modelica/scodeinst/OperatorOverloadBinaryAmbiguous.mo:38:3-38:14:writable] Error: Ambiguous matching overloaded operator functions found for c1 + 1.
// Candidates are:
//   C.'+'.rightInt(C i, Integer j) => C
//   C.'+'.anotherRightInt(C i, Integer j) => C
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
