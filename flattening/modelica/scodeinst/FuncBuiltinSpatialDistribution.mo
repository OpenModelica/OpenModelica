// name: FuncBuiltinSpatialDistribution
// keywords: spacialDistribution
// status: correct
// cflags: -d=newInst
//
// Tests the builtin spacialDistribution operator.
//

model FuncBuiltinSpatialDistribution
  Real in0;
  Real in1;
  Real out0;
  Real out1;
  Real x;
  Boolean positiveVelocity;
equation
  (out0, out1) = spatialDistribution(in0, in1, x, positiveVelocity,
    initialPoints = {0.0, 1.0}, initialValues = {0.0, 0.0});
end FuncBuiltinSpatialDistribution;

// Result:
// [/home/per/workspace/OpenModelica/OMCompiler/Compiler/NFFrontEnd/NFInst.mo:1210:9-1210:69:writable]Modelica Assert: NFInst.instExp got unknown expression!
// Error processing file: FuncBuiltinSpatialDistribution.mo
// Error: Internal error Instantiation of FuncBuiltinSpatialDistribution failed with no error message.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
