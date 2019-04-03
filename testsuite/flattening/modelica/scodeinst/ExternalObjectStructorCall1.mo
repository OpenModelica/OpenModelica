// name: ExternalObjectStructorCall1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Tests that it's not possible to call an external object constructor
// explicitly.
//

class ExtObj
  extends ExternalObject;

  function constructor
    input Integer i;
    output ExtObj obj;
    external "C" obj = initObject();
  end constructor;

  function destructor
    input ExtObj obj;
    external "C" destroyObject(obj);
  end destructor;
end ExtObj;

model ExternalObjectStructorCall1
  ExtObj eo1 = ExtObj.constructor(10);
end ExternalObjectStructorCall1;

// Result:
// Error processing file: ExternalObjectStructorCall1.mo
// [flattening/modelica/scodeinst/ExternalObjectStructorCall1.mo:26:3-26:38:writable] Error: Function ExtObj.constructor not found in scope ExternalObjectStructorCall1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
