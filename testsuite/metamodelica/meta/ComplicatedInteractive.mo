package ComplicatedInteractive

  uniontype LI2
    record RecordWithComplicatedTypes
      tuple<Real,list<tuple<Real,Option<list<Integer>>>>> rcf;
    end RecordWithComplicatedTypes;
  end LI2;

  type tupIntLI2 = tuple<Integer, LI2>;

  function listIdent
    input list<Integer> intList;
    output list<Integer> out;
  algorithm
    out := intList;
  end listIdent;

  function LI2Ident
    input LI2 ident;
    output LI2 out;
  algorithm
    out := ident;
  end LI2Ident;

  function NewComplicatedThingy
    input Option<list<Integer>> opt;
    output tupIntLI2 out;
  algorithm
    out := (4, RecordWithComplicatedTypes((1.0,{(7.5,opt)})));
  end NewComplicatedThingy;

  function listOfTuple
    input tuple<Integer,Real> i;
    output list<tuple<Integer,Real>> out;
  algorithm
    out := {i,i,i,(1,7.5),i,i};
  end listOfTuple;

end ComplicatedInteractive;
