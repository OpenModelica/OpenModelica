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
end DependsMutual;

// Result:
// class DependsMutual
//   Real x;
//   Real a.x;
// equation
//   a.x = x;
//   x = time;
// end DependsMutual;
// endResult
