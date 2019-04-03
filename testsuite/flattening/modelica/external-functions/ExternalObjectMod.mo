// name:     ExternalObjectMod
// keywords: external object, modifier
// status:   incorrect
//
// Checks that invalid modifiers on external objects are caught.
//

class ExtObj
  extends ExternalObject;

  function constructor
    input String inParam;
    output ExtObj outEO;

    external "C" outEO = ctor(inParam);
  end constructor;

  function destructor
    input ExtObj inEO;

    external "C" dtor(inEO);
  end destructor;
end ExtObj;

model ExternalObjectMod
  ExtObj eo(param = "test");
end ExternalObjectMod;

// Result:
// Error processing file: ExternalObjectMod.mo
// [flattening/modelica/external-functions/ExternalObjectMod.mo:26:13-26:27:writable] Error: Modified element param not found in class ExtObj$eo.
// Error: Error occurred while flattening model ExternalObjectMod
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
