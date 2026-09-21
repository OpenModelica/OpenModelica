model NegatedBooleanAlias "Boolean negated alias: `!v`, not `-v`"
  Boolean u = time > 0.5;
  Boolean nu;
  Integer k(start = 0, fixed = true);
  Real y;
equation
  nu = not u;
  y = if nu then 1.0 else 2.0;
  when sample(0.1, 0.1) then
    k = pre(k) + (if pre(nu) then 1 else 0);
  end when;
end NegatedBooleanAlias;
