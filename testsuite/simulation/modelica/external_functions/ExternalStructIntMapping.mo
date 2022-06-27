record R
  Real x;
  Integer y;
  Integer z;
end R;

function f
  output R r;
  external "C" f_impl(r) annotation(Include="#include \"ExternalStructIntMapping.ext.h\"");
end f;

model M
  R r;
  Integer y; // Need this or the record won't be output in the result for some reason
equation
  r = f();
  y = r.y;
end M;
