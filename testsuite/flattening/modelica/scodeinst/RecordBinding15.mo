// name: RecordBinding15
// keywords:
// status: correct
//

record ParamsBottom
  parameter Real bottom[3] = zeros(3);
end ParamsBottom;

record ParamsMid
  parameter ParamsBottom paramsBottom;
end ParamsMid;

record Params
  parameter ParamsMid paramsMid = ParamsMid();
end Params;

model RecordBinding15
  parameter Params params;
  parameter Real[3] r_shape = {0, 0, 0};
  parameter Real[3] lengthDirection = params.paramsMid.paramsBottom.bottom - r_shape annotation(Evaluate = true);
end RecordBinding15;

// Result:
// class RecordBinding15
//   final parameter Real params.paramsMid.paramsBottom.bottom[1] = 0.0;
//   final parameter Real params.paramsMid.paramsBottom.bottom[2] = 0.0;
//   final parameter Real params.paramsMid.paramsBottom.bottom[3] = 0.0;
//   final parameter Real r_shape[1] = 0.0;
//   final parameter Real r_shape[2] = 0.0;
//   final parameter Real r_shape[3] = 0.0;
//   final parameter Real lengthDirection[1] = 0.0;
//   final parameter Real lengthDirection[2] = 0.0;
//   final parameter Real lengthDirection[3] = 0.0;
// end RecordBinding15;
// endResult
