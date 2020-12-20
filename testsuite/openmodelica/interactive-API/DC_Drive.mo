within ;
package DC_Drive "Library of controlled DCPM drives"
  extends Modelica.Icons.Package;
  package Examples "Application and test examples of DCPM drives"
    extends Modelica.Icons.ExamplesPackage;

    model DCPMCurrentControlled "DCPM drive fed by ideal DC/DC inverter"
      extends Modelica.Icons.Example;
      import Modelica.Constants.pi;
      parameter DriveParameters.DriveData driveData(redeclare
          DC_Drive.DriveParameters.MachineDataSets.M48V machineData)
        annotation (Placement(transformation(extent={{-80,60},{-60,80}})));
      Modelica.Electrical.Analog.Basic.Ground ground annotation (Placement(
            transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,-40})));
      Modelica.Blocks.Sources.Step iRef(
        height=driveData.machineData.IANominal,
        offset=0,
        startTime=0.1)
        annotation (Placement(transformation(extent={{-80,10},{-60,30}})));
      Modelica.Mechanics.Rotational.Components.Inertia inertiaLoad(
        J=driveData.JL,
        phi(fixed=false, start=0),
        w(fixed=false, start=0))
        annotation (Placement(transformation(extent={{40,-70},{60,-50}})));
      Modelica.Mechanics.Rotational.Sources.LinearSpeedDependentTorque
        linearSpeedDependentTorque(
          tau_nominal=-driveData.machineData.tauNominal,
          TorqueDirection=false,
          w_nominal=driveData.machineData.wNominal)
        annotation (Placement(transformation(extent={{90,-70},{70,-50}})));
      Components.DCPM dCPM(machineData=driveData.machineData)
        annotation (Placement(transformation(extent={{10,-70},{30,-50}})));
      Modelica.Electrical.Analog.Sources.SignalVoltage signalVoltage
        annotation (Placement(transformation(extent={{30,-10},{10,10}})));
      Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor
        annotation (Placement(transformation(
            extent={{-10,10},{10,-10}},
            rotation=90,
            origin={10,-20})));
      Modelica.Blocks.Continuous.FirstOrder firstOrder(k=1, T=driveData.Td)
        annotation (Placement(transformation(extent={{-10,10},{10,30}})));
      Modelica.Electrical.Machines.Examples.ControlledDCDrives.Utilities.LimitedPI
        limitedPI(
        k=driveData.controllerData.kpI,
        Ti=driveData.controllerData.TiI,
        useFF=true,
        KFF=driveData.machineData.kPhi,
        yMax=driveData.VBat)
        annotation (Placement(transformation(extent={{-40,10},{-20,30}})));
    equation
      connect(dCPM.shaft, inertiaLoad.flange_a)
        annotation (Line(points={{30,-60},{40,-60}},
                                                 color={0,0,0}));
      connect(linearSpeedDependentTorque.flange, inertiaLoad.flange_b)
        annotation (Line(points={{70,-60},{60,-60}}, color={0,0,0}));
      connect(ground.p, dCPM.pin_n) annotation (Line(points={{10,-40},{14,-40},
              {14,-50}}, color={0,0,255}));
      connect(ground.p, currentSensor.p)
        annotation (Line(points={{10,-40},{10,-30}}, color={0,0,255}));
      connect(currentSensor.n, signalVoltage.n)
        annotation (Line(points={{10,-10},{10,0}}, color={0,0,255}));
      connect(signalVoltage.p, dCPM.pin_p) annotation (Line(points={{30,0},{30,
              -40},{26,-40},{26,-50}}, color={0,0,255}));
      connect(firstOrder.y, signalVoltage.v)
        annotation (Line(points={{11,20},{20,20},{20,12}}, color={0,0,127}));
      connect(limitedPI.y, firstOrder.u)
        annotation (Line(points={{-19,20},{-12,20}}, color={0,0,127}));
      connect(iRef.y, limitedPI.u)
        annotation (Line(points={{-59,20},{-42,20}}, color={0,0,127}));
      connect(currentSensor.i, limitedPI.u_m) annotation (Line(points={{-1,-20},
              {-36,-20},{-36,8}}, color={0,0,127}));
      connect(dCPM.w, limitedPI.feedForward)
        annotation (Line(points={{9,-60},{-30,-60},{-30,8}}, color={0,0,127}));
      annotation (experiment(
          StopTime=1,
          Interval=0.0001,
          Tolerance=1e-06));
    end DCPMCurrentControlled;
  end Examples;

  package Components "Components for DCPM drives"
    extends Modelica.Icons.Package;
    model DCPM
      extends Modelica.Electrical.Machines.Icons.Machine;
      Modelica.Electrical.Analog.Basic.Resistor resistor(R=machineData.RA,
          T_ref=293.15)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,60})));
      Modelica.Electrical.Analog.Basic.Inductor inductor(L=machineData.LA)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,30})));
      Modelica.Electrical.Analog.Basic.EMF emf(k=machineData.kPhi)
                                                    annotation (Placement(
            transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={0,0})));
      Modelica.Mechanics.Rotational.Components.Inertia inertia(J=machineData.J)
        annotation (Placement(transformation(extent={{40,-10},{60,10}})));
      Modelica.Electrical.Analog.Interfaces.PositivePin pin_p "Positive armature pin"
        annotation (Placement(transformation(extent={{50,90},{70,110}})));
      Modelica.Electrical.Analog.Interfaces.NegativePin pin_n "Negative armature pin"
        annotation (Placement(transformation(extent={{-70,90},{-50,110}})));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a shaft "Shaft"
        annotation (Placement(transformation(extent={{90,-10},{110,10}})));
      Modelica.Mechanics.Rotational.Sensors.SpeedSensor speedSensor annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={80,-30})));
      Modelica.Blocks.Interfaces.RealOutput w annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-110,0})));
      parameter DriveParameters.MachineDataSets.MachineData machineData
        annotation (Placement(transformation(extent={{60,40},{80,60}})));
    equation
      connect(resistor.n, inductor.p)
        annotation (Line(points={{-1.77636e-15,50},{0,50},{0,40},{1.77636e-15,40}},
                                                     color={0,0,255}));
      connect(inductor.n, emf.p)
        annotation (Line(points={{-1.77636e-15,20},{0,20},{0,10}},
                                                          color={0,0,255}));
      connect(emf.flange, inertia.flange_a)
        annotation (Line(points={{10,0},{40,0}}, color={0,0,0}));
      connect(resistor.p, pin_p) annotation (Line(points={{0,70},{0,80},{60,80},{60,
              100}}, color={0,0,255}));
      connect(emf.n, pin_n) annotation (Line(points={{0,-10},{0,-20},{-60,-20},{-60,
              100}}, color={0,0,255}));
      connect(inertia.flange_b, shaft)
        annotation (Line(points={{60,0},{100,0}}, color={0,0,0}));
      connect(inertia.flange_b, speedSensor.flange)
        annotation (Line(points={{60,0},{80,0},{80,-20}}, color={0,0,0}));
      connect(speedSensor.w, w) annotation (Line(points={{80,-41},{80,-60},{-80,-60},
              {-80,0},{-110,0}}, color={0,0,127}));
      annotation (
        Icon(graphics={Text(
              extent={{-100,-100},{100,-140}},
              lineColor={28,108,200},
              textString="%name")}));
    end DCPM;

  end Components;

  package DriveParameters "Library with drive parameter data sets"
    extends Modelica.Icons.RecordsPackage;
    record DriveData
      extends Modelica.Icons.Record;
      import Modelica.Constants.pi;
      replaceable parameter DC_Drive.DriveParameters.MachineDataSets.MachineData machineData
        annotation (choicesAllMatching=true, Placement(transformation(extent={{-10,40},{10,60}})));
      parameter ControllerData controllerData(
        kpI=machineData.LA/(2*Td),
        TiI=machineData.LA/machineData.RA,
        Tsub=2*Td,
        kpw=(machineData.J + JL)/(2*controllerData.Tsub),
        Tiw=4*controllerData.Tsub)
        annotation (Placement(transformation(extent={{-10,0},{10,20}})));
      parameter Modelica.SIunits.Inertia JL=machineData.J "Load inertia";
      parameter Modelica.SIunits.Voltage VBat=1.2*machineData.VANominal "Battery voltage";
      parameter Modelica.SIunits.Frequency fSwitch=1e3 "Switching frequency";
      parameter Modelica.SIunits.Time Td=0.5/fSwitch "Dead time of inverter"
        annotation(Dialog(enable=false));
      annotation(defaultComponentPrefixes="parameter", defaultComponentName="driveData");
    end DriveData;

    record ControllerData
      extends Modelica.Icons.Record;
      parameter Real kpI "Proportional gain of current controller";
      parameter Modelica.SIunits.Time TiI "Integral time constant of current controller";
      parameter Modelica.SIunits.Time Tsub "Substitute time constant";
      parameter Real kpw "Porportional gain of speed controller";
      parameter Modelica.SIunits.Time Tiw "Integral time constant of speed controller";
      annotation(defaultComponentPrefixes="parameter", defaultComponentName="controllerData");
    end ControllerData;

    package MachineDataSets
      extends Modelica.Icons.RecordsPackage;
      record MachineData
        extends Modelica.Icons.Record;
        import Modelica.Constants.pi;
        parameter Modelica.SIunits.Voltage VANominal=100 "Nominal armature voltage";
        parameter Modelica.SIunits.Current IANominal=100 "Nominal armature current";
        parameter Modelica.SIunits.AngularVelocity wNominal=1425*pi/30 "Nominal speed";
        parameter Modelica.SIunits.Resistance RA=0.05 "Armature resistance";
        parameter Modelica.SIunits.Inductance LA=0.0015 "Armature inductance";
        parameter Modelica.SIunits.Voltage ViNominal=VANominal - RA*IANominal "Nominal induced voltage"
          annotation(Dialog(enable=false));
        parameter Modelica.SIunits.ElectricalTorqueConstant kPhi=ViNominal/wNominal "Flux constant";
        parameter Modelica.SIunits.Inertia J=0.29 "Rotor inertia";
        parameter Modelica.SIunits.Torque tauNominal=kPhi*IANominal "Nominal torque"
          annotation(Dialog(enable=false));
        annotation(defaultComponentPrefixes="parameter", defaultComponentName="machineData");
      end MachineData;

      record M48V
        import Modelica.Constants.pi;
        extends DC_Drive.DriveParameters.MachineDataSets.MachineData(
          VANominal=48,
          IANominal=25,
          wNominal=3500*pi/30,
          RA=0.24,
          LA=0.004,
          J=0.0008);
        annotation(defaultComponentPrefixes="parameter", defaultComponentName="machineData");
      end M48V;
    end MachineDataSets;
  end DriveParameters;
  annotation (uses(Modelica(version="3.2.3")));
end DC_Drive;
