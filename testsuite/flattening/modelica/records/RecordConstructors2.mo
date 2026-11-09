// status: correct

model RecordConstructors2
  record R
    constant Real default = 1.5;
    Real r = default;
  end R;
  R r = R();
end RecordConstructors2;

// Result:
// class RecordConstructors2
//   constant Real r.default = 1.5;
//   Real r.r = 1.5;
// end RecordConstructors2;
// endResult
