class PreAndAliasedVar
  Real a = time;
  Real b = -a;
  Real c;
  Real d = 4;
  Real e;
equation
  when sample(0.1,0.1) then
    c = a+pre(b); // tests pre(-a)
    e = a+pre(d); // tests pre(known)
  end when;
end PreAndAliasedVar;
