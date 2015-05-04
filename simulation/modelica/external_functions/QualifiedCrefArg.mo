model QualifiedCrefArg
  record R
    Real x;
    Real y;
  end R;

  impure function f
    input R ri = R(1.0, 2.0);
    output R r;
    external "C" r.y = f_ext(ri.x, ri.y, r) annotation(Library = "QualifiedCrefArg-f.o");
  end f;

  R r1 = f(R(2.0, 3.0));
  R r2 = f();
end QualifiedCrefArg;
