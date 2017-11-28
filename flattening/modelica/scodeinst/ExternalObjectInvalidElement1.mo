// name: ExternalObjectInvalidElement1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

class ExtObj
  extends ExternalObject;

  function constructor
    output ExtObj obj;
    external "C" obj = initObject();
  end constructor;

  function destructor
    input ExtObj obj;
    external "C" destroyObject(obj);
  end destructor;

  function f
  end f;
end ExtObj;

model ExternalObjectInvalidElement1
  ExtObj eo1;
end ExternalObjectInvalidElement1;

// Result:
// Error processing file: ExternalObjectInvalidElement1.mo
// [flattening/modelica/scodeinst/ExternalObjectInvalidElement1.mo:21:3-22:8:writable] Error: External object ExtObj contains invalid element 'f'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
