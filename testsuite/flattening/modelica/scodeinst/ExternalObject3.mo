// name: ExternalObject3
// keywords:
// status: correct
//
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

model ExternalObject3
  ExtObj eo1 = ExtObj(10);
end ExternalObject3;

// Result:
// impure function ExtObj.constructor
//   input Integer i;
//   output ExtObj obj;
//
//   external "C" obj = initObject();
// end ExtObj.constructor;
//
// impure function ExtObj.destructor
//   input ExtObj obj;
//
//   external "C" destroyObject(obj);
// end ExtObj.destructor;
//
// class ExternalObject3
//   ExtObj eo1 = ExtObj.constructor(10);
// end ExternalObject3;
// endResult
