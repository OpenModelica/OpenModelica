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
// class RecordDefaultArgMod
//   Real r.a = time;
//   Real r.b = -time;
// end RecordDefaultArgMod;
// endResult
