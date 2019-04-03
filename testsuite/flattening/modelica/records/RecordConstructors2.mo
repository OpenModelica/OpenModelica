// status: correct

model RecordConstructors2
  record R
    constant Real default = 1.5;
    Real r = default;
  end R;
  R r = R();
end RecordConstructors2;

// Result:
// function RecordConstructors2.R "Automatically generated record constructor for RecordConstructors2.R"
//   input Real r = 1.5;
//   protected Real default = 1.5;
//   output R res;
// end RecordConstructors2.R;
//
// class RecordConstructors2
//   constant Real r.default = 1.5;
//   Real r.r = 1.5;
// end RecordConstructors2;
// endResult
