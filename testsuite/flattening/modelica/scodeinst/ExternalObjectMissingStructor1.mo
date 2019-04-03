// name: ExternalObjectMissingStructor1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

class ExternalObjectMissingStructor1
  extends ExternalObject;

  function constructor
    output ExternalObjectMissingStructor1 obj;
    external "C" obj = initObject();
  end constructor;
end ExternalObjectMissingStructor1;

// Result:
// Error processing file: ExternalObjectMissingStructor1.mo
// [flattening/modelica/scodeinst/ExternalObjectMissingStructor1.mo:8:1-15:35:writable] Error: External object ExternalObjectMissingStructor1 is missing a destructor.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
