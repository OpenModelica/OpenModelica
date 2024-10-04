// name: ExternalObject5
// keywords:
// status: correct
//
//

partial package Icon
  annotation(Icon());
end Icon;

class ExternalObject5
  extends ExternalObject;
  extends Icon;

  function constructor
    output ExternalObject5 obj;
    external "C" obj = initObject();
  end constructor;

  function destructor
    input ExternalObject5 obj;
    external "C" destroyObject(obj);
  end destructor;
end ExternalObject5;

// Result:
// class ExternalObject5
// end ExternalObject5;
// endResult
