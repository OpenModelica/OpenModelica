// name: ExternalObject1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

class ExternalObject1
  extends ExternalObject;

  function constructor
    output ExternalObject1 obj;
    external "C" obj = initObject();
  end constructor;

  function destructor
    input ExternalObject1 obj;
    external "C" destroyObject(obj);
  end destructor;
end ExternalObject1;

// Result:
// class ExternalObject1
// end ExternalObject1;
// endResult
