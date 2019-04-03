package ListInteractive

  public constant list<Integer> intCons = 2::3::4::5::{};
  public constant list<Integer> intList = {2,3,4,5};

  function listPrepend
    input list<Integer> intList;
    input Integer inInt;
    output list<Integer> out;
  algorithm
    out := inInt :: intList;
  end listPrepend;

  function listlistIdent
    input list<list<Integer>> intList;
    output list<list<Integer>> out;
  algorithm
    out := intList;
  end listlistIdent;

  function listlistlistIdent
    input list<list<list<Integer>>> intList;
    output list<list<list<Integer>>> out;
  algorithm
    out := intList;
  end listlistlistIdent;

  function testCompiledArrayToList
    input Integer[2] inArr;
    output list<Integer> out;
  algorithm
    out := listPrepend(inArr, 1);
  end testCompiledArrayToList;

end ListInteractive;
