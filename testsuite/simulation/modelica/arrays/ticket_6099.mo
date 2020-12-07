package TestVectors
  function f1
    input Real[:] vIn;
    input Real[:, :] mIn;
    output Real[size(mIn, 2)] vOut;
  algorithm
    vOut := {1 / (mIn[:, i] * vIn) for i in 1:size(mIn, 2)};
  end f1;

  model M1
    Real[3, 2] m1 = transpose({{1, 2, 3}, {5, 10, 30}});
    Real[3] v1 = {1, 2, 3};
    Real[2] y1;
  algorithm
    y1 := f1(v1, m1);
  annotation(
      experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-6, Interval = 0.002),
      __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection");
  end M1;

  function f2
    input Real[:] v1;
    input Real[:] v2;
    input Real[:, :] m1;
    output Real[size(v2, 1)] Xout;
  protected
    Real internal;
  algorithm
    internal := sum(v2[i] / v1[i] for i in 1:size(v2, 1)) + sum({{m1[i, j] / v1[i] for j in 1:size(m1, 2)} for i in 1:size(m1, 1)});
    Xout := {v2[i] / (v1[i] * internal) for i in 1:size(v2, 1)};
  end f2;

  function f3
    input Real[:] v1;
    input Real[:] v2;
    output Real[size(v2, 1)] out;
  algorithm
    for j in 1:size(v2, 1) loop
      out[j] := (1 - v1[j] - v2[j]);
    end for;
  end f3;

  model M2
    Real[2] v1 = {1, 0.8};
    Real[2] v2 = {1, 2};
    Real[2, 1] m1 = [0.5; 0];
    Real[2] v3;
    Real[2] v4;
  algorithm
    v3 := f2(v1, v2, m1);
    v4 := f3(v2, v3);
  annotation(
      experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-6, Interval = 0.002),
      __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection");
  end M2;
end TestVectors;
