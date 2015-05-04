// name:     InvalidExternalObject1
// keywords: external object bug2043
// status:   incorrect
//
//

class A end A;

class InvalidExternalObject1
  extends ExternalObject;
  extends A;

  import A;

  function constructor
    output InvalidExternalObject1 obj;
  end constructor;

  function destructor
    input InvalidExternalObject1 obj;
  end destructor;

  function otherFunc end otherFunc;

  Real x;
end InvalidExternalObject1;

// function f
// input Real x;
// output Real y;
//
// external "C";
// end f;
//
// Result:
// Error processing file: InvalidExternalObject1.mo
// [flattening/modelica/external-functions/InvalidExternalObject1.mo:9:1-26:27:writable] Error: Invalid external object InvalidExternalObject1, contains invalid elements: extends A, otherFunc, x.
// Error: Error occurred while flattening model InvalidExternalObject1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
