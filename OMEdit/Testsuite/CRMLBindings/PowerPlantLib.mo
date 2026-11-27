package PowerPlantLib "Behavioural models and observers for the D2.1.1 cooling system example"
  package Behaviour
    model CentrifugalPump "Hydraulic part of a centrifugal pump"
      parameter Real J = 0.5 "Inertia of the rotating masses";
      parameter Real kq = 0.01 "Volumetric flow rate per angular velocity";
      parameter Real kr = 0.002 "Resistive torque coefficient";
      Real Cm "Motor torque";
      Real omega(start = 0, fixed = true) "Angular velocity of the rotor";
      Real q "Volumetric flow rate";
      Real Pin "Pressure at the inlet";
      Real Cr "Resistive torque";
    equation
      Cr = kr*omega*abs(omega);
      J*der(omega) = Cm - Cr;
      q = kq*omega;
    end CentrifugalPump;

    model ElectricMotor "Electric motor of a pump"
      parameter Real kt = 0.5 "Torque per volt";
      Real V "Supply voltage";
      Real tau "Torque delivered to the shaft";
    equation
      tau = kt*V;
    end ElectricMotor;

    model CoolingSystem_B1 "Behavioural model: pumps PO1 and PO2 with motors, PO3 hydraulic part only"
      CentrifugalPump p1 "Model for pump PO1";
      ElectricMotor m1 "Model for electric motor of pump PO1";
      CentrifugalPump p2 "Model for pump PO2";
      ElectricMotor m2 "Model for electric motor of pump PO2";
      CentrifugalPump p3 "Model for pump PO3";
    equation
      m1.V = if time > 1 then 400 else 0;
      m2.V = if time > 2 then 400 else 0;
      p1.Cm = m1.tau;
      p2.Cm = m2.tau;
      p3.Cm = if time > 3 then 200 else 0;
      p1.Pin = 2e5;
      p2.Pin = 2e5 - 1.5e4*time "The inlet pressure of PO2 drops, PO2 cavitates after about 7 s";
      p3.Pin = 2e5;
      annotation(experiment(StopTime = 10));
    end CoolingSystem_B1;
  end Behaviour;

  package Observers "Observation operators: they read the behavioural model and return a CRML Boolean4"
    function Obs_PumpStarted_1 "The pump is started when the supply voltage of its motor is above a threshold"
      input Real V "Supply voltage";
      input Real Vt = 100 "Voltage threshold";
      output CRMLtoModelica.Types.Boolean4 pumpStarted;
    algorithm
      pumpStarted := if V > Vt then CRMLtoModelica.Types.Boolean4.true4 else CRMLtoModelica.Types.Boolean4.false4;
      annotation(__OpenModelica_CRML(observes = "inOperation", rank = 1));
    end Obs_PumpStarted_1;

    function Obs_PumpStarted_2 "The pump is started when the motor torque on its rotor is above a threshold"
      input Real Cm "Motor torque";
      input Real Ct = 50 "Torque threshold";
      output CRMLtoModelica.Types.Boolean4 pumpStarted;
    algorithm
      pumpStarted := if Cm > Ct then CRMLtoModelica.Types.Boolean4.true4 else CRMLtoModelica.Types.Boolean4.false4;
      annotation(__OpenModelica_CRML(observes = "inOperation", rank = 2));
    end Obs_PumpStarted_2;

    function Obs_PumpStarted_3 "The pump is started when its volumetric flow rate is above a threshold"
      input Real q "Volumetric flow rate";
      input Real qt = 0.5 "Volumetric flow rate threshold";
      output CRMLtoModelica.Types.Boolean4 pumpStarted;
    algorithm
      pumpStarted := if q > qt then CRMLtoModelica.Types.Boolean4.true4 else CRMLtoModelica.Types.Boolean4.false4;
      annotation(__OpenModelica_CRML(observes = "inOperation", rank = 3));
    end Obs_PumpStarted_3;

    function Obs_PumpCavitating "The pump cavitates when the inlet pressure is below the required NPSH at the current flow"
      input Real P "Pressure at the inlet of the pump";
      input Real q "Volumetric flow through the pump";
      input Real NPSH_req[:, 2] "Required NPSH: flow rate in column 1, pressure in column 2";
      output CRMLtoModelica.Types.Boolean4 pumpCavitating;
    algorithm
      if Obs_PumpStarted_3(q) == CRMLtoModelica.Types.Boolean4.true4 then
        pumpCavitating := if P < interpolate(NPSH_req, q) then CRMLtoModelica.Types.Boolean4.true4 else CRMLtoModelica.Types.Boolean4.false4;
      else
        pumpCavitating := CRMLtoModelica.Types.Boolean4.undefined;
      end if;
      annotation(__OpenModelica_CRML(observes = "cavitate"));
    end Obs_PumpCavitating;

    function interpolate "Linear interpolation in a table with the abscissa in column 1"
      input Real table[:, 2];
      input Real x;
      output Real y;
    protected
      Integer i = 1;
    algorithm
      if size(table, 1) == 1 or x <= table[1, 1] then
        y := table[1, 2];
      elseif x >= table[size(table, 1), 1] then
        y := table[size(table, 1), 2];
      else
        while x > table[i + 1, 1] loop
          i := i + 1;
        end while;
        y := table[i, 2] + (table[i + 1, 2] - table[i, 2])*(x - table[i, 1])/(table[i + 1, 1] - table[i, 1]);
      end if;
    end interpolate;
  end Observers;
end PowerPlantLib;
