within ;
model whenInAlgorithm
  Real p_vol;
  Real V;
  Boolean b;
  Real x;
algorithm
  assert(V>0,"This is a test for assertions.",level=  AssertionLevel.warning);
  when b then
    Modelica.Utilities.Streams.print("\nThis is some debug output that needs testing.");
  end when;
  assert(p_vol<100,"This is another test for assertions.", level=  AssertionLevel.warning);

equation
  der(x) = sin(time)*2;
  V = x+1;
  p_vol = V+10;
  if x>0.5 then b = true;
  else b = false;
  end if;
  annotation(uses(Modelica(version="3.2.2")));
end whenInAlgorithm;
