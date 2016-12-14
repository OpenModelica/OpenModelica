package ParArray
  constant Integer globalSizes = 10;
  constant Integer localSizes = 2;
  constant Integer nx = 10;
  constant Integer ny = 10;

  function OneDim
    input Real a;
    output Real result[nx];
  protected
    parglobal Real pa;
    parglobal Real presult[nx];
  algorithm
    pa := a;
    parfor i in 1:nx loop
      presult[i] := i*pa;
    end parfor;
    result := presult;
  end OneDim;

  function TwoDim
    input Real a;
    output Real result[nx,ny];
  protected
    parglobal Real pa;
    parglobal Real presult[nx,ny];
  algorithm
    pa := a;
    parfor i in 1:nx loop
      for j in 1:ny loop
        presult[i,j] := i*j*pa;
      end for;
    end parfor;
    result := presult;
  end TwoDim;
end ParArray;
