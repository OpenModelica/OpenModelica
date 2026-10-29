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
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Constant13;

// Result:
// class Constant13
//   constant Real r.R;
//   constant Real r.cp;
//   constant Real r.cv = r.cp - r.R;
// end Constant13;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
