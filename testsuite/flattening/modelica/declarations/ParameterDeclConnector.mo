// name: ParameterDeclConnector
// keywords: parameter
// status: incorrect
//
// Tests the parameter prefix on a connector type
//

connector ParameterConnector
  Real r;
  flow Real f;
end ParameterConnector;

class ParameterDeclConnector
  parameter ParameterConnector pc;
equation
  pc.r = 1.0;
end ParameterDeclConnector;

// Result:
// Error processing file: ParameterDeclConnector.mo
// [flattening/modelica/declarations/ParameterDeclConnector.mo:14:3-14:34:writable] Error: Invalid variability parameter on connector 'pc'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
