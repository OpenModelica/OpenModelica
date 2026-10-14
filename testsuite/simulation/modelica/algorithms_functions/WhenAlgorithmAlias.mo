model WhenAlgorithmAlias
  Real y(start = 0);
  Real z;
algorithm
  when sample(0.25, 0.5) then
    if time > 0.5 then
      y := time;
    end if;
  end when;
equation
  z = y;
end WhenAlgorithmAlias;

model WhenAlgorithmNegatedAlias
  Real y(start = 2, fixed = true);
  Real z;
  output Real a;
algorithm
  when sample(0.25, 0.5) then
    if time > 0.5 and time < 1.0 then
      y := time;
    end if;
  end when;
equation
  z = -y;
  a = z;
end WhenAlgorithmNegatedAlias;

model WhenAlgorithmConnectedAliases
  connector RealInput = input Real;
  connector RealOutput = output Real;

  block Source
    RealOutput y1(start = 2, fixed = true);
    RealOutput y2(start = 3, fixed = true);
  algorithm
    when sample(0.25, 0.5) then
      for i in 1:2 loop
        if time > 0.5 and time < 1.0 then
          if i == 1 then
            y1 := time;
          end if;
          if i == 2 then
            y2 := 2 * time;
          end if;
        end if;
      end for;
    end when;
  end Source;

  block Sink
    RealInput u[2];
    output Real v = u[1] + u[2];
  end Sink;

  Source b;
  Sink s;
equation
  connect(b.y1, s.u[1]);
  connect(b.y2, s.u[2]);
end WhenAlgorithmConnectedAliases;

model WhenAlgorithmElsewhenAlias
  Real y(start = 4, fixed = true);
  output Real z;
algorithm
  when sample(0.25, 1.0) then
    if time < 1.0 then
      if time > 0.0 then
        y := 10 * time;
      end if;
    end if;
  elsewhen sample(0.75, 1.0) then
    if time < 1.0 then
      y := 20 * time;
    end if;
  end when;
equation
  z = y;
end WhenAlgorithmElsewhenAlias;
