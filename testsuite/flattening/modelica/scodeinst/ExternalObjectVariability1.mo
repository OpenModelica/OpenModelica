// name: ExternalObjectVariability1
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

model ExternalObjectVariability1
  constant ExtObj eo;
end ExternalObjectVariability1;

// Result:
// impure function ExtObj.constructor
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
// class ExternalObjectVariability1
//   constant ExtObj eo;
// end ExternalObjectVariability1;
// endResult
