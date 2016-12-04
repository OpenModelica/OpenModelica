// name: lookup4.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
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
  Real x = a.b.C.d.x;
end M;

// Result:
// Error processing file: lookup4.mo
// [flattening/modelica/scodeinst/lookup4.mo:23:3-23:21:writable] Error: Found class C during lookup of composite component name 'a.b.C.d.x', expected component.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
