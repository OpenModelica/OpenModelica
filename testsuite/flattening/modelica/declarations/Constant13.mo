// name: Constant13
// status: correct
// #2155 - this pattern was used in the Buildings library

model Constant13
  model DataRecord
    Real R;
    constant Real cp;
    Real cv = cp - R;
  end DataRecord;

  constant DataRecord r;
end Constant13;

// Result:
// class Constant13
//   constant Real r.R;
//   constant Real r.cp;
//   constant Real r.cv = r.cp - r.R;
// end Constant13;
// endResult
