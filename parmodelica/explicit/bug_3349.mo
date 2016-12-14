package ParTmp
  constant Integer arrayCnt = 2;
  parkernel function f
    parglobal input Real A[arrayCnt];
    parglobal output Real B[arrayCnt];
    parglobal output Real Tmp[arrayCnt];
  algorithm
    for
      i in oclGetGlobalId(1):oclGetGlobalSize(1):arrayCnt
    loop
      Tmp[i] := A[i]*7;
      B[i] := Tmp[i]+A[i];
    end for;
  end f;
  
  function test
    input Real d;
    output Real result[arrayCnt];
  protected
    parglobal Real pResult[arrayCnt];
    Real tmp[arrayCnt];
    parglobal Real pTmp[arrayCnt];
  algorithm
    for i loop
      tmp[i] := i;
    end for;
    pTmp := tmp;
    pResult := f(pTmp);
    result := pResult;
  end test;
end ParTmp;

