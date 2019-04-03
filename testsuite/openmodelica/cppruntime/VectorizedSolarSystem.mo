package Vectorized
  import SI = Modelica.SIunits;

  connector Terminal
    SI.Voltage v;
    flow SI.Current i;
  end Terminal;

  model SolarPlant
    input Boolean on "Plant status";
    input SI.Power P_solar "Solar power";
    parameter Real eta = 0.9 "Efficiency";
    Terminal term;
  equation
    term.v * term.i =
      if on then eta * P_solar else 0;
  end SolarPlant;

  model Collector
    parameter Integer n;
    parameter SI.Voltage V = 1000;
    output SI.Power P_grid;
    Terminal terms[n];
  equation
    //terms.v = fill(V, n); // don't use to avoid expansion
    for i in 1:n loop
      terms[i].v = V;
    end for;
    0 = P_grid + terms.v * terms.i;
  end Collector;

  model SolarSystem
    parameter Integer n = 1000;
    SolarPlant plant[n](
      each on = true,
      P_solar = 100:100:n*100);
    Collector grid(n = n);
  equation
    connect(plant.term, grid.terms);
  end SolarSystem;

end Vectorized;

model VectorizedSolarSystemTest = Vectorized.SolarSystem;
