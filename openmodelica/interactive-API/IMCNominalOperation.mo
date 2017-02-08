within ;
package IMCNominalOperation
  model NominalOperation "Nominal Operation"
    extends Modelica.Icons.Example;
    import Modelica.Constants.eps;
    import Modelica.Constants.pi;
    import Modelica.SIunits.Conversions.from_rpm;
    import Modelica.SIunits.Conversions.from_degC;
    parameter Integer m(final min=2) = 3 "Number of phases";
    final parameter Integer mSystems=Modelica.Electrical.MultiPhase.Functions.numberOfSymmetricBaseSystems(m) "Count of basic systems";
    parameter Modelica.SIunits.Inertia Jr=eps*0.015 "Rotor's moment of inertia";
    parameter Modelica.SIunits.Inertia Js=Jr "Stator's moment of inertia";
    parameter Integer p(min=1) = 2 "Number of pole pairs (Integer)";
    parameter Modelica.SIunits.Frequency fsNominal=133 "Nominal frequency";
    parameter Real effectiveStatorTurns=1 "Effective number of stator turns";
    parameter String terminalConnection="Y" "Choose Y=star/D=delta";
    parameter Modelica.SIunits.Voltage VsNominal=300/sqrt(3) "Nominal RMS voltage per phase";
    parameter Modelica.SIunits.Current IsNominal=38 "Nominal RMS current per phase";
    parameter Modelica.SIunits.AngularVelocity wNominal=from_rpm(3929) "Nominal speed";
    parameter Modelica.SIunits.Torque tauNominal=36.5 "Nominal torque";
    parameter Modelica.SIunits.Torque tauBreakDown=165;
    parameter Modelica.SIunits.Resistance Rs=0.0773 "Stator resistance per phase at TRef";
    parameter Modelica.SIunits.Temperature TsRef=293.15 "Reference temperature of stator resistance";
    parameter Modelica.Electrical.Machines.Thermal.LinearTemperatureCoefficient20
      alpha20s=Modelica.Electrical.Machines.Thermal.Constants.alpha20Copper "Temperature coefficient of stator resistance at 20 degC";
    parameter Modelica.SIunits.Inductance Lszero=Lssigma "Stator zero sequence inductance";
    parameter Modelica.SIunits.Inductance Lssigma=0.000408538 "Stator stray inductance per phase";
    parameter Modelica.SIunits.Inductance Lm=0.013019592 "Main inductance per phase";
    parameter Modelica.SIunits.Inductance Lrsigma=0.000610054 "Rotor stray inductance per phase";
    parameter Modelica.SIunits.Resistance Rr=0.0586 "Rotor resistance per phase at TRef";
    parameter Modelica.SIunits.Temperature TrRef=293.15 "Reference temperature of rotor resistance";
    parameter Modelica.Electrical.Machines.Thermal.LinearTemperatureCoefficient20
      alpha20r=Modelica.Electrical.Machines.Thermal.Constants.alpha20Aluminium "Temperature coefficient of rotor resistance at 20 degC";
    parameter Modelica.Electrical.Machines.Losses.FrictionParameters
      frictionParameters(PRef=400, wRef=wNominal) "Friction loss parameter record";
    parameter Modelica.Electrical.Machines.Losses.CoreParameters
      statorCoreParameters(
      final m=m,
      PRef=630,
      VRef=VsNominal,
      wRef=2*pi*fsNominal)
      "Stator core loss parameter record w.r.t. to stator side";
    parameter Modelica.Electrical.Machines.Losses.StrayLoadParameters
      strayLoadParameters(
      PRef=75,
      IRef=IsNominal,
      wRef=wNominal) "Stray load loss parameter record";
    parameter Modelica.SIunits.Temperature TsOperational=from_degC(95);
    parameter Modelica.SIunits.Temperature TrOperational=from_degC(95);
    Modelica.SIunits.AngularVelocity wSyn=2*pi*fsNominal/p;
    Real s=1 - multiSensor.w/wSyn;
    Real pf=cos(powerSensor.arg_y);
    Real eta=efficiency(imc.powerBalance.powerStator, imc.powerBalance.powerMechanical);
    parameter Modelica.SIunits.Power PmNominal=tauNominal*wNominal;
    Modelica.Electrical.QuasiStationary.MultiPhase.Sources.VoltageSource
      voltageSource(
      gamma(fixed=true, start=0),
      m=m,
      f=fsNominal,
      V=fill(VsNominal, m))
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-50,50})));
    Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Ground ground
      annotation (Placement(transformation(extent={{-80,-50},{-60,-30}})));
    Modelica.Electrical.QuasiStationary.MultiPhase.Basic.Star star(m=mSystems)
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-70,-10})));
    Modelica.Magnetic.QuasiStatic.FundamentalWave.Utilities.MultiTerminalBox
      multiTerminalBox(m=m, terminalConnection=terminalConnection)
      annotation (Placement(transformation(extent={{-10,6},{10,26}})));
    Modelica.Electrical.QuasiStationary.MultiPhase.Basic.MultiStar multiStar(m=m)
                                   annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-70,20})));
    Modelica.Electrical.QuasiStationary.MultiPhase.Sensors.CurrentQuasiRMSSensor
      currentSensor(m=m)                       annotation (Placement(
          transformation(
          extent={{10,-10},{-10,10}},
          rotation=90,
          origin={0,30})));
    Modelica.Mechanics.Rotational.Sensors.MultiSensor multiSensor
      annotation (Placement(transformation(extent={{20,-10},{40,10}})));
    Modelica.Electrical.QuasiStationary.MultiPhase.Sensors.PowerSensor
      powerSensor(m=m)
      annotation (Placement(transformation(extent={{-30,40},{-10,60}})));
    Modelica.Mechanics.Rotational.Sources.Torque torque
      annotation (Placement(transformation(extent={{70,-10},{50,10}})));
    Modelica.Blocks.Math.Feedback feedback
      annotation (Placement(transformation(extent={{20,-30},{40,-50}})));
    Modelica.Blocks.Continuous.Integrator integrator(
      initType=Modelica.Blocks.Types.Init.InitialOutput,
      k=-1e6,
      y_start=-tauNominal)
      annotation (Placement(transformation(extent={{50,-50},{70,-30}})));
    Modelica.Blocks.Sources.Ramp ramp(
      duration=10,
      height=-3*PmNominal,
      offset=1.5*PmNominal)
      annotation (Placement(transformation(extent={{-10,-50},{10,-30}})));
    Modelica.Magnetic.QuasiStatic.FundamentalWave.BasicMachines.InductionMachines.IM_SquirrelCage
      imc(
      m=m,
      Jr=Jr,
      useSupport=false,
      Js=Js,
      useThermalPort=false,
      p=p,
      fsNominal=fsNominal,
      effectiveStatorTurns=effectiveStatorTurns,
      wMechanical(start=wNominal),
      TsOperational=TsOperational,
      Rs=Rs,
      TsRef=TsRef,
      Lssigma=Lssigma,
      frictionParameters=frictionParameters,
      statorCoreParameters=statorCoreParameters,
      strayLoadParameters=strayLoadParameters,
      Lm=Lm,
      Lrsigma=Lrsigma,
      Rr=Rr,
      TrRef=TrRef,
      TrOperational=TrOperational,
      alpha20s=alpha20s,
      alpha20r=alpha20r)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
  equation
    connect(star.pin_n, ground.pin) annotation (Line(points={{-70,-20},{-70,-24},{
            -70,-30}},  color={85,170,255}));
    connect(star.plug_p, multiStar.starpoints)
      annotation (Line(points={{-70,0},{-70,10}},  color={85,170,255}));
    connect(multiStar.plug_p, voltageSource.plug_n) annotation (Line(points={{-70,30},
            {-70,50},{-60,50}},         color={85,170,255}));
    connect(star.plug_p, multiTerminalBox.starpoint) annotation (Line(points={{-70,0},
            {-20,0},{-20,12},{-9,12}},          color={85,170,255}));
    connect(currentSensor.plug_n, multiTerminalBox.plugSupply)
      annotation (Line(points={{0,20},{0,20},{0,12}}, color={85,170,255}));
    connect(voltageSource.plug_p, powerSensor.currentP)
      annotation (Line(points={{-40,50},{-30,50}}, color={85,170,255}));
    connect(powerSensor.currentP, powerSensor.voltageP)
      annotation (Line(points={{-30,50},{-30,60},{-20,60}}, color={85,170,255}));
    connect(powerSensor.currentN, currentSensor.plug_p) annotation (Line(points={{-10,50},
            {-6,50},{0,50},{0,40}},         color={85,170,255}));
    connect(multiStar.plug_p, powerSensor.voltageN) annotation (Line(points={{-70,
            30},{-40,30},{-20,30},{-20,40}}, color={85,170,255}));
    connect(multiSensor.flange_b, torque.flange)
      annotation (Line(points={{40,0},{45,0},{50,0}}, color={0,0,0}));
    connect(feedback.y, integrator.u)
      annotation (Line(points={{39,-40},{48,-40}}, color={0,0,127}));
    connect(integrator.y, torque.tau) annotation (Line(points={{71,-40},{80,-40},{
            80,0},{72,0}}, color={0,0,127}));
    connect(multiSensor.power, feedback.u2) annotation (Line(points={{24,-11},{24,
            -20},{30,-20},{30,-32}}, color={0,0,127}));
    connect(ramp.y, feedback.u1)
      annotation (Line(points={{11,-40},{22,-40}},          color={0,0,127}));
    connect(multiTerminalBox.plug_sn, imc.plug_sn)
      annotation (Line(points={{-6,10},{-6,10}}, color={85,170,255}));
    connect(multiTerminalBox.plug_sp, imc.plug_sp)
      annotation (Line(points={{6,10},{6,10}}, color={85,170,255}));
    connect(imc.flange, multiSensor.flange_a)
      annotation (Line(points={{10,0},{16,0},{20,0}}, color={0,0,0}));
    annotation (Documentation(info="<html>
</html>"),   Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},
              {100,100}})),
      experiment(
        StopTime=10,
        Interval=0.001,
        Tolerance=1e-005,
        __Dymola_Algorithm="Dassl"));
  end NominalOperation;

  function efficiency
    extends Modelica.Icons.Function;
    import Modelica.Constants.eps;
    input Modelica.SIunits.Power Pel;
    input Modelica.SIunits.Power Pm;
    output Real eta;
  algorithm
    eta :=if noEvent(Pm > eps) then Pm/Pel else if noEvent(Pel < -eps) then Pel/Pm else 0;
    annotation(Inline=true);
  end efficiency;
  annotation (uses(Modelica(version="3.2.2")));
end IMCNominalOperation;
