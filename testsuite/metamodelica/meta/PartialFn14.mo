// name:     PartialFn14
// keywords: PartialFn
// status:  correct
//
// Using function pointers
//

package PartialFn14

function map0
  input list<Type_a> inLst;
  input FnAToNothing inFn;

  replaceable type Type_a subtypeof Any;
  partial function FnAToNothing
    input Type_a inA;
  end FnAToNothing;
algorithm
  if not listEmpty(inLst) then
    inFn(listGet(inLst,1));
    map0(listRest(inLst),inFn);
  end if;
end map0;

function printLst
  input list<String> inLst;
algorithm
  map0(inLst, print);
end printLst;

end PartialFn14;
