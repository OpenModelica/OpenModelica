package TupleInteractive

  function tupleToInt
    input tuple<Integer,Real> intRealTuple;
    output Integer out;
  algorithm
    out := 2;
  end tupleToInt;

  function tupleIdent
    input tuple<Integer,Real> intRealTuple;
    output tuple<Integer,Real> out;
  algorithm
    out := intRealTuple;
  end tupleIdent;

  function intRealToTuple
    input Integer inInt;
    input Real inReal;
    output tuple<Integer,Real> out;
  algorithm
    out := (inInt,inReal);
  end intRealToTuple;

  function tupleToMultiple
    input tuple<Integer,Real> intRealTuple;
    output Integer outInt;
    output Real outReal;
  algorithm
    outInt := 1;
    outReal := 1.5;
  end tupleToMultiple;

  function tupleToMultipleCompiled
    input tuple<Integer,Real> intRealTuple;
    output Integer outInt;
    output Real outReal;
  algorithm
    (outInt,outReal) := tupleToMultiple(intRealTuple);
  end tupleToMultipleCompiled;

end TupleInteractive;
