// name: ConnectExternalObject1
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

connector C
  ExtObj eo;
end C;

model ConnectExternalObject1
  C c1, c2;
equation
  connect(c1, c2);
end ConnectExternalObject1;

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
// class ConnectExternalObject1
//   ExtObj c1.eo;
//   ExtObj c2.eo;
// equation
//   c1.eo = c2.eo;
// end ConnectExternalObject1;
// endResult
