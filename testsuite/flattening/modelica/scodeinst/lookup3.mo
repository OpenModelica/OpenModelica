// name: lookup3.mo
// keywords:
// status: incorrect
//

model A
  model B
    model C
      model D
        Real x;
      end D;

      D d;
    end C;
  end B;

  B b;
end A;

model M
  A a;
  Real x = a.B.C;
end M;

// Result:
// Error processing file: lookup3.mo
// [flattening/modelica/scodeinst/lookup3.mo:22:3-22:17:writable] Error: Class name 'a.B.C' was found via a component (only component and function call names may be accessed in this way).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
