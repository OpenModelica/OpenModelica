package Transformer  
  model SC2  
    Modelica.Electrical.QuasiStationary.SinglePhase.Sensors.PowerSensor powerSensor2;
    Modelica.Electrical.QuasiStationary.SinglePhase.Sensors.VoltageSensor voltageSensor2;
    Modelica.Electrical.QuasiStationary.SinglePhase.Sensors.CurrentSensor currentSensor1;
    Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Ground ground2;
    Modelica.Electrical.QuasiStationary.SinglePhase.Sensors.VoltageSensor voltageSensor1;
    Transformer.SinglePhaseTransformerQS singlePhaseTransformerQS1(N1 = 500, R1 = 2.5, N2 = 250, R2 = 0.6, Gc = 1 / 1942, Lm = 1.79, L1sigma = 0.0636, L2sigma = 0.0165);
    Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Ground ground1;
    Modelica.Electrical.QuasiStationary.SinglePhase.Sensors.CurrentSensor currentSensor2;
    Modelica.Electrical.QuasiStationary.SinglePhase.Sources.VoltageSource voltageSource1(f = 50, V = 98.5);
    Modelica.Electrical.QuasiStationary.SinglePhase.Sensors.PowerSensor powerSensor1;
  equation
    connect(currentSensor1.pin_p, ground2.pin);
    connect(powerSensor2.voltageN, ground1.pin);
    connect(singlePhaseTransformerQS1.pin_p2, powerSensor1.currentP);
    connect(ground2.pin, powerSensor1.voltageN);
    connect(powerSensor1.currentN, currentSensor1.pin_n);
    connect(powerSensor1.currentP, powerSensor1.voltageP);
    connect(voltageSensor1.pin_n, ground2.pin);
    connect(currentSensor1.pin_p, voltageSensor1.pin_p);
    connect(singlePhaseTransformerQS1.pin_n2, ground2.pin);
    connect(singlePhaseTransformerQS1.pin_n1, ground1.pin);
    connect(voltageSensor2.pin_n, ground1.pin);
    connect(voltageSource1.pin_n, ground1.pin);
    connect(voltageSensor2.pin_p, powerSensor2.currentN);
    connect(singlePhaseTransformerQS1.pin_p1, powerSensor2.currentN);
    connect(currentSensor2.pin_p, powerSensor2.currentP);
    connect(voltageSource1.pin_p, currentSensor2.pin_n);
    connect(powerSensor2.currentP, powerSensor2.voltageP);
  end SC2;

  model SinglePhaseTransformerQS  "Quasi stationary transformer modeled in electric domain including core loss" 
    parameter Real N1 "Number of turns of primary winding";
    parameter Modelica.SIunits.Resistance R1 "Primary resistance per phase at TRef";
    parameter Modelica.Electrical.Machines.Thermal.LinearTemperatureCoefficient20 alpha20_1 = Modelica.Electrical.Machines.Thermal.Constants.alpha20Copper "Temperature coefficient of primary resistance at 20 degC";
    parameter Modelica.SIunits.Inductance L1sigma "Primary stray inductance per phase";
    parameter Real N2 "Number of turns of secondary winding";
    parameter Modelica.SIunits.Resistance R2 "Secondary resistance per phase at TRef";
    parameter Modelica.Electrical.Machines.Thermal.LinearTemperatureCoefficient20 alpha20_2 = Modelica.Electrical.Machines.Thermal.Constants.alpha20Copper "Temperature coefficient of secondary resistance at 20 degC";
    parameter Modelica.SIunits.Inductance L2sigma "Secondary stray inductance per phase";
    parameter Modelica.SIunits.Temperature TRef "Reference temperature of primary resistance";
    parameter Modelica.SIunits.Temperature TOperational = 293.15 "Operational temperature of primary resistance";
    parameter Boolean useHeatPort = false "Enables or disables thermal heat port";
    parameter Modelica.SIunits.Conductance Gc = 0 "Total eddy current core loss conductance (w.r.t. primary side)" annotation(Evaluate = true);
    parameter Modelica.SIunits.Inductance Lm "Magnetizing inductance" annotation(Evaluate = true);
    Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Inductor inductor1(final L = L1sigma);
    Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Inductor inductor2(final L = L2sigma);
    Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Resistor resistor1(final T_ref = TRef, final T = TOperational, final R_ref = R1, final alpha_ref = alpha20_1, final useHeatPort = useHeatPort);
    Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Resistor resistor2(final T_ref = TRef, final T = TOperational, final R_ref = R2, final alpha_ref = alpha20_2, final useHeatPort = useHeatPort);
    Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Inductor inductorh(final L = Lm);
    Transformer.IdealTransformer idealTransformer(final n = N1 / N2);
    Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Conductor conductor(final G_ref = Gc, final useHeatPort = useHeatPort);
    Modelica.Electrical.QuasiStationary.SinglePhase.Interfaces.PositivePin pin_p1;
    Modelica.Electrical.QuasiStationary.SinglePhase.Interfaces.PositivePin pin_p2;
    Modelica.Electrical.QuasiStationary.SinglePhase.Interfaces.NegativePin pin_n1;
    Modelica.Electrical.QuasiStationary.SinglePhase.Interfaces.NegativePin pin_n2;
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort if useHeatPort;
  equation
    connect(pin_p1, resistor1.pin_p);
    connect(resistor1.pin_n, inductor1.pin_p);
    connect(inductor2.pin_p, resistor2.pin_n);
    connect(inductor1.pin_n, inductorh.pin_p);
    connect(inductorh.pin_n, pin_n1);
    connect(idealTransformer.pin_n1, pin_n1);
    connect(resistor1.heatPort, heatPort);
    connect(resistor2.heatPort, heatPort);
    connect(conductor.heatPort, heatPort);
    connect(conductor.pin_n, inductorh.pin_n);
    connect(conductor.pin_p, inductorh.pin_p);
    connect(inductor1.pin_n, idealTransformer.pin_p1);
    connect(idealTransformer.pin_n2, pin_n2);
    connect(idealTransformer.pin_p2, inductor2.pin_n);
    connect(resistor2.pin_p, pin_p2);
  end SinglePhaseTransformerQS;

  model IdealTransformer  "Ideal quasi stationary transformer" 
    parameter Real n = 1 "Ratio of primary to secondary voltage";
    Modelica.SIunits.ComplexVoltage v1 = pin_p1.v - pin_n1.v "Voltage drop of side 1";
    Modelica.SIunits.ComplexCurrent i1 = pin_p1.i "Current into side 1";
    Modelica.SIunits.ComplexVoltage v2 = pin_p2.v - pin_n2.v "Voltage drop of side 2";
    Modelica.SIunits.ComplexCurrent i2 = pin_p2.i "Current into side 2";
    Modelica.Electrical.QuasiStationary.SinglePhase.Interfaces.PositivePin pin_p1;
    Modelica.Electrical.QuasiStationary.SinglePhase.Interfaces.PositivePin pin_p2;
    Modelica.Electrical.QuasiStationary.SinglePhase.Interfaces.NegativePin pin_n1;
    Modelica.Electrical.QuasiStationary.SinglePhase.Interfaces.NegativePin pin_n2;
  equation
    pin_p1.i + pin_n1.i = Complex(0, 0);
    pin_p2.i + pin_n2.i = Complex(0, 0);
    v1 = Complex(+n, 0) * v2;
    i2 = Complex(-n, 0) * i1;
    Connections.branch(pin_p1.reference, pin_n1.reference);
    pin_p1.reference.gamma = pin_n1.reference.gamma;
    Connections.branch(pin_n1.reference, pin_n2.reference);
    pin_p2.reference.gamma = pin_n2.reference.gamma;
    Connections.branch(pin_p1.reference, pin_p2.reference);
    pin_p1.reference.gamma = pin_p2.reference.gamma;
  end IdealTransformer;
end Transformer;

package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation" 
  extends Modelica.Icons.Package;

  package Machine  
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1.e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1.e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;
  annotation(Protection(access = Access.hide), version = "3.2.2", versionBuild = 0, versionDate = "2016-01-15", dateModified = "2016-01-15 08:44:41Z"); 
end ModelicaServices;

operator record Complex  "Complex number with overloaded operators" 
  replaceable Real re "Real part of complex number";
  replaceable Real im "Imaginary part of complex number";

  encapsulated operator 'constructor'  "Constructor" 
    function fromReal  "Construct Complex from Real" 
      import Complex;
      input Real re "Real part of complex number";
      input Real im = 0 "Imaginary part of complex number";
      output Complex result(re = re, im = im) "Complex number";
    algorithm
      annotation(Inline = true); 
    end fromReal;
  end 'constructor';

  encapsulated operator function '0'  "Zero-element of addition (= Complex(0))" 
    import Complex;
    output Complex result "Complex(0)";
  algorithm
    result := Complex(0);
    annotation(Inline = true); 
  end '0';

  encapsulated operator '-'  "Unary and binary minus" 
    function negate  "Unary minus (multiply complex number by -1)" 
      import Complex;
      input Complex c1 "Complex number";
      output Complex c2 "= -c1";
    algorithm
      c2 := Complex(-c1.re, -c1.im);
      annotation(Inline = true); 
    end negate;

    function subtract  "Subtract two complex numbers" 
      import Complex;
      input Complex c1 "Complex number 1";
      input Complex c2 "Complex number 2";
      output Complex c3 "= c1 - c2";
    algorithm
      c3 := Complex(c1.re - c2.re, c1.im - c2.im);
      annotation(Inline = true); 
    end subtract;
  end '-';

  encapsulated operator '*'  "Multiplication" 
    function multiply  "Multiply two complex numbers" 
      import Complex;
      input Complex c1 "Complex number 1";
      input Complex c2 "Complex number 2";
      output Complex c3 "= c1*c2";
    algorithm
      c3 := Complex(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
      annotation(Inline = true); 
    end multiply;

    function scalarProduct  "Scalar product c1*c2 of two complex vectors" 
      import Complex;
      input Complex[:] c1 "Vector of Complex numbers 1";
      input Complex[size(c1, 1)] c2 "Vector of Complex numbers 2";
      output Complex c3 "= c1*c2";
    algorithm
      c3 := Complex(0);
      for i in 1:size(c1, 1) loop
        c3 := c3 + c1[i] * c2[i];
      end for;
      annotation(Inline = true); 
    end scalarProduct;
  end '*';

  encapsulated operator function '+'  "Add two complex numbers" 
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1 + c2";
  algorithm
    c3 := Complex(c1.re + c2.re, c1.im + c2.im);
    annotation(Inline = true); 
  end '+';

  encapsulated operator function '/'  "Divide two complex numbers" 
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1/c2";
  algorithm
    c3 := Complex(((+c1.re * c2.re) + c1.im * c2.im) / (c2.re * c2.re + c2.im * c2.im), ((-c1.re * c2.im) + c1.im * c2.re) / (c2.re * c2.re + c2.im * c2.im));
    annotation(Inline = true); 
  end '/';

  encapsulated operator function '^'  "Complex power of complex number" 
    import Complex;
    input Complex c1 "Complex number";
    input Complex c2 "Complex exponent";
    output Complex c3 "= c1^c2";
  protected
    Real lnz = 0.5 * log(c1.re * c1.re + c1.im * c1.im);
    Real phi = atan2(c1.im, c1.re);
    Real re = lnz * c2.re - phi * c2.im;
    Real im = lnz * c2.im + phi * c2.re;
  algorithm
    c3 := Complex(exp(re) * cos(im), exp(re) * sin(im));
    annotation(Inline = true); 
  end '^';

  encapsulated operator function '=='  "Test whether two complex numbers are identical" 
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Boolean result "c1 == c2";
  algorithm
    result := c1.re == c2.re and c1.im == c2.im;
    annotation(Inline = true); 
  end '==';

  encapsulated operator function '<>'  "Test whether two complex numbers are not identical" 
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Boolean result "c1 <> c2";
  algorithm
    result := c1.re <> c2.re or c1.im <> c2.im;
    annotation(Inline = true); 
  end '<>';

  encapsulated operator function 'String'  "Transform Complex number into a String representation" 
    import Complex;
    input Complex c "Complex number to be transformed in a String representation";
    input String name = "j" "Name of variable representing sqrt(-1) in the string";
    input Integer significantDigits = 6 "Number of significant digits that are shown";
    output String s = "";
  algorithm
    s := String(c.re, significantDigits = significantDigits);
    if c.im <> 0 then
      if c.im > 0 then
        s := s + " + ";
      else
        s := s + " - ";
      end if;
      s := s + String(abs(c.im), significantDigits = significantDigits) + "*" + name;
    else
    end if;
    annotation(Inline = true); 
  end 'String';
  annotation(Protection(access = Access.hide), version = "3.2.2", versionBuild = 0, versionDate = "2016-01-15", dateModified = "2016-01-15 08:44:41Z"); 
end Complex;

package Modelica  "Modelica Standard Library - Version 3.2.2" 
  extends Modelica.Icons.Package;

  package ComplexBlocks  "Library of basic input/output control blocks with Complex signals" 
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks" 
      extends Modelica.Icons.InterfacesPackage;
      connector ComplexOutput = output Complex "'output Complex' as connector";
    end Interfaces;
  end ComplexBlocks;

  package Electrical  "Library of electrical models (analog, digital, machines, multi-phase)" 
    extends Modelica.Icons.Package;

    package Analog  "Library for analog electrical models" 
      import SI = Modelica.SIunits;
      extends Modelica.Icons.Package;

      package Interfaces  "Connectors and partial models for Analog electrical components" 
        extends Modelica.Icons.InterfacesPackage;

        partial model ConditionalHeatPort  "Partial model to include a conditional HeatPort in order to describe the power loss via a thermal network" 
          parameter Boolean useHeatPort = false "=true, if heatPort is enabled" annotation(Evaluate = true, HideResult = true);
          parameter SI.Temperature T = 293.15 "Fixed device temperature if useHeatPort = false";
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(T(start = T) = T_heatPort, Q_flow = -LossPower) if useHeatPort "Conditional heat port";
          SI.Power LossPower "Loss power leaving component via heatPort";
          SI.Temperature T_heatPort "Temperature of heatPort";
        equation
          if not useHeatPort then
            T_heatPort = T;
          end if;
        end ConditionalHeatPort;
      end Interfaces;
    end Analog;

    package Machines  "Library for electric machines" 
      extends Modelica.Icons.Package;

      package Thermal  "Library with models for connecting thermal models" 
        extends Modelica.Icons.Package;
        type LinearTemperatureCoefficient20 = Modelica.SIunits.LinearTemperatureCoefficient "Linear temperature coefficient with choices";

        package Constants  "Material Constants" 
          extends Modelica.Icons.Package;
          constant Modelica.SIunits.LinearTemperatureCoefficient alpha20Copper = 3.920e-3 "Copper";
        end Constants;
      end Thermal;
    end Machines;

    package QuasiStationary  "Library for quasi-stationary electrical singlephase and multiphase AC simulation" 
      extends Modelica.Icons.Package;

      package SinglePhase  "Single phase AC components" 
        extends Modelica.Icons.Package;

        package Basic  "Basic components for AC singlephase models" 
          extends Modelica.Icons.Package;

          model Ground  "Electrical ground" 
            Interfaces.PositivePin pin;
          equation
            Connections.potentialRoot(pin.reference, 256);
            if Connections.isRoot(pin.reference) then
              pin.reference.gamma = 0;
            end if;
            pin.v = Complex(0);
          end Ground;

          model Resistor  "Single phase linear resistor" 
            extends Interfaces.OnePort;
            import Modelica.ComplexMath.real;
            import Modelica.ComplexMath.conj;
            parameter Modelica.SIunits.Resistance R_ref(start = 1) "Reference resistance at T_ref";
            parameter Modelica.SIunits.Temperature T_ref = 293.15 "Reference temperature";
            parameter Modelica.SIunits.LinearTemperatureCoefficient alpha_ref = 0 "Temperature coefficient of resistance (R_actual = R_ref*(1 + alpha_ref*(heatPort.T - T_ref))";
            extends Modelica.Electrical.Analog.Interfaces.ConditionalHeatPort(T = T_ref);
            Modelica.SIunits.Resistance R_actual "Resistance = R_ref*(1 + alpha_ref*(heatPort.T - T_ref))";
          equation
            assert(1 + alpha_ref * (T_heatPort - T_ref) >= Modelica.Constants.eps, "Temperature outside scope of model!");
            R_actual = R_ref * (1 + alpha_ref * (T_heatPort - T_ref));
            v = R_actual * i;
            LossPower = real(v * conj(i));
          end Resistor;

          model Conductor  "Single phase linear conductor" 
            extends Interfaces.OnePort;
            import Modelica.ComplexMath.real;
            import Modelica.ComplexMath.conj;
            parameter Modelica.SIunits.Conductance G_ref(start = 1) "Reference conductance at T_ref";
            parameter Modelica.SIunits.Temperature T_ref = 293.15 "Reference temperature";
            parameter Modelica.SIunits.LinearTemperatureCoefficient alpha_ref = 0 "Temperature coefficient of conductance (G_actual = G_ref/(1 + alpha_ref*(heatPort.T - T_ref))";
            extends Modelica.Electrical.Analog.Interfaces.ConditionalHeatPort(T = T_ref);
            Modelica.SIunits.Conductance G_actual "Conductance = G_ref/(1 + alpha_ref*(heatPort.T - T_ref))";
          equation
            assert(1 + alpha_ref * (T_heatPort - T_ref) >= Modelica.Constants.eps, "Temperature outside scope of model!");
            G_actual = G_ref / (1 + alpha_ref * (T_heatPort - T_ref));
            i = G_actual * v;
            LossPower = real(v * conj(i));
          end Conductor;

          model Inductor  "Single phase linear inductor" 
            extends Interfaces.OnePort;
            import Modelica.ComplexMath.j;
            parameter Modelica.SIunits.Inductance L(start = 1) "Inductance";
          equation
            v = j * omega * L * i;
          end Inductor;
        end Basic;

        package Sensors  "AC singlephase sensors" 
          extends Modelica.Icons.SensorsPackage;

          model VoltageSensor  "Voltage sensor" 
            extends Interfaces.RelativeSensor;
            Modelica.SIunits.Voltage abs_y = Modelica.ComplexMath.'abs'(y) "Magnitude of complex voltage";
            Modelica.SIunits.Angle arg_y = Modelica.ComplexMath.arg(y) "Argument of complex voltage";
          equation
            i = Complex(0);
            y = v;
          end VoltageSensor;

          model CurrentSensor  "Current sensor" 
            extends Interfaces.RelativeSensor;
            Modelica.SIunits.Current abs_y = Modelica.ComplexMath.'abs'(y) "Magnitude of complex current";
            Modelica.SIunits.Angle arg_y = Modelica.ComplexMath.arg(y) "Argument of complex current";
          equation
            v = Complex(0);
            y = i;
          end CurrentSensor;

          model PowerSensor  "Power sensor" 
            import Modelica.ComplexMath.conj;
            extends Modelica.Icons.RotationalSensor;
            Interfaces.PositivePin currentP;
            Interfaces.NegativePin currentN;
            Interfaces.PositivePin voltageP;
            Interfaces.NegativePin voltageN;
            output Modelica.SIunits.ComplexCurrent i;
            output Modelica.SIunits.ComplexVoltage v;
            Modelica.ComplexBlocks.Interfaces.ComplexOutput y;
            Modelica.SIunits.ApparentPower abs_y = Modelica.ComplexMath.'abs'(y) "Magnitude of complex apparent power";
            Modelica.SIunits.Angle arg_y = Modelica.ComplexMath.arg(y) "Argument of complex apparent power";
          equation
            Connections.branch(currentP.reference, currentN.reference);
            currentP.reference.gamma = currentN.reference.gamma;
            Connections.branch(voltageP.reference, voltageN.reference);
            voltageP.reference.gamma = voltageN.reference.gamma;
            Connections.branch(currentP.reference, voltageP.reference);
            currentP.reference.gamma = voltageP.reference.gamma;
            currentP.i + currentN.i = Complex(0);
            currentP.v - currentN.v = Complex(0);
            i = currentP.i;
            voltageP.i + voltageN.i = Complex(0);
            voltageP.i = Complex(0);
            v = voltageP.v - voltageN.v;
            y = v * conj(i);
          end PowerSensor;
        end Sensors;

        package Sources  "AC singlephase sources" 
          extends Modelica.Icons.SourcesPackage;

          model VoltageSource  "Constant AC voltage" 
            extends Interfaces.Source;
            parameter Modelica.SIunits.Frequency f(start = 1) "frequency of the source";
            parameter Modelica.SIunits.Voltage V(start = 1) "RMS voltage of the source";
            parameter Modelica.SIunits.Angle phi(start = 0) "phase shift of the source";
          equation
            omega = 2 * Modelica.Constants.pi * f;
            v = Complex(V * cos(phi), V * sin(phi));
          end VoltageSource;
        end Sources;

        package Interfaces  "Interfaces for AC singlephase models" 
          extends Modelica.Icons.InterfacesPackage;

          connector Pin  "Basic connector" 
            Modelica.SIunits.ComplexVoltage v "Complex potential at the node";
            flow Modelica.SIunits.ComplexCurrent i "Complex current flowing into the pin";
          end Pin;

          connector PositivePin  "Positive connector" 
            extends Pin;
            QuasiStationary.Types.Reference reference "Reference";
          end PositivePin;

          connector NegativePin  "Negative Connector" 
            extends Pin;
            QuasiStationary.Types.Reference reference "Reference";
          end NegativePin;

          partial model TwoPin  "Two pins" 
            import Modelica.Constants.eps;
            Modelica.SIunits.ComplexVoltage v "Complex voltage";
            Modelica.SIunits.Voltage abs_v = Modelica.ComplexMath.'abs'(v) "Magnitude of complex voltage";
            Modelica.SIunits.Angle arg_v = Modelica.ComplexMath.arg(v) "Argument of complex voltage";
            Modelica.SIunits.ComplexCurrent i "Complex current";
            Modelica.SIunits.Current abs_i = Modelica.ComplexMath.'abs'(i) "Magnitude of complex current";
            Modelica.SIunits.Angle arg_i = Modelica.ComplexMath.arg(i) "Argument of complex current";
            Modelica.SIunits.ActivePower P = Modelica.ComplexMath.real(v * Modelica.ComplexMath.conj(i)) "Active power";
            Modelica.SIunits.ReactivePower Q = Modelica.ComplexMath.imag(v * Modelica.ComplexMath.conj(i)) "Reactive power";
            Modelica.SIunits.ApparentPower S = Modelica.ComplexMath.'abs'(v * Modelica.ComplexMath.conj(i)) "Magnitude of complex apparent power";
            Real pf = cos(Modelica.ComplexMath.arg(Complex(P, Q))) "Power factor";
            Modelica.SIunits.AngularVelocity omega "Angular velocity of reference frame";
            PositivePin pin_p "Positive pin";
            NegativePin pin_n "Negative pin";
          equation
            Connections.branch(pin_p.reference, pin_n.reference);
            pin_p.reference.gamma = pin_n.reference.gamma;
            omega = der(pin_p.reference.gamma);
            v = pin_p.v - pin_n.v;
            i = pin_p.i;
          end TwoPin;

          partial model OnePort  "Two pins, current through" 
            extends TwoPin;
          equation
            pin_p.i + pin_n.i = Complex(0);
          end OnePort;

          partial model RelativeSensor  "Partial voltage / current sensor" 
            extends Modelica.Icons.RotationalSensor;
            extends OnePort;
            Modelica.ComplexBlocks.Interfaces.ComplexOutput y;
          end RelativeSensor;

          partial model Source  "Partial voltage / current source" 
            extends OnePort;
            Modelica.SIunits.Angle gamma(start = 0) = pin_p.reference.gamma;
          equation
            Connections.root(pin_p.reference);
          end Source;
        end Interfaces;
      end SinglePhase;

      package Types  "Definition of types for quasistationary AC models" 
        extends Modelica.Icons.TypesPackage;

        record Reference  "Reference angle" 
          Modelica.SIunits.Angle gamma;

          function equalityConstraint  "Equality constraint for reference angle" 
            input Reference reference1;
            input Reference reference2;
            output Real[0] residue;
          algorithm
            assert(abs(reference1.gamma - reference2.gamma) < 1E-6 * 2 * Modelica.Constants.pi, "Reference angles should be equal!");
          end equalityConstraint;
        end Reference;
      end Types;
    end QuasiStationary;
  end Electrical;

  package Thermal  "Library of thermal system components to model heat transfer and simple thermo-fluid pipe flow" 
    extends Modelica.Icons.Package;

    package HeatTransfer  "Library of 1-dimensional heat transfer with lumped elements" 
      extends Modelica.Icons.Package;

      package Interfaces  "Connectors and partial models" 
        extends Modelica.Icons.InterfacesPackage;

        partial connector HeatPort  "Thermal port for 1-dim. heat transfer" 
          Modelica.SIunits.Temperature T "Port temperature";
          flow Modelica.SIunits.HeatFlowRate Q_flow "Heat flow rate (positive if flowing from outside into the component)";
        end HeatPort;

        connector HeatPort_a  "Thermal port for 1-dim. heat transfer (filled rectangular icon)" 
          extends HeatPort;
        end HeatPort_a;
      end Interfaces;
    end HeatTransfer;
  end Thermal;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices" 
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math" 
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function asin  "Inverse sine (-1 <= u <= 1)" 
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output SI.Angle y;
      external "builtin" y = asin(u);
    end asin;

    function atan2  "Four quadrant inverse tangent" 
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1;
      input Real u2;
      output SI.Angle y;
      external "builtin" y = atan2(u1, u2);
    end atan2;

    function atan3  "Four quadrant inverse tangent (select solution that is closest to given angle y0)" 
      import Modelica.Math;
      import Modelica.Constants.pi;
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1;
      input Real u2;
      input Modelica.SIunits.Angle y0 = 0 "y shall be in the range: -pi < y-y0 <= pi";
      output Modelica.SIunits.Angle y;
    protected
      constant Real pi2 = 2 * pi;
      Real w;
    algorithm
      w := Math.atan2(u1, u2);
      if y0 == 0 then
        y := w;
      else
        y := w + pi2 * integer((pi + y0 - w) / pi2);
      end if;
    end atan3;

    function exp  "Exponential, base e" 
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
    end exp;
  end Math;

  package ComplexMath  "Library of complex mathematical functions (e.g., sin, cos) and of functions operating on complex vectors and matrices" 
    extends Modelica.Icons.Package;
    final constant Complex j = Complex(0, 1) "Imaginary unit";

    function 'abs'  "Absolute value of complex number" 
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      output Real result "= abs(c)";
    algorithm
      result := (c.re ^ 2 + c.im ^ 2) ^ 0.5;
      annotation(Inline = true); 
    end 'abs';

    function arg  "Phase angle of complex number" 
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      input Modelica.SIunits.Angle phi0 = 0 "Phase angle phi shall be in the range: -pi < phi-phi0 < pi";
      output Modelica.SIunits.Angle phi "= phase angle of c";
    algorithm
      phi := Modelica.Math.atan3(c.im, c.re, phi0);
      annotation(Inline = true); 
    end arg;

    function conj  "Conjugate of complex number" 
      extends Modelica.Icons.Function;
      input Complex c1 "Complex number";
      output Complex c2 "= c1.re - j*c1.im";
    algorithm
      c2 := Complex(c1.re, -c1.im);
      annotation(Inline = true); 
    end conj;

    function real  "Real part of complex number" 
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      output Real r "= c.re";
    algorithm
      r := c.re;
      annotation(Inline = true); 
    end real;

    function imag  "Imaginary part of complex number" 
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      output Real r "= c.im";
    algorithm
      r := c.im;
      annotation(Inline = true); 
    end imag;
  end ComplexMath;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)" 
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Modelica.Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
  end Constants;

  package Icons  "Library of icons" 
    extends Icons.Package;

    partial package Package  "Icon for standard packages" end Package;

    partial package InterfacesPackage  "Icon for packages containing interfaces" 
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage  "Icon for packages containing sources" 
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package SensorsPackage  "Icon for packages containing sensors" 
      extends Modelica.Icons.Package;
    end SensorsPackage;

    partial package TypesPackage  "Icon for packages containing type definitions" 
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package IconsPackage  "Icon for packages containing icons" 
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial class RotationalSensor  "Icon representing a round measurement device" end RotationalSensor;

    partial function Function  "Icon for functions" end Function;
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992" 
    extends Modelica.Icons.Package;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units" 
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units" 
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
      end NonSIunits;
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type Power = Real(final quantity = "Power", final unit = "W");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
    type Temperature = ThermodynamicTemperature;
    type LinearTemperatureCoefficient = Real(final quantity = "LinearTemperatureCoefficient", final unit = "1/K");
    type HeatFlowRate = Real(final quantity = "Power", final unit = "W");
    type ElectricCurrent = Real(final quantity = "ElectricCurrent", final unit = "A");
    type Current = ElectricCurrent;
    type ElectricPotential = Real(final quantity = "ElectricPotential", final unit = "V");
    type Voltage = ElectricPotential;
    type Inductance = Real(final quantity = "Inductance", final unit = "H");
    type Resistance = Real(final quantity = "Resistance", final unit = "Ohm");
    type Conductance = Real(final quantity = "Conductance", final unit = "S");
    type ActivePower = Real(final quantity = "Power", final unit = "W");
    type ApparentPower = Real(final quantity = "Power", final unit = "VA");
    type ReactivePower = Real(final quantity = "Power", final unit = "var");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    operator record ComplexCurrent = Complex(redeclare Modelica.SIunits.Current re "Real part of complex current", redeclare Modelica.SIunits.Current im "Imaginary part of complex current") "Complex electrical current";
    operator record ComplexVoltage = Complex(redeclare Modelica.SIunits.Voltage re "Imaginary part of complex voltage", redeclare Modelica.SIunits.Voltage im "Real part of complex voltage") "Complex electrical voltage";
  end SIunits;
  annotation(version = "3.2.2", versionBuild = 3, versionDate = "2016-04-03", dateModified = "2016-04-03 08:44:41Z"); 
end Modelica;

model SC2_total
  extends Transformer.SC2;
end SC2_total;
