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
end ExternalFunction5;

// Result:
// class ExternalFunction5
//   Real r1 = trunc(1.5);
//   Real r2 = trunc(-1.5);
// end ExternalFunction5;
// endResult
