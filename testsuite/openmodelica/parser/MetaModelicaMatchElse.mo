// name: MetaModelicaMatchElse
// status: correct
// cflags: -g=MetaModelica -i=MetaModelicaMatchElse.A -d=-newInst
//
// Tests that the parser can handle all sorts of match/matchcontinue

package MetaModelicaMatchElse

function f1
  input Integer x, y, z;
algorithm
  _ := match x case 1 then ();  end match;
  _ := match (x,y,z) case 1 then (); end match;
  _ := match () case 1 then (); end match;
  _ := match (x) case 1 then fail(); else equation fail(); then 2; end match;
  _ := match (x) case 1 then fail(); else then 2; end match;
  _ := match (x) case 1 then fail(); else 2; end match;
  _ := matchcontinue x case 1 then ();  end matchcontinue;
  _ := matchcontinue (x,y,z) case 1 then (); end matchcontinue;
  _ := matchcontinue () case 1 then (); end matchcontinue;
  _ := matchcontinue (x) case 1 then fail(); else equation fail(); then 2; end matchcontinue;
  _ := matchcontinue (x) case 1 then fail(); else then 2; end matchcontinue;
  _ := matchcontinue (x) case 1 then fail(); else 2; end matchcontinue;
end f1;

class A
constant Real x = 1.0;
end A;
end MetaModelicaMatchElse;

// Result:
// class MetaModelicaMatchElse.A
//   constant Real x = 1.0;
// end MetaModelicaMatchElse.A;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
