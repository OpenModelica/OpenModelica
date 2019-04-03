package oclTest
  
  constant Integer globalSizes = 10;
  constant Integer localSizes = 2;

  parkernel function Kernel
    input Integer S;
    parglobal input Integer i[10];
    parglobal output Integer groupId[globalSizes];
    parglobal output Integer localId[globalSizes];
  protected
    Integer g;
  algorithm
    g := oclGetGlobalId(1);
    groupId[g] := oclGetGroupId(1);
    localId[g] := oclGetLocalId(1);
  end Kernel;
  
  function test
    output Integer groupId[globalSizes];
    output Integer localId[globalSizes];
  protected
    parglobal Integer p_groupId[globalSizes];
    parglobal Integer p_localId[globalSizes];
    Integer I[10];
    parglobal Integer pI[10];
  algorithm
    for i loop
      I[i] := i;
    end for;
    pI := I;
    oclSetNumThreadsGlobalLocal1D({globalSizes}, {localSizes});
      (p_groupId, p_localId) := Kernel(7,pI);
      groupId := p_groupId;
      localId := p_localId;
  end test;
end oclTest;
