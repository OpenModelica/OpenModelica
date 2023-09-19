// name: ExternalObject4
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ExternalObject3
  model ExtObj
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

  ExtObj eo1 = ExtObj(10);
end ExternalObject3;

// Result:
// impure function ExternalObject3.ExtObj.constructor
//   input Integer i;
//   output ExternalObject3.ExtObj obj;
//
//   external "C" obj = initObject();
// end ExternalObject3.ExtObj.constructor;
//
// impure function ExternalObject3.ExtObj.destructor
//   input ExternalObject3.ExtObj obj;
//
//   external "C" destroyObject(obj);
// end ExternalObject3.ExtObj.destructor;
//
// class ExternalObject3
//   ExternalObject3.ExtObj eo1 = ExternalObject3.ExtObj.constructor(10);
// end ExternalObject3;
// endResult
