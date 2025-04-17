// name: LookupLibrary2
// keywords:
// status: incorrect
//
// Tests that missing libraries are not loaded when --loadMissingLibraries=false
//

model LookupLibrary2
  Modelica.Units.SI.Angle angle;
  annotation(__OpenModelica_commandLineOptions="--loadMissingLibraries=false");
end LookupLibrary2;

// Result:
// Error processing file: LookupLibrary2.mo
// [flattening/modelica/scodeinst/LookupLibrary2.mo:9:3-9:32:writable] Error: Class Modelica.Units.SI.Angle not found in scope LookupLibrary2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
