// status: correct

model SpliceUnknownDest

  function getVariableNameTable
    extends modelInExpressionBase;
  public
    input Integer indexModel ;
    input Integer dim;
    output String variableNameTable[dim] ;
  algorithm
     if indexModel == 1 then   // model1
      variableNameTable[1:size(model2,1)]  := model1[:];
     elseif indexModel == 2 then  // model2
      variableNameTable [1:size(model2,1)]:= model2[:];
     end if;
  end getVariableNameTable;

  function modelInExpressionBase
  protected
      final constant String model1[8] =    {"a", "b", "c", "d", "e", "f", "g","h"};
      final constant String model2[8] = {"a", "b", "c", "d", "e", "f", "g", "i"};
  end modelInExpressionBase;

  String tab[8];
equation
  tab=getVariableNameTable(2,8);
end SpliceUnknownDest;

// Result:
// function SpliceUnknownDest.getVariableNameTable
//   protected final constant String[8] model1 = {"a", "b", "c", "d", "e", "f", "g", "h"};
//   protected final constant String[8] model2 = {"a", "b", "c", "d", "e", "f", "g", "i"};
//   input Integer indexModel;
//   input Integer dim;
//   output String[dim] variableNameTable;
// algorithm
//   if indexModel == 1 then
//     variableNameTable[{1, 2, 3, 4, 5, 6, 7, 8}] := {"a", "b", "c", "d", "e", "f", "g", "h"};
//   elseif indexModel == 2 then
//     variableNameTable[{1, 2, 3, 4, 5, 6, 7, 8}] := {"a", "b", "c", "d", "e", "f", "g", "i"};
//   end if;
// end SpliceUnknownDest.getVariableNameTable;
//
// class SpliceUnknownDest
//   String tab[1];
//   String tab[2];
//   String tab[3];
//   String tab[4];
//   String tab[5];
//   String tab[6];
//   String tab[7];
//   String tab[8];
// equation
//   tab[1] = "a";
//   tab[2] = "b";
//   tab[3] = "c";
//   tab[4] = "d";
//   tab[5] = "e";
//   tab[6] = "f";
//   tab[7] = "g";
//   tab[8] = "i";
// end SpliceUnknownDest;
// endResult
