// name: BuiltinAttribute23
// keywords:
// status: correct
//

model BuiltinAttribute23
  parameter Real x0 = 0;
  type T = Real[3] (each start = x0);
  T t;
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end BuiltinAttribute23;

// Result:
// class BuiltinAttribute23
//   parameter Real x0 = 0.0;
//   Real[3] t(start = array(x0 for $f1 in 1:3));
// end BuiltinAttribute23;
// endResult
