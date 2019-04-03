// name: SimpleTypeExtend
// keywords: inheritance
// status: incorrect
//
// Tests to make sure you cannot extend built-in types and add components
// THIS TEST SHOULD FAIL
//

model SimpleTypeExtend
  extends Real;
  Real illegalReal;
end SimpleTypeExtend;

// Result:
// class SimpleTypeExtend
//   final parameter String unit = "";
//   final parameter String quantity = "";
//   final parameter String displayUnit = "";
//   final parameter Real min = 0.0;
//   final parameter Real max = 0.0;
//   final parameter Real start = 0.0;
//   final parameter Boolean fixed = false;
//   final parameter Real nominal;
//   final parameter enumeration(never, avoid, default, prefer, always) stateSelect = StateSelect.default;
//   Real illegalReal;
// end SimpleTypeExtend;
// endResult
