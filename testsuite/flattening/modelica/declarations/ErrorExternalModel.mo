// name: ErrorExternalModel
// status: incorrect
// cflags: -d=-newInst

model ErrorExternalModel
external "C";
end ErrorExternalModel;

// Result:
// Error processing file: ErrorExternalModel.mo
// [flattening/modelica/declarations/ErrorExternalModel.mo:5:1-7:23:writable] Error: Class specialization violation: .ErrorExternalModel is a model, which may not contain an external function declaration.
// Error: Error occurred while flattening model ErrorExternalModel
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
