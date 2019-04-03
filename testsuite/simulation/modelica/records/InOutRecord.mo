encapsulated package TestPkg
  record R
    Boolean a = false;
    String tmp = "test";
  end R;

  function fkn
    input R r;
    output Boolean b;
  algorithm
    b := r.a;
  end fkn;

  function mk_r
    input Boolean a;
    input String b;
    output R r;
  algorithm
    r.a := a;
    r.tmp := b;
  end mk_r;

  class subm
    Boolean q;
    parameter Boolean init = false;
  equation
    q = fkn(mk_r(init, "test"));
  end subm;
end TestPkg;

class m
  Boolean q;
equation
  q = TestPkg.fkn(TestPkg.mk_r(true, "not"));
end m;

