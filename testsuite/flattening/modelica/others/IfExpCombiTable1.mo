// name: IfExpCombiTable1
// status: correct
// This should succeed without error messages

class IfExpCombiTable1
  parameter Boolean b = false;
  Real r = if not b then 1.5 else q();
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end IfExpCombiTable1;

// Result:
// class IfExpCombiTable1
//   parameter Boolean b = false;
//   Real r = 1.5;
// end IfExpCombiTable1;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
