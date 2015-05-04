// name:     ExternalObjectVariableModel.mo [#2356]
// keywords: Test that we can use an object with variables as input
// status:   correct
//

package ExtObj
class Object
  extends ExternalObject;

  function constructor
    input Integer someNumber;
    output Object obj;
    external "C" obj = create(someNumber) annotation(Include = "#include \"mainfunctions.h\"", Library = {"libexternalObject.a"});
  end constructor;

  function destructor
    input Object obj;
    external "C" destroy(obj) ;
  end destructor;
end Object;
end ExtObj;

model ExternalObjectVariableModel
  Integer a = 1;
  parameter Integer b = 2;
  ExtObj.Object obj = ExtObj.Object(a);
end ExternalObjectVariableModel;

// Result:
// function ExtObj.Object.constructor
//   input Integer someNumber;
//   output ExtObj.Object obj;
//
//   external "C" obj = create(someNumber);
// end ExtObj.Object.constructor;
//
// function ExtObj.Object.destructor
//   input ExtObj.Object obj;
//
//   external "C" destroy(obj);
// end ExtObj.Object.destructor;
//
// class ExternalObjectVariableModel
//   Integer a = 1;
//   parameter Integer b = 2;
//   ExtObj.Object obj = ExtObj.Object.constructor(a);
// end ExternalObjectVariableModel;
// [flattening/modelica/others/ExternalObjectVariable.mo:26:3-26:39:writable] Warning: OpenModelica requires that all external objects input arguments are possible to evaluate before initialization in order to avoid odd run-time failures, but a is a variable.
//
// endResult
