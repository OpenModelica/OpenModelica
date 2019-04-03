// name: ExternalObjectStructorCall2
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

model ExternalObjectStructorCall2
  ExtObj eo1 = ExtObj.destructor();
end ExternalObjectStructorCall2;

// Result:
// Error processing file: ExternalObjectStructorCall2.mo
// [flattening/modelica/scodeinst/ExternalObjectStructorCall2.mo:26:3-26:35:writable] Error: Function ExtObj.destructor not found in scope ExternalObjectStructorCall2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
