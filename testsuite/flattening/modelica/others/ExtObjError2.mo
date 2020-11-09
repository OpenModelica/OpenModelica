// status: incorrect
// cflags: -d=-newInst

model ExtObjError2
  class ExtObj
    extends ExternalObject;
    function constructor
      output ExtObj eo;
    external "C";
    end constructor;
    function destructor
      input ExtObj eo;
    external "C";
    end destructor;
  end ExtObj;

  function notConstructor
    output ExtObj eo = ExtObj(); // Invalid; non-constructors may not return external objects
  algorithm

  end notConstructor;

  ExtObj eo = notConstructor();
end ExtObjError2;

// Result:
// Error processing file: ExtObjError2.mo
// [flattening/modelica/others/ExtObjError2.mo:17:3-21:21:writable] Error: Function ExtObjError2.notConstructor returns an external object, but the only function allowed to return this object is ExtObjError2.ExtObj.constructor.
// [flattening/modelica/others/ExtObjError2.mo:23:3-23:31:writable] Error: Class notConstructor not found in scope ExtObjError2 (looking for a function or record).
// Error: Error occurred while flattening model ExtObjError2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
