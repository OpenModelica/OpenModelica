// name:     Units2
// keywords: connect
// status:   incorrect
//
// Connections of flow variables with non-flow variables are not
// possible.
//

type Voltage = Real(unit = "V");
type Current = Real(unit = "A");


connector Pin1
  Voltage x;
end Pin1;
connector Pin2
  flow Current x;
end Pin2;
model Units2
  Pin1 v;
  Pin2 i;
equation
  connect(v, i);
  annotation(__OpenModelica_commandLineOptions="+std=2.x");
end Units2;
// Result:
// Error processing file: Units2.mo
// [flattening/modelica/connectors/Units2.mo:20:3-20:9:writable] Warning: Connector v is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/connectors/Units2.mo:21:3-21:9:writable] Warning: Connector i is not balanced: The number of potential variables (0) is not equal to the number of flow variables (1).
// [flattening/modelica/connectors/Units2.mo:23:3-23:16:writable] Error: The connectors in connect(v, i) are not type compatible.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
