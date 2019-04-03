// name:     RecordEnumBinding
// keywords: record, enumeration, #2616
// status:   correct
//
// Tests that it's possible to have enumeration variables with bindings in
// records.
//

type StepType = enumeration(invalid, charge, discharge, rest);

record StepData
  parameter StepType steptype = StepType.invalid;
end StepData;

model Controller
  parameter StepData[:] stepdef = {StepData()};
end Controller;

model RecordEnumBinding
  parameter StepData[:] stepdef = {StepData()};
  Controller controller(stepdef = stepdef);
end RecordEnumBinding;

// Result:
// function StepData "Automatically generated record constructor for StepData"
//   input enumeration(invalid, charge, discharge, rest) steptype = StepType.invalid;
//   output StepData res;
// end StepData;
//
// class RecordEnumBinding
//   parameter enumeration(invalid, charge, discharge, rest) stepdef[1].steptype = StepType.invalid;
//   parameter enumeration(invalid, charge, discharge, rest) controller.stepdef[1].steptype = stepdef[1].steptype;
// end RecordEnumBinding;
// endResult
