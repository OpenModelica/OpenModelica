package CRMLtoModelica "Stand-in for the CRMLtoModelica library of the CRML repository: only what the bindings test uses"
  package Types
    type Boolean4 = enumeration(undefined, undecided, false4, true4) "4-valued logic";
  end Types;

  package Functions
    function not4
      input CRMLtoModelica.Types.Boolean4 x;
      output CRMLtoModelica.Types.Boolean4 y;
    algorithm
      y := if x == CRMLtoModelica.Types.Boolean4.true4 then CRMLtoModelica.Types.Boolean4.false4
           elseif x == CRMLtoModelica.Types.Boolean4.false4 then CRMLtoModelica.Types.Boolean4.true4 else x;
    end not4;

    function and4
      input CRMLtoModelica.Types.Boolean4 x1;
      input CRMLtoModelica.Types.Boolean4 x2;
      output CRMLtoModelica.Types.Boolean4 y;
    algorithm
      y := if x1 == CRMLtoModelica.Types.Boolean4.false4 or x2 == CRMLtoModelica.Types.Boolean4.false4 then CRMLtoModelica.Types.Boolean4.false4
           elseif x1 == CRMLtoModelica.Types.Boolean4.undecided or x2 == CRMLtoModelica.Types.Boolean4.undecided then CRMLtoModelica.Types.Boolean4.undecided
           elseif x1 == CRMLtoModelica.Types.Boolean4.undefined then x2
           elseif x2 == CRMLtoModelica.Types.Boolean4.undefined then x1
           else CRMLtoModelica.Types.Boolean4.true4;
    end and4;
  end Functions;

  package Blocks
    model setAnd
      input CRMLtoModelica.Types.Boolean4[:] r1;
      output CRMLtoModelica.Types.Boolean4 out;
    algorithm
      out := CRMLtoModelica.Types.Boolean4.undefined;
      for i in 1:size(r1, 1) loop
        out := CRMLtoModelica.Functions.and4(out, r1[i]);
      end for;
    end setAnd;
  end Blocks;
end CRMLtoModelica;
