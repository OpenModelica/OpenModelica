// name:     DependsMutual
// keywords: scoping
// status:   correct
//
// Mutual dependence is supported since Modelica does not require
// declare before use.
//
// Here package A depends on the class DependsMutual and
// DependsMutual depends on the package A.
//
// Obviously a model cannot contain a model that contains itself
// since that leads to recursive models.

package A
 Real x;
 model B
   DependsMutual b;
 end B;
 model C
   Real x;
 end C;
end A;

class DependsMutual
  Real x;
  A.C a;
equation
  a.x=x;
  x=time;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end DependsMutual;

// Result:
// class DependsMutual
//   Real x;
//   Real a.x;
// equation
//   a.x = x;
//   x = time;
// end DependsMutual;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
