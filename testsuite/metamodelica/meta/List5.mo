// name: List5
// cflags: +g=MetaModelica -d=-newInst
// status: correct
// suite: metamodelica
package P
uniontype UT
  record R1 end R1;
  record R2 end R2;
end UT;
end P;

class List5
  import P.UT;
  constant list<UT> lst1 = {P.R1(),P.R2()};
  constant list<UT> lst2 = P.R1()::lst1;
end List5;

// Result:
// class List5
//   constant list<P.UT> lst1 = List(P.UT.R1(), P.UT.R2());
//   constant list<P.UT> lst2 = List(P.UT.R1(), P.UT.R1(), P.UT.R2());
// end List5;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
