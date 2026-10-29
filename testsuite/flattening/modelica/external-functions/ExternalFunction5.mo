// name: ExternalFunction5
// status: correct
// teardown_command: rm -f myFloor.* myFloor_* ExternalFunction5_*

function trunc
  input Real r;
  output Real o;
external "builtin";
end trunc;

class ExternalFunction5
  Real r1 = trunc(1.5);
  Real r2 = trunc(-1.5);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ExternalFunction5;

// Result:
// class ExternalFunction5
//   Real r1 = trunc(1.5);
//   Real r2 = trunc(-1.5);
// end ExternalFunction5;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
