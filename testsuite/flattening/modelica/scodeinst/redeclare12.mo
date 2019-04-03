// name: redeclare12.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//


model MyInternalModel
  parameter Real par = 1;
end MyInternalModel;

model MyModel
  replaceable model ReplaceableInternalModel = MyInternalModel;
  ReplaceableInternalModel internalModel;
end MyModel;

model MyTestModel
  parameter Real localPar = 1;
  MyModel intModel(redeclare model ReplaceableInternalModel = MyInternalModel(final par = localPar));
end MyTestModel;

// Result:
// class MyTestModel
//   parameter Real localPar = 1.0;
//   final parameter Real intModel.internalModel.par = localPar;
// end MyTestModel;
// endResult
