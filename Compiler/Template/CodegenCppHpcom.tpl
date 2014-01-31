// This file defines template-extensions for transforming Modelica code into parallel hpcom-code.
//
// There are one root template intended to be called from the code generator:
// translateModel. These template do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).

package CodegenCppHpcom

import interface SimCodeTV;
import CodegenUtil.*;
import CodegenCpp.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)

template translateModel(SimCode simCode) ::=
  // empty result of the top-level template .., only side effects
  << //bla
  >>
end translateModel;

template update( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses,SimCode simCode, Context context)
::=
  <<
  //test
  >>
end update;

end CodegenCppHpcom;