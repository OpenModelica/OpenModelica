within ;
package TestMedia
  package Media
    package WaterIF97
       extends Modelica.Media.Water.StandardWater;
    end WaterIF97;

    package ColdWater
       extends Modelica.Media.CompressibleLiquids.LinearColdWater;
    end ColdWater;

    package FlueGas
      extends Modelica.Media.IdealGases.MixtureGases.FlueGasSixComponents;
    end FlueGas;

    package Nitrogen
       extends Modelica.Media.IdealGases.SingleGases.N2;
    end Nitrogen;
  end Media;

  package TestModels
    package WaterIF97 "Test suite for the IF97 water model"
      model Test1 "Simple test case with setState_ph"
        package Medium = Media.WaterIF97;
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
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test1;

      model Test2
        "Test case with state records, subcooled and superheated conditions"
        package Medium = Media.WaterIF97;

        Medium.AbsolutePressure p1;
        Medium.SpecificEnthalpy h1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T2;

        Medium.ThermodynamicState state1;
        Medium.ThermodynamicState state2;

        TestMedia.CompleteModels.CompleteThermodynamicState_ph
          completeState1(redeclare package Medium = Medium, state=state1);
        TestMedia.CompleteModels.CompleteThermodynamicState_ph
          completeState2(redeclare package Medium = Medium, state=state2);
        CompleteModels.CompleteFluidConstants completeConstants(
          redeclare package Medium = Medium);

      equation
        state1 = Medium.setState_ph(p1, h1);
        state2 = Medium.setState_pT(p2, T2);

        p1 = 1e5;
        h1 = 1e5+2e5*time;
        p2 = 1e5;
        T2 = 400 + 50*time;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test2;

      model Test3
        "Test case with state records, two-phase and supercritical conditions"
        package Medium = Media.WaterIF97;

        Medium.AbsolutePressure p1;
        Medium.SpecificEnthalpy h1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T2;

        Medium.ThermodynamicState state1;
        Medium.ThermodynamicState state2;

        TestMedia.CompleteModels.CompleteThermodynamicState_ph
          completeState1(redeclare package Medium = Medium, state=state1);
        TestMedia.CompleteModels.CompleteThermodynamicState_ph
          completeState2(redeclare package Medium = Medium, state=state2);
        CompleteModels.CompleteFluidConstants completeConstants(
          redeclare package Medium = Medium);
      equation
        state1 = Medium.setState_ph(p1, h1);
        state2 = Medium.setState_pT(p2, T2);

        p1 = 1e5;
        h1 = 1e5+3e6*time;
        p2 = 1e6+23e6*time;
        T2 = 700;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test3;

      model Test4 "Test case with state + sat records"
        package Medium = Media.WaterIF97;

        Medium.AbsolutePressure p1;
        Medium.SpecificEnthalpy h1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T2;

        Medium.ThermodynamicState state1;
        Medium.ThermodynamicState state2;
        Medium.SaturationProperties sat1;
        Medium.SaturationProperties sat2;

        Medium.Temperature Ts;
        Medium.AbsolutePressure ps;

        TestMedia.CompleteModels.CompleteThermodynamicState_ph
          completeState1(redeclare package Medium = Medium, state=state1);
        TestMedia.CompleteModels.CompleteThermodynamicState_ph
          completeState2(redeclare package Medium = Medium, state=state2);
        CompleteModels.CompleteSaturationProperties
          completeSat1(redeclare package Medium = Medium, sat=sat1);
        CompleteModels.CompleteSaturationProperties
          completeSat2(redeclare package Medium = Medium, sat=sat2);
        CompleteModels.CompleteBubbleDewStates
          completeBubbleDewStates1(redeclare package Medium = Medium, sat=sat1);
        CompleteModels.CompleteBubbleDewStates
          completeBubbleDewStates2(redeclare package Medium = Medium, sat=sat2);
        CompleteModels.CompleteFluidConstants completeConstants(
          redeclare package Medium = Medium);
      equation
        state1 = Medium.setState_ph(p1, h1);
        state2 = Medium.setState_pT(p2, T2);
        sat1 = Medium.setSat_p(p1);
        sat2 = Medium.setSat_T(T2);

        Ts = Medium.saturationTemperature(p1);
        ps = Medium.saturationPressure(T2);

        p1 = 1e5+2e5*time;
        h1 = 1e5+2e5*time;
        p2 = 1e5;
        T2 = 300 + 50*time;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test4;

      model Test5
        "Test case using BaseProperties and explicit equations, subcooled and superheated conditions"
        package Medium = Media.WaterIF97;

        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium1(redeclare package Medium
            =                                                                    Medium)
          "Constant pressure, varying enthalpy";
        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium2(redeclare package Medium
            =                                                                    Medium)
          "Varying pressure, constant enthalpy";
        CompleteModels.CompleteFluidConstants completeConstants(
          redeclare package Medium = Medium);
        Medium.AbsolutePressure p1;
        Medium.AbsolutePressure p2;
        Medium.SpecificEnthalpy h1;
        Medium.SpecificEnthalpy h2;
      equation
        medium1.baseProperties.p = p1;
        medium1.baseProperties.h = h1;
        medium2.baseProperties.p = p2;
        medium2.baseProperties.h = h2;

        p1 = 1e5+2e5*time;
        h1 = 1e5+2e5*time;
        p2 = 1e5;
        h2 = 3e6 + 2e5*time;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test5;

      model Test6
        "Test case using BaseProperties and explicit equations, two-phase and supercritical conditions"
        package Medium = Media.WaterIF97;

        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium1(redeclare package Medium
            =                                                                    Medium)
          "Constant pressure, varying enthalpy";
        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium2(redeclare package Medium
            =                                                                    Medium)
          "Varying pressure, constant enthalpy";
       CompleteModels.CompleteFluidConstants completeConstants(
          redeclare package Medium = Medium);
        Medium.AbsolutePressure p1;
        Medium.AbsolutePressure p2;
        Medium.SpecificEnthalpy h1;
        Medium.SpecificEnthalpy h2;
      equation
        medium1.baseProperties.p = p1;
        medium1.baseProperties.h = h1;
        medium2.baseProperties.p = p2;
        medium2.baseProperties.h = h2;

        p1 = 1e5;
        h1 = 1e5+3e6*time;
        p2 = 1e6+23e6*time;
        h2 = 3.2e6;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test6;

      model Test7 "Test case using BaseProperties and implicit equations"
        package Medium = Media.WaterIF97;
        parameter Medium.SpecificEnthalpy hstart = 1e5
          "Start value for specific enthalpy";
        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium1(redeclare package Medium
            =                                                                    Medium,
                                       baseProperties(h(start = hstart)))
          "Constant pressure, varying enthalpy";
        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium2(redeclare package Medium
            =                                                                    Medium,
                                       baseProperties(h(start = hstart)))
          "Varying pressure, constant enthalpy";
        CompleteModels.CompleteFluidConstants completeConstants(
          redeclare package Medium = Medium);
        Medium.AbsolutePressure p1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T1;
        Medium.Temperature T2;
      equation
        medium1.baseProperties.p = p1;
        medium1.baseProperties.T = T1;
        medium2.baseProperties.p = p2;
        medium2.baseProperties.T = T2;

        p1 = 1e5+1e5*time;
        T1 = 300 + 25*time;
        p2 = 1e5+1e5*time;
        T2 = 300;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test7;

    model Test8
        "Test case using BaseProperties, dynamic equations, state selection and derivative annotations"
      package Medium = Media.WaterIF97;

      parameter Modelica.SIunits.Volume V=1 "Storage Volume";
      parameter Real p_atm = 101325 "Atmospheric pressure";
      parameter Modelica.SIunits.Temperature Tstart=300;
      parameter Modelica.SIunits.SpecificEnthalpy hstart=1e5;
      parameter Modelica.SIunits.Pressure pstart=p_atm;
      parameter Real Kv0 = 1.00801e-2 "Valve flow coefficient";
      Medium.BaseProperties medium(preferredMediumStates = true,
                                   h(start=hstart),
                                   p(start = pstart));
      Modelica.SIunits.Mass M;
      Modelica.SIunits.Energy U;
      Modelica.SIunits.MassFlowRate win(start=100);
      Modelica.SIunits.MassFlowRate wout;
      Modelica.SIunits.SpecificEnthalpy hin;
      Modelica.SIunits.SpecificEnthalpy hout;
      Modelica.SIunits.Power Q;
      Real Kv;
    equation
      // Mass & energy balance equation
      M = medium.d*V;
      U = medium.u*M;
      der(M) = win - wout;
      der(U) = win*hin - wout*hout + Q;

      // Outlet valve equation
      wout = Kv * sqrt(medium.d*(medium.p - p_atm));
      hout = medium.h;

    initial equation
      // Steady state equations
      der(medium.p) = 0;
      der(medium.h) = 0;

    equation
      // Inlet pump equations
      medium.p - p_atm = 2e5 - (1e5/100^2)*win^2;
      hin = 1e5;

      // Input variables
      Kv = if time<50 then Kv0 else Kv0*1.1;
      Q = if time < 1 then 0 else 1e7;
      annotation (experiment(StartTime = 0, StopTime=80, NumberOfIntervals=1000));
    end Test8;



    end WaterIF97;

    package ColdWater "Test suite for linear water model"

      model Test1 "Test case with state records"
        package Medium = Media.ColdWater;

        Medium.AbsolutePressure p1;
        Medium.SpecificEnthalpy h1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T2;

        Medium.ThermodynamicState state1;
        Medium.ThermodynamicState state2;

        Medium.Density d1;
        Medium.Density d2;

      equation
        state1 = Medium.setState_ph(p1, h1);
        state2 = Medium.setState_pT(p2, T2);

        d1 = Medium.density(state1);
        d2 = Medium.density(state2);

        p1 = 1e5;
        h1 = 1e5+2e5*time;
        p2 = 1e5;
        T2 = 300 + 50*time;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test1;

      model Test2
        "Test case with state records, subcooled and superheated conditions"
        package Medium = Media.ColdWater;

        Medium.AbsolutePressure p1;
        Medium.SpecificEnthalpy h1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T2;

        Medium.ThermodynamicState state1;
        Medium.ThermodynamicState state2;

        TestMedia.CompleteModels.CompleteThermodynamicState_ph
          completeState1(redeclare package Medium = Medium, state=state1);
        TestMedia.CompleteModels.CompleteThermodynamicState_ph
          completeState2(redeclare package Medium = Medium, state=state2);
      equation
        state1 = Medium.setState_ph(p1, h1);
        state2 = Medium.setState_pT(p2, T2);

        p1 = 1e5;
        h1 = 1e5+2e5*time;
        p2 = 1e5;
        T2 = 300 + 50*time;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test2;

      model Test3 "Test case using BaseProperties and explicit equations"
        package Medium = Media.ColdWater;
        parameter Medium.SpecificEnthalpy hstart = 1e5
          "Start value for specific enthalpy";
        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium1(redeclare package Medium
            =                                                                    Medium,
                                       baseProperties(h(start = hstart)))
          "Constant pressure, varying enthalpy";
        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium2(redeclare package Medium
            =                                                                    Medium,
                                       baseProperties(h(start = hstart)))
          "Varying pressure, constant enthalpy";
        Medium.AbsolutePressure p1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T1;
        Medium.Temperature T2;
      equation
        medium1.baseProperties.p = p1;
        medium1.baseProperties.T = T1;
        medium2.baseProperties.p = p2;
        medium2.baseProperties.T = T2;

        p1 = 1e5+1e5*time;
        T1 = 300 + 25*time;
        p2 = 1e5+1e5*time;
        T2 = 300;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test3;

      model Test4 "Test case using BaseProperties and implicit equations"
        package Medium = Media.ColdWater;

        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium1(redeclare package Medium
            =                                                                    Medium)
          "Constant pressure, varying enthalpy";
        TestMedia.CompleteModels.CompleteBaseProperties_ph
                                              medium2(redeclare package Medium
            =                                                                    Medium)
          "Varying pressure, constant enthalpy";
        Medium.AbsolutePressure p1;
        Medium.AbsolutePressure p2;
        Medium.SpecificEnthalpy h1;
        Medium.SpecificEnthalpy h2;
      equation
        medium1.baseProperties.p = p1;
        medium1.baseProperties.h = h1;
        medium2.baseProperties.p = p2;
        medium2.baseProperties.h = h2;

        p1 = 1e5+2e5*time;
        h1 = 1e5+2e5*time;
        p2 = 1e5;
        h2 = 3e6 + 2e5*time;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test4;
    end ColdWater;

    package Nitrogen "Test suite for the NASA model of nitrogen"

      model Test1
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
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test1;

      model Test2 "Test case with state records"
        package Medium = Media.Nitrogen;

        Medium.AbsolutePressure p1;
        Medium.SpecificEnthalpy h1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T2;

        Medium.ThermodynamicState state1;
        Medium.ThermodynamicState state2;

        TestMedia.CompleteModels.CompleteThermodynamicState_pTX
          completeState1(redeclare package Medium = Medium, state=state1);
        TestMedia.CompleteModels.CompleteThermodynamicState_pTX
          completeState2(redeclare package Medium = Medium, state=state2);
      equation
        state1 = Medium.setState_phX(p1, h1);
        state2 = Medium.setState_pTX(p2, T2);

        p1 = 1e5;
        h1 = 3e5+1e5*time;
        p2 = 1e5+1e5*time;
        T2 = 400 + 50*time;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test2;

      model Test3 "Test case with baseProperties and explicit equations"
        package Medium = Media.Nitrogen;

        parameter Medium.SpecificEnthalpy hstart = 1e5
          "Start value for specific enthalpy";
        CompleteModels.CompleteBaseProperties_pTX
          medium1(redeclare package Medium = Medium);
        CompleteModels.CompleteBaseProperties_pTX
          medium2(redeclare package Medium = Medium);
        Medium.AbsolutePressure p1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T1;
        Medium.Temperature T2;
      equation
        medium1.baseProperties.p = p1;
        medium1.baseProperties.T = T1;
        medium2.baseProperties.p = p2;
        medium2.baseProperties.T = T2;

        p1 = 1e5+1e5*time;
        T1 = 300 + 25*time;
        p2 = 1e5+1e5*time;
        T2 = 300;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test3;

      model Test4 "Test case with baseProperties and implicit equations"
        package Medium = Media.Nitrogen;

        parameter Medium.SpecificEnthalpy hstart = 1e5
          "Start value for specific enthalpy";
        CompleteModels.CompleteBaseProperties_pTX
          medium1(redeclare package Medium = Medium);
        CompleteModels.CompleteBaseProperties_pTX
          medium2(redeclare package Medium = Medium);
        Medium.AbsolutePressure p1;
        Medium.AbsolutePressure p2;
        Medium.SpecificEnthalpy h1;
        Medium.SpecificEnthalpy h2;
      equation
        medium1.baseProperties.p = p1;
        medium1.baseProperties.h = h1;
        medium2.baseProperties.p = p2;
        medium2.baseProperties.h = h2;

        p1 = 1e5;
        h1 = 3e5+1e5*time;
        p2 = 1e5+1e5*time;
        h2 = 3e5;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test4;
    end Nitrogen;

    package FlueGas "Test suite for the 6-component NASA model of flue gas"

      model Test1
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
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test1;

      model Test2 "Test case with state records"
        package Medium = Media.FlueGas;

        Medium.AbsolutePressure p1;
        Medium.SpecificEnthalpy h1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T2;

        Medium.ThermodynamicState state1;
        Medium.ThermodynamicState state2;

        TestMedia.CompleteModels.CompleteThermodynamicState_pTX
          completeState1(redeclare package Medium = Medium, state=state1);
        TestMedia.CompleteModels.CompleteThermodynamicState_pTX
          completeState2(redeclare package Medium = Medium, state=state2);
      equation
        state1 = Medium.setState_phX(p1, h1);
        state2 = Medium.setState_pTX(p2, T2);

        p1 = 1e5;
        h1 = 3e5+1e5*time;
        p2 = 1e5+1e5*time;
        T2 = 400 + 50*time;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test2;

      model Test3 "Test case with baseProperties and explicit equations"
        package Medium = Media.FlueGas;

        parameter Medium.SpecificEnthalpy hstart = 1e5
          "Start value for specific enthalpy";
        CompleteModels.CompleteBaseProperties_pTX
          medium1(redeclare package Medium = Medium);
        CompleteModels.CompleteBaseProperties_pTX
          medium2(redeclare package Medium = Medium);
        Medium.AbsolutePressure p1;
        Medium.AbsolutePressure p2;
        Medium.Temperature T1;
        Medium.Temperature T2;
      equation
        medium1.baseProperties.p = p1;
        medium1.baseProperties.T = T1;
        medium1.baseProperties.Xi = Medium.reference_X[1:Medium.nXi];
        medium2.baseProperties.p = p2;
        medium2.baseProperties.T = T2;
        medium2.baseProperties.Xi = Medium.reference_X[1:Medium.nXi];

        p1 = 1e5+1e5*time;
        T1 = 300 + 25*time;
        p2 = 1e5+1e5*time;
        T2 = 300;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test3;

      model Test4 "Test case with baseProperties and implicit equations"
        package Medium = Media.FlueGas;

        parameter Medium.SpecificEnthalpy hstart = 1e5
          "Start value for specific enthalpy";
        CompleteModels.CompleteBaseProperties_pTX
          medium1(redeclare package Medium = Medium);
        CompleteModels.CompleteBaseProperties_pTX
          medium2(redeclare package Medium = Medium);
        Medium.AbsolutePressure p1;
        Medium.AbsolutePressure p2;
        Medium.SpecificEnthalpy h1;
        Medium.SpecificEnthalpy h2;
      equation
        medium1.baseProperties.p = p1;
        medium1.baseProperties.h = h1;
        medium1.baseProperties.Xi = Medium.reference_X[1:Medium.nXi];
        medium2.baseProperties.p = p2;
        medium2.baseProperties.h = h2;
        medium2.baseProperties.Xi = Medium.reference_X[1:Medium.nXi];

        p1 = 1e5;
        h1 = 3e5+1e5*time;
        p2 = 1e5+1e5*time;
        h2 = 3e5;
        annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
      end Test4;
    end FlueGas;
  end TestModels;

  partial package CompleteModels
    "Models to compute all available thermodynamic properties from medium models"
    model CompleteFluidConstants "Compute all available medium fluid constants"
      replaceable package Medium =
          Modelica.Media.Interfaces.PartialMedium;

      // Fluid constants
      Medium.Temperature Tc = Medium.fluidConstants[1].criticalTemperature;
      Medium.AbsolutePressure pc = Medium.fluidConstants[1].criticalPressure;
      Medium.MolarVolume vc = Medium.fluidConstants[1].criticalMolarVolume;
      Medium.MolarMass MM = Medium.fluidConstants[1].molarMass;
    end CompleteFluidConstants;

    model CompleteThermodynamicState_ph
      "Compute all available medium properties from a ThermodynamicState model"
      replaceable package Medium =
          Modelica.Media.Interfaces.PartialMedium;

      // ThermodynamicState record
      input Medium.ThermodynamicState state;

      // Medium properties
      Medium.AbsolutePressure p =                Medium.pressure(state);
      Medium.SpecificEnthalpy h =                Medium.specificEnthalpy(state);
      Medium.Temperature T =                     Medium.temperature(state);
      Medium.Density d =                         Medium.density(state);
      Medium.SpecificEntropy s =                 Medium.specificEntropy(state);
      Medium.SpecificHeatCapacity cp =           Medium.specificHeatCapacityCp(state);
      Medium.SpecificHeatCapacity cv =           Medium.specificHeatCapacityCv(state);
    // Not yet implemented in FluidProp
      Medium.IsobaricExpansionCoefficient beta = Medium.isobaricExpansionCoefficient(state);
      Modelica.SIunits.IsothermalCompressibility kappa=
          Medium.isothermalCompressibility(state);
      Medium.DerDensityByPressure d_d_dp_h =     Medium.density_derp_h(state);
      Medium.DerDensityByEnthalpy d_d_dh_p =     Medium.density_derh_p(state);
      Medium.MolarMass MM =                      Medium.molarMass(state);
    end CompleteThermodynamicState_ph;

    model CompleteThermodynamicState_pTX
      "Compute all available two-phase medium properties from a ThermodynamicState model"
      replaceable package Medium =
          Modelica.Media.Interfaces.PartialMedium;

      // ThermodynamicState record
      input Medium.ThermodynamicState state;

      // Medium properties
      Medium.AbsolutePressure p =                Medium.pressure(state);
      Medium.SpecificEnthalpy h =                Medium.specificEnthalpy(state);
      Medium.Temperature T =                     Medium.temperature(state);
      Medium.Density d =                         Medium.density(state);
      Medium.SpecificEntropy s =                 Medium.specificEntropy(state);
      Medium.SpecificHeatCapacity cp =           Medium.specificHeatCapacityCp(state);
      Medium.SpecificHeatCapacity cv =           Medium.specificHeatCapacityCv(state);
    // Not yet implemented in FluidProp
      Medium.IsobaricExpansionCoefficient beta = Medium.isobaricExpansionCoefficient(state);
      Modelica.SIunits.IsothermalCompressibility kappa=
          Medium.isothermalCompressibility(state);
      Medium.DerDensityByPressure d_d_dp_T =     Medium.density_derp_T(state);
      Medium.DerDensityByTemperature d_d_dT_p =  Medium.density_derT_p(state);
      Medium.Density d_d_dX[Medium.nX] =         Medium.density_derX(state);
      Medium.MolarMass MM =                      Medium.molarMass(state);
    end CompleteThermodynamicState_pTX;

    model CompleteSaturationProperties
      "Compute all available saturation properties from a SaturationProperties record"
      replaceable package Medium =
          Modelica.Media.Interfaces.PartialTwoPhaseMedium;

      // SaturationProperties record
      input Medium.SaturationProperties sat;

      // Saturation properties
      Medium.Temperature Ts =      Medium.saturationTemperature_sat(sat);
      Medium.Density dl =          Medium.bubbleDensity(sat);
      Medium.Density dv =          Medium.dewDensity(sat);
      Medium.SpecificEnthalpy hl = Medium.bubbleEnthalpy(sat);
      Medium.SpecificEnthalpy hv = Medium.dewEnthalpy(sat);
      Real d_Ts_dp =               Medium.saturationTemperature_derp_sat(sat);
      Real d_dl_dp =               Medium.dBubbleDensity_dPressure(sat);
      Real d_dv_dp =               Medium.dDewDensity_dPressure(sat);
      Real d_hl_dp =               Medium.dBubbleEnthalpy_dPressure(sat);
      Real d_hv_dp =               Medium.dDewEnthalpy_dPressure(sat);
    end CompleteSaturationProperties;

    model CompleteBubbleDewStates
      "Compute all available properties for dewpoint and bubble point states corresponding to a sat record"
      replaceable package Medium =
          Modelica.Media.Interfaces.PartialMedium;

      // SaturationProperties record
      input Medium.SaturationProperties sat;

      TestMedia.CompleteModels.CompleteThermodynamicState_ph
                                 dewStateOnePhase(state=
            Medium.setDewState(sat, 1), redeclare package Medium = Medium);
      TestMedia.CompleteModels.CompleteThermodynamicState_ph
                                 dewStateTwoPhase(state=
            Medium.setDewState(sat, 2), redeclare package Medium = Medium);
      TestMedia.CompleteModels.CompleteThermodynamicState_ph
                                 bubbleStateOnePhase(state=
            Medium.setBubbleState(sat, 1), redeclare package Medium = Medium);
      TestMedia.CompleteModels.CompleteThermodynamicState_ph
                                 bubbleStateTwoPhase(state=
            Medium.setBubbleState(sat, 2), redeclare package Medium = Medium);
    end CompleteBubbleDewStates;

    model CompleteBaseProperties_ph
      "Compute all available medium properties from a BaseProperties model"
      replaceable package Medium =
            Modelica.Media.Interfaces.PartialMedium;

      // BaseProperties object
      Medium.BaseProperties baseProperties;

      // All the complete properties
      TestMedia.CompleteModels.CompleteThermodynamicState_ph
                                 completeState(
        redeclare package Medium = Medium, state=baseProperties.state);
    end CompleteBaseProperties_ph;

    model CompleteBaseProperties_pTX
      "Compute all available medium properties from a BaseProperties model"
      replaceable package Medium =
            Modelica.Media.Interfaces.PartialMedium;

      // BaseProperties object
      Medium.BaseProperties baseProperties;

      // All the complete properties
      TestMedia.CompleteModels.CompleteThermodynamicState_pTX
                                 completeState(
        redeclare package Medium = Medium, state=baseProperties.state);
    end CompleteBaseProperties_pTX;
  end CompleteModels;
  annotation (uses(Modelica(version="3.2.1")));
end TestMedia;
