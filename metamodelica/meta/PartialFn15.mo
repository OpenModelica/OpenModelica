// name:     PartialFn15
// keywords: PartialFn
// status:  correct
// cflags: -g=MetaModelica -d=noevalfunc,gen
//
// Using lists of function pointers
//

package PartialFn15

function elabRealBinOps
  input Real r1;
  input Real r2;
  output list<Real> lst;
protected
  partial function RealBinOp
    input Real r1;
    input Real r2;
    output Real r;
  end RealBinOp;
  list<RealBinOp> binops;
  RealBinOp binop;
algorithm
  lst := {};
  binops := {realAdd,realSub,realMul,realDiv,realPow,realMax,realMin};
  while not listEmpty(binops) loop
    lst := match binops
      case binop::binops then binop(r1,r2)::lst;
    end match;
  end while;
  lst := listReverse(lst); // Easier to read the results this way...
end elabRealBinOps;

constant list<Real> rs = elabRealBinOps(8.0, 3.0);

end PartialFn15;
// Result:
// function PartialFn15.elabRealBinOps
//   input Real r1;
//   input Real r2;
//   output list<#Real> lst;
//   protected list<.PartialFn15.elabRealBinOps.RealBinOp<function>(#Real r1, #Real r2) => #Real> binops;
//   protected binop<function>(#Real r1, #Real r2) => #Real binop;
// algorithm
//   lst := List();
//   binops := List(realAdd, realSub, realMul, realDiv, realPow, realMax, realMin);
//   while not listEmpty(binops) loop
//     lst := match (binops)
//     case (binop::binops) then listCons(binop(#(r1), #(r2)), lst);
//   end match;
//   end while;
//   lst := listReverse(lst);
// end PartialFn15.elabRealBinOps;
//
// class PartialFn15
//   constant list<#Real> rs = List(#(11.0), #(5.0), #(24.0), #(2.6666666666666665), #(512.0), #(8.0), #(3.0));
// end PartialFn15;
// endResult
