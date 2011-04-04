package SimCodeDump

import interface SimCodeTV;
import SimCodeC.*;

template dumpSimCode(SimCode code)
::=
  match code
  case sc as SIMCODE(modelInfo=mi as MODELINFO(__)) then
  <<
  SimCode: <%dotPath(mi.name)%>
  >>
end dumpSimCode;

end SimCodeDump;

// vim: filetype=susan sw=2 sts=2
