package ParFuncTest
  constant Integer globalSizes = 10;
  constant Integer localSizes = 2;
  constant Integer elements = 10;

  parallel function f
    parglobal input Integer i;
    parglobal output Integer o;
  algorithm
    o := 10*i;
    annotation(Inline=true);
  end f;

  impure function test
    input Integer a;
    output Integer result[elements];
  protected
    Integer v[elements] = {i for i in 1:elements};
    parglobal Integer pv[elements];
    parglobal Integer pr[elements];
    parglobal Integer pa;
    parglobal Integer pi;
  algorithm
    oclSetNumThreadsGlobalLocal1D({globalSizes}, {localSizes});
    pa := a;
    pv := v;
    parfor i in 1 : elements loop
      pi := i;
      pr[i] := pa * pv[i] * f(pi);
    end parfor;
    result := pr;
  end test;

  model M
    parameter Integer a = 5;
    Integer r[elements] = test(a + integer(time));
    Integer err = sum(abs(r - {(a + integer(time))*i*10*i for i in 1:elements}));
  end M;
end ParFuncTest;
