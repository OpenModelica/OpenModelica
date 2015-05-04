// name: ExtObjError
// status: incorrect

model ExtObjError
  class A
    extends ExternalObject;
    function constructor input Real r; output A a; end constructor;
    function destructor input A a; end destructor;
  end A;
  class B
    extends ExternalObject;
    function constructor input Real r; output B b; end constructor;
    function destructor input B b; end destructor;
  end B;
  function f
    input A a;
    output Real r = 1.5;
  end f;
  A a = A(0);
  B b = B(0);
  Real r1 = f(a);
  Real r2 = f(b);
end ExtObjError;

// Result:
// Error processing file: ExtObjError.mo
// [flattening/modelica/others/ExtObjError.mo:22:3-22:17:writable] Error: Type mismatch for positional argument 1 in ExtObjError.f(a=b). The argument has type:
//   ExternalObject ExtObjError.B
// expected type:
//   ExternalObject ExtObjError.A
// Error: Error occurred while flattening model ExtObjError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
