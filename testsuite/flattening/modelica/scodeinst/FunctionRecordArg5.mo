// name: FunctionRecordArg5
// keywords:
// status: correct
//

model FunctionRecordArg5
  record BaseRecord
    constant Integer nx = 4;
  end BaseRecord;

  record ExtendRecord
    extends BaseRecord(nx=6);
  end ExtendRecord;

  function initArr
    input BaseRecord r = ExtendRecord();
    output Real x_1;
  protected
    Real x[r.nx-1];
  algorithm
    x := zeros(r.nx - 1);
    x_1 := x[1];
  end initArr;

  BaseRecord r = ExtendRecord();
  Real x_1;
equation
  x_1 = initArr(r);
end FunctionRecordArg5;

// Result:
// function FunctionRecordArg5.BaseRecord "Automatically generated record constructor for FunctionRecordArg5.BaseRecord"
//   input Integer nx = 4;
//   output BaseRecord res;
// end FunctionRecordArg5.BaseRecord;
//
// function FunctionRecordArg5.ExtendRecord "Automatically generated record constructor for FunctionRecordArg5.ExtendRecord"
//   input Integer nx = 6;
//   output ExtendRecord res;
// end FunctionRecordArg5.ExtendRecord;
//
// function FunctionRecordArg5.initArr
//   input FunctionRecordArg5.BaseRecord r = FunctionRecordArg5.ExtendRecord(6);
//   output Real x_1;
//   protected Real[r.nx - 1] x;
// algorithm
//   x := fill(0.0, r.nx - 1);
//   x_1 := x[1];
// end FunctionRecordArg5.initArr;
//
// class FunctionRecordArg5
//   constant Integer r.nx = 6;
//   Real x_1;
// equation
//   x_1 = FunctionRecordArg5.initArr(r);
// end FunctionRecordArg5;
// endResult
