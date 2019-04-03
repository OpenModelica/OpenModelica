// name:     Units2
// keywords: connect
// cflags: +std=2.x
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
end Units2;
// Result:
// Error processing file: Units2.mo
// [flattening/modelica/connectors/Units2.mo:24:3-24:16:writable] Error: Cannot connect flow component i.x to non-flow component v.x.
// [flattening/modelica/connectors/Units2.mo:24:3-24:16:writable] Error: The type of variables
// v type:
// connector Pin1
//   Real(unit = "V") x;
// end Pin1; and
// i type:
// connector Pin2
//   flow Real(unit = "A") x;
// end Pin2;
// are inconsistent in connect equations.
// Error: Error occurred while flattening model Units2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
