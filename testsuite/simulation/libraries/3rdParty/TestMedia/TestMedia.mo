within ;
package TestMedia
  annotation (uses(Modelica(version="3.1")));
  package Media
    package Water = Modelica.Media.Water.StandardWater;
    package FlueGas =
        Modelica.Media.IdealGases.MixtureGases.FlueGasSixComponents;
    package Nitrogen = Modelica.Media.IdealGases.SingleGases.N2;
  end Media;

  package TestModels
    model TestWater
      package Medium = Media.Water;
      Medium.ThermodynamicState state;
      Medium.AbsolutePressure p;
      Medium.SpecificEnthalpy h;
      Medium.Density d;
      Medium.Temperature T;
    equation
      h = 25000+ time * 300000;
      p = 1e5;
      state = Medium.setState_ph(p,h);
      d = Medium.density(state);
      T = Medium.temperature(state);
    end TestWater;

    model TestSteam
      package Medium = Media.Water;
      Medium.ThermodynamicState state;
      Medium.AbsolutePressure p;
      Medium.SpecificEnthalpy h;
      Medium.Density d;
      Medium.Temperature T;
    equation
      h = 2.8e6+ time * 300000;
      p = 60e5;
      state = Medium.setState_ph(p,h);
      d = Medium.density(state);
      T = Medium.temperature(state);
    end TestSteam;

    model TestFlueGas
      package Medium = Media.FlueGas;
      Medium.ThermodynamicState state;
      Medium.AbsolutePressure p;
      Medium.SpecificEnthalpy h;
      Medium.Density d;
      Medium.Temperature T;
    equation
      T = 300 + 300 * time;
      p = 1e5;
      state = Medium.setState_pTX(p,T);
      d = Medium.density(state);
      h = Medium.specificEnthalpy(state);
    end TestFlueGas;

    model TestNitrogen
      package Medium = Media.Nitrogen;
      Medium.ThermodynamicState state;
      Medium.AbsolutePressure p;
      Medium.SpecificEnthalpy h;
      Medium.Density d;
      Medium.Temperature T;
    equation
      T = 300 + 300 * time;
      p = 1e5;
      state = Medium.setState_pTX(p,T);
      d = Medium.density(state);
      h = Medium.specificEnthalpy(state);
    end TestNitrogen;
  end TestModels;
end TestMedia;
