// name: ExternalObjectMod1
// keywords:
// status: incorrect
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
end ExtObj;

model ExternalObjectMod1
  ExtObj eo1(x = 1);
end ExternalObjectMod1;

// Result:
// Error processing file: ExternalObjectMod1.mo
// [flattening/modelica/scodeinst/ExternalObjectMod1.mo:22:14-22:19:writable] Error: Modified element x not found in class ExtObj.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
