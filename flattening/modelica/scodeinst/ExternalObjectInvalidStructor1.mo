// name: ExternalObjectInvalidStructor1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

class ExtObj
  extends ExternalObject;

  class constructor
    output ExtObj obj;
  end constructor;

  function destructor
    input ExtObj obj;
    external "C" destroyObject(obj);
  end destructor;
end ExtObj;

model ExternalObjectInvalidStructor1
  ExtObj eo1;
end ExternalObjectInvalidStructor1;

// Result:
// Error processing file: ExternalObjectInvalidStructor1.mo
// [flattening/modelica/scodeinst/ExternalObjectInvalidStructor1.mo:11:3-13:18:writable] Error: External object ExtObj contains invalid element 'constructor'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
