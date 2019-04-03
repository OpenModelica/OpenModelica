// name: ExternalObject2
// keywords:
// status: correct
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
end ExtObj;

model ExternalObject2
  ExtObj eo1;
  ExtObj eo2;
end ExternalObject2;

// Result:
// function ExtObj.constructor
//   output ExtObj obj;
//
//   external "C" obj = initObject();
// end ExtObj.constructor;
//
// function ExtObj.destructor
//   input ExtObj obj;
//
//   external "C" destroyObject(obj);
// end ExtObj.destructor;
//
// class ExternalObject2
//   ExtObj eo1;
//   ExtObj eo2;
// end ExternalObject2;
// endResult
