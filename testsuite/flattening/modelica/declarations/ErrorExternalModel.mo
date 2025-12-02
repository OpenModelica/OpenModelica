// name: ErrorExternalModel
// status: incorrect

model ErrorExternalModel
external "C";
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ErrorExternalModel;

// Result:
// Error processing file: ErrorExternalModel.mo
// [flattening/modelica/declarations/ErrorExternalModel.mo:4:1-7:23:writable] Error: Class specialization violation: .ErrorExternalModel is a model, which may not contain an external function declaration.
// Error: Error occurred while flattening model ErrorExternalModel
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
