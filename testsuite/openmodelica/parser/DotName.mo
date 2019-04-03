record R
  Real r;
end R;

class DotName
  constant .R r = .R(1.5);
  .DotName.Real r2 = .DotName.r;
  class R
    Integer r;
  end R;
end DotName;
