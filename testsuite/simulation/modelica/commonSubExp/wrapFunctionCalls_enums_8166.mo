model logical_op
  model _or
    input CRML.ETL.Types.Boolean4 R1;
    input CRML.ETL.Types.Boolean4 R2;
    output CRML.ETL.Types.Boolean4 out;
  equation
    out = CRML.Blocks.Logical4.not4(CRML.Blocks.Logical4.not4(CRML.Blocks.Logical4.and4(R1, CRML.Blocks.Logical4.not4(R2))));
  end _or;

  model _xor
    input CRML.ETL.Types.Boolean4 R1;
    input CRML.ETL.Types.Boolean4 R2;
    output CRML.ETL.Types.Boolean4 out;
    _or _or0(R1 = R1, R2 = R2);
  equation
    out = CRML.Blocks.Logical4.and4(_or0.out, CRML.Blocks.Logical4.not4(CRML.Blocks.Logical4.and4(R1, R2)));
  end _xor;

  CRML.ETL.Types.Boolean4 R1 = CRML.ETL.Types.Boolean4.true4;
  CRML.ETL.Types.Boolean4 R2 = CRML.ETL.Types.Boolean4.false4;
  CRML.ETL.Types.Boolean4 R3 = _xor2.out;
  _xor _xor2(R1 = R1, R2 = R2);
  // annotation(__OpenModelica_commandLineOptions = "+postOptModules-=wrapFunctionCalls");
end logical_op;

package CRML
  package Blocks
    package Logical4
      function and4 "Boolean4 and operator"
        import CRML.ETL.Types.Boolean4;
        input Boolean4 x1;
        input Boolean4 x2;
        output Boolean4 y;
      algorithm
        y := TruthTables.and4[Integer(x1), Integer(x2)];
      end and4;

      function not4 "Boolean4 not operator"
        import CRML.ETL.Types.Boolean4;
        input Boolean4 x;
        output Boolean4 y;
      algorithm
        y := TruthTables.not4[Integer(x)];
      end not4;

      package TruthTables
        import CRML.ETL.Types.Boolean4;
        constant Boolean4[4, 4] and4 = [Boolean4.undefined, Boolean4.undecided, Boolean4.false4, Boolean4.true4; Boolean4.undecided, Boolean4.undecided, Boolean4.false4, Boolean4.undecided; Boolean4.false4, Boolean4.false4, Boolean4.false4, Boolean4.false4; Boolean4.true4, Boolean4.undecided, Boolean4.false4, Boolean4.true4];
        constant Boolean4[4] not4 = {Boolean4.undefined, Boolean4.undecided, Boolean4.true4, Boolean4.false4};
      end TruthTables;
    end Logical4;
  end Blocks;

  package ETL
    package Types
      type Boolean4 = enumeration(undefined, undecided, false4, true4) "4-valued logic";
    end Types;
  end ETL;
end CRML;

model logical_op_total
  extends logical_op;
end logical_op_total;
