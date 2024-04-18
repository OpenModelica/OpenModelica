// name: ExternalObjectReplaceable1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

class ExtObj
  extends ExternalObject;

  replaceable function constructor
    output ExtObj obj;
    external "C" obj = initObject();
  end constructor;

  replaceable function destructor
    input ExtObj obj;
    external "C" destroyObject(obj);
  end destructor;
end ExtObj;

model ExternalObjectReplaceable1
  ExtObj eo1;
end ExternalObjectReplaceable1;

// Result:
// Error processing file: ExternalObjectReplaceable1.mo
// [flattening/modelica/scodeinst/ExternalObjectReplaceable1.mo:11:15-14:18:writable] Error: 'constructor' may not be replaceable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
