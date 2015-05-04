package MatchDotNotation

uniontype Union
  record REAL
    Real r;
  end REAL;
  record INT
    Integer i;
  end INT;
  record EXP
    Union u;
  end EXP;
end Union;

function f1
  input Real rx;
  output Real o;
algorithm
  o := match REAL(rx)
    local
      Union x;
    case x as REAL()
      equation
        x as _ =REAL(2*rx);
      then x.r;
  end match;
end f1;

function f2
  input Real r;
  output Real o;
algorithm
  o := match REAL(r)
    local
      Union x;
    case x as REAL()
      equation
        x = REAL(2*r);
      then x.r;
  end match;
end f2;

function f3
  input Real r;
  output Real o;
protected
  Union u;
algorithm
  u := REAL(r);
  o := match u
    case REAL() then 2*u.r;
  end match;
end f3;

function f4
  input Real r;
  output Real o;
algorithm
  o := match u as REAL(r)
    case REAL() then 2*u.r;
  end match;
end f4;

function error1
  input Real r;
  output Real o;
algorithm
  o := match REAL(r)
    local
      Union x,y;
    case x as REAL()
      equation
        y = x;
        x as REAL() = y; // TODO: Nice additional extension since the pattern constrains the type...
      then x.r;
  end match;
end error1;

function error2
  input Real r;
  output Real o;
algorithm
  o := match REAL(r)
    local
      Union x;
    case x as REAL()
      equation
        x as INT(_) = x;
      then x.r;
  end match;
end error2;

function error3
  input Real r;
  output Real o;
algorithm
  o := match REAL(r)
    local
      Union x;
    case x as REAL()
      equation
        x as _ = INT(_);
      then x.r;
  end match;
end error3;

function error4
  input Real r;
  output Real o;
algorithm
  o := match REAL(r)
    local
      Union x;
    case x as REAL()
      equation
        EXP(x) = EXP(INT(1));
      then x.r;
  end match;
end error4;

function error5
  input Real r;
  output Real o;
algorithm
  o := match u as REAL(r)
    case REAL() equation u = REAL(3.5); then 2*u.r;
  end match;
end error5;

end MatchDotNotation;
