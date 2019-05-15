encapsulated package NFUnitCheck
" file:        NFUnitCheck.mo
  package:     UnitCheck
  description: This package provides everything for advanced unit checking:
                 - for all variables unspecified units get calculated if possible
                 - inconsistent equations get reported in a user friendly way
               authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)"

import DAE;

public function checkUnits
  input DAE.DAElist inDAE;
  input DAE.FunctionTree func;
  output DAE.DAElist outDAE = inDAE;
algorithm
  return;
end checkUnits;

annotation(__OpenModelica_Interface="frontend");
end NFUnitCheck;

