// name:     RecordDefaultArgMod
// keywords: record, default argument, modifier, #2643
// status:   correct
//
// Tests that default arguments in records are properly overwritten by
// modifications.
//

model RecordDefaultArgMod
  record MyRecord
    Real a;
    Real b = 24;
  end MyRecord;

  MyRecord r = MyRecord(time, -time);
end RecordDefaultArgMod;

// Result:
// function RecordDefaultArgMod.MyRecord "Automatically generated record constructor for RecordDefaultArgMod.MyRecord"
//   input Real a;
//   input Real b = 24.0;
//   output MyRecord res;
// end RecordDefaultArgMod.MyRecord;
//
// class RecordDefaultArgMod
//   Real r.a;
//   Real r.b;
// equation
//   r.a = time;
//   r.b = -time;
// end RecordDefaultArgMod;
// endResult
