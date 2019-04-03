// name: OperatorOverloadBinaryAmbiguousTwoRecords
// keywords: operator overload
// status: incorrect
// cflags: -d=newInst
//
// Tests that ambiguous overloads due to two overloads in two different operator records are caught. 
// C.'+'.rightD() and D.'+'.leftC() are ambiguous for c1+d1.
//

operator record C
  Real r;

  encapsulated operator '+'
    import C;
    import D;

    function self
      input C i;
      input C j;
      output C o;
    algorithm
      o.r := i.r + j.r;
    end self;

    function rightD
      input C i;
      input D j;
      output C o;
    algorithm
      o.r := i.r + j.r;
    end rightD;
  end '+';
end C;

operator record D
  Real r;

  encapsulated operator '+'
    import C;
    import D;

    function leftC
      input C i;
      input D j;
      output D o;
    algorithm
      o.r := i.r + j.r;
    end leftC;
  end '+';
end D;

model OperatorOverloadBinaryAmbiguousTwoRecords
  C c1;
  C c2;
  D d1;
equation
  c1 = C(1);
  d1 = D(1);
  c2 = c1 + d1;
end OperatorOverloadBinaryAmbiguousTwoRecords;


// Result:
// Error processing file: OperatorOverloadBinaryAmbiguousTwoRecords.mo
// [flattening/modelica/scodeinst/OperatorOverloadBinaryAmbiguousTwoRecords.mo:59:3-59:15:writable] Error: Ambiguous matching overloaded operator functions found for c1 + d1.
// Candidates are:
//   C.'+'.self(C i, C j) => C
//   C.'+'.rightD(C i, D j) => C
//   D.'+'.leftC(C i, D j) => D
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
