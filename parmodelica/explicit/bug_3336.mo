package ParArg
 constant Integer nx = 10;
 
  function mult
    input Real a;
    input Real m[nx];
    output Real result[nx];
  protected
    parglobal Real pa;
    parglobal Real pm[nx];
    parglobal Real presult[nx];
  algorithm
    pa := a;
    pm := m;
    parfor i in 1:nx loop
      presult[i] := pm[i]*pa;
    end parfor;
    result := presult;
  end mult;

  function multParArg
    input Real a;
    parglobal input Real mpm[nx];
    parglobal output Real mpresult[nx];
  protected
    parglobal Real pa;
  algorithm
    pa := a;
    parfor i in 1:nx loop
      mpresult[i] := mpm[i]*pa;
    end parfor;
  end multParArg;

  function Test
    input Real a;
    output Real result[nx];
  protected
    Real m[nx] = {i for i in 1:nx};
    Real pm[nx];
  algorithm
    result := mult(a,m);
  end Test;

  function TestParArg
    input Real a;
    output Real result[nx];
  protected
    Real m[nx] = {i for i in 1:nx};
    parglobal Real pa;
    parglobal Real pm[nx];
    parglobal Real presult[nx];
  algorithm
    pa := a;
    pm := m;
    presult := multParArg(pa,pm);
    result := presult;
  end TestParArg;
end ParArg;