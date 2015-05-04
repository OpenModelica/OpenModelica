record R
  Real r;
end R;

class DotName
  import .A;
  import .A.B;
  import a = .A;
  import b = .A.B;
  import .A.B.C.*;
  constant .R r = .R(1.5);
  .DotName.Real r2 = .DotName.r;
  class R
    Integer r;
  end R;
end DotName;
