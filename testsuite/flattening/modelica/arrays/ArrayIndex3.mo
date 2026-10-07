// name:     ArrayIndex
// keywords: array, index
// status:   correct
//
// This is a simple test of basic array handling. Bug reported by Hannes Edinger
//

class myTestClass
  connector acausalConnectorR
    Real value;
    flow Real f;
  end acausalConnectorR;

  class encapsulatedArrayR2
    acausalConnectorR IN;
    acausalConnectorR OUT;
  protected
    Real v[3]={1.1,2.2,3.3};
  equation
    OUT.value=v[integer(IN.value)];
  end encapsulatedArrayR2;

  class someThingR
    parameter Real value=2.7;
    acausalConnectorR OUT;
  equation
    OUT.value=value;
  end someThingR;

  model a2
    encapsulatedArrayR2 myTable;
    someThingR mySomeThingR;
  equation
    connect(mySomeThingR.OUT,myTable.IN);
  end a2;

end myTestClass;
model myTestClass_a2
  extends myTestClass.a2;
end myTestClass_a2;
// Result:
// class myTestClass_a2
//   Real myTable.IN.value;
//   Real myTable.IN.f;
//   Real myTable.OUT.value;
//   Real myTable.OUT.f;
//   protected Real myTable.v[1];
//   protected Real myTable.v[2];
//   protected Real myTable.v[3];
//   parameter Real mySomeThingR.value = 2.7;
//   Real mySomeThingR.OUT.value;
//   Real mySomeThingR.OUT.f;
// equation
//   mySomeThingR.OUT.value = myTable.IN.value;
//   myTable.OUT.f = 0.0;
//   mySomeThingR.OUT.f + myTable.IN.f = 0.0;
//   myTable.v = {1.1, 2.2, 3.3};
//   myTable.OUT.value = myTable.v[integer(myTable.IN.value)];
//   mySomeThingR.OUT.value = mySomeThingR.value;
// end myTestClass_a2;
// [flattening/modelica/arrays/ArrayIndex3.mo:15:5-15:25:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/ArrayIndex3.mo:16:5-16:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/ArrayIndex3.mo:18:5-18:28:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/ArrayIndex3.mo:20:5-20:35:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/arrays/ArrayIndex3.mo:24:5-24:29:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/ArrayIndex3.mo:25:5-25:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/ArrayIndex3.mo:27:5-27:20:writable] Warning: Equation sections are deprecated in class.
//
// endResult
