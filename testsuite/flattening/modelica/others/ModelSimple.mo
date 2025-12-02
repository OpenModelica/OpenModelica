// name: ModelSimple
// keywords: model
// status: correct
//
// Tests simple model declaration and instantiation
//

model TestModel
  Integer i;
end TestModel;

model ModelSimple
  TestModel tm;
equation
  tm.i = 1;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ModelSimple;

// Result:
// class ModelSimple
//   Integer tm.i;
// equation
//   tm.i = 1;
// end ModelSimple;
// endResult
