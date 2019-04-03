package Modelica "Modelica Standard Library"
extends Icons.Library;

  package Blocks
  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;

    package Interfaces
    "Library of connectors and partial models for input/output blocks"
      import Modelica.SIunits;
        extends Modelica.Icons.Library;

    connector RealSignal "Real port (both input/output possible)"
      replaceable type SignalType = Real;

      extends SignalType;

    end RealSignal;

    connector RealOutput = output RealSignal "'output Real' as connector";

        partial block BlockIcon "Basic graphical layout of input/output block"

        equation

        end BlockIcon;

        partial block SO "Single Output continuous control block"
          extends BlockIcon;

          RealOutput y "Connector of Real output signal";
        end SO;

        partial block SignalSource "Base class for continuous signal source"
          extends SO;
          parameter Real offset=0 "Offset of output signal y";
          parameter SIunits.Time startTime=0
        "Output y = offset for time < startTime";
        end SignalSource;
    end Interfaces;

    package Sources
    "Library of signal source blocks generating Real and Boolean signals"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
          extends Modelica.Icons.Library;

          block Sine "Generate sine signal"
            parameter Real amplitude=1 "Amplitude of sine wave";
            parameter SIunits.Frequency freqHz=1 "Frequency of sine wave";
            parameter SIunits.Angle phase=0 "Phase of sine wave";
            parameter Real offset=0 "Offset of output signal";
            parameter SIunits.Time startTime=0
        "Output = offset for time < startTime";
            extends Interfaces.SO;
    protected
            constant Real pi=Modelica.Constants.pi;
          equation
            y = offset + (if time < startTime then 0 else amplitude*
              Modelica.Math.sin(2*pi*freqHz*(time - startTime) + phase));
          end Sine;
    end Sources;
  end Blocks;

  package Constants
  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Library2;

    constant Real pi=2*Modelica.Math.asin(1.0);
  end Constants;

  package Electrical
  "Library of electrical models (analog, digital, machines, multi-phase)"
  extends Modelica.Icons.Library2;

    package Analog "Library for analog electrical models"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Library2;

      package Basic
      "Basic electrical components such as resistor, capacitor, transformer"
        extends Modelica.Icons.Library;

        model Ground "Ground node"
          Interfaces.Pin p;
        equation
          p.v = 0;
        end Ground;

        model Resistor "Ideal linear electrical resistor"
          extends Interfaces.OnePort;
          parameter SI.Resistance R=1 "Resistance";
        equation
          R*i = v;
        end Resistor;

        model Inductor "Ideal linear electrical inductor"
          extends Interfaces.OnePort;
          parameter SI.Inductance L=1 "Inductance";
        equation
          L*der(i) = v;
        end Inductor;
      end Basic;

      package Interfaces
      "Connectors and partial models for Analog electrical components"
        extends Modelica.Icons.Library;

        connector Pin "Pin of an electrical component"
          SI.Voltage v "Potential at the pin";
          flow SI.Current i "Current flowing into the pin";
        end Pin;

        connector PositivePin "Positive pin of an electric component"
          SI.Voltage v "Potential at the pin";
          flow SI.Current i "Current flowing into the pin";
        end PositivePin;

        connector NegativePin "Negative pin of an electric component"
          SI.Voltage v "Potential at the pin";
          flow SI.Current i "Current flowing into the pin";
        end NegativePin;

        partial model OnePort
        "Component with two electrical pins p and n and current i from p to n"

          SI.Voltage v "Voltage drop between the two pins (= p.v - n.v)";
          SI.Current i "Current flowing from pin p to pin n";
          PositivePin p
          "Positive pin (potential p.v > n.v for positive voltage drop v)";
          NegativePin n "Negative pin";
        equation
          v = p.v - n.v;
          0 = p.i + n.i;
          i = p.i;
        end OnePort;

        partial model VoltageSource "Interface for voltage sources"
          extends OnePort;

          parameter SI.Voltage offset=0 "Voltage offset";
          parameter SI.Time startTime=0 "Time offset";
          replaceable Modelica.Blocks.Interfaces.SignalSource signalSource(
              final offset = offset, final startTime=startTime);
        equation
          v = signalSource.y;
        end VoltageSource;
      end Interfaces;

      package Sources
      "Time-dependend and controlled voltage and current sources"
        extends Modelica.Icons.Library;

        model SineVoltage "Sine voltage source"
          parameter SI.Voltage V=1 "Amplitude of sine wave";
          parameter SI.Angle phase=0 "Phase of sine wave";
          parameter SI.Frequency freqHz=1 "Frequency of sine wave";
          extends Interfaces.VoltageSource(redeclare
            Modelica.Blocks.Sources.Sine signalSource(
              amplitude=V,
              freqHz=freqHz,
              phase=phase));
        end SineVoltage;
      end Sources;
    end Analog;
  end Electrical;

  package Icons "Library of icons"

    partial package Library "Icon for library"

    end Library;

    partial package Library2
    "Icon for library where additional icon elements shall be added"

    end Library2;
  end Icons;

  package Math
  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;

  function sin "Sine"
    extends baseIcon1;
    input SI.Angle u;
    output Real y;

  external "C" y=  sin(u);
  end sin;

  function asin "Inverse sine (-1 <= u <= 1)"
    extends baseIcon2;
    input Real u;
    output SI.Angle y;

  external "C" y=  asin(u);
  end asin;

  partial function baseIcon1
    "Basic icon for mathematical function with y-axis on left side"

  end baseIcon1;

  partial function baseIcon2
    "Basic icon for mathematical function with y-axis in middle"

  end baseIcon2;
  end Math;

  package SIunits
  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Library2;

    package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Library2;

      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Library2;
      end NonSIunits;
    end Conversions;

    type Angle = Real (
        final quantity="Angle",
        final unit="rad",
        displayUnit="deg");

    type Time = Real (final quantity="Time", final unit="s");

    type Frequency = Real (final quantity="Frequency", final unit="Hz");

    type ElectricCurrent = Real (final quantity="ElectricCurrent", final unit="A");

    type Current = ElectricCurrent;

    type ElectricPotential = Real (final quantity="ElectricPotential", final unit
        =  "V");

    type Voltage = ElectricPotential;

    type Inductance = Real (
        final quantity="Inductance",
        final unit="H");

    type Resistance = Real (
        final quantity="Resistance",
        final unit="Ohm");
  end SIunits;
end Modelica;

package Test3Phase
  model Test3PhaseStart
  constant Real pi=Modelica.Constants.pi;
  parameter Real shift=0.4;
  Real i_abc[3]={I1.i,I2.i,I3.i};
  Real i_dq0[3];
  Real power;
  protected
  Real theta;
  Real P[3,3];
  Real u_abc[3]={S1.v,S2.v,S3.v};
  Real u_dq0[3];
  public
    Modelica.Electrical.Analog.Basic.Resistor R1(R=.5);
    Modelica.Electrical.Analog.Basic.Inductor I1;
    Modelica.Electrical.Analog.Basic.Resistor R2(R=.5);
    Modelica.Electrical.Analog.Basic.Inductor I2;
    Modelica.Electrical.Analog.Basic.Resistor R3(R=.5);
    Modelica.Electrical.Analog.Basic.Inductor I3;
    Modelica.Electrical.Analog.Sources.SineVoltage S1;
    Modelica.Electrical.Analog.Sources.SineVoltage S3(phase=4*pi/3);
    Modelica.Electrical.Analog.Sources.SineVoltage S2(phase=2*pi/3);
    Modelica.Electrical.Analog.Basic.Ground G;
    Modelica.Electrical.Analog.Sources.SineVoltage SS1(phase=shift);
    Modelica.Electrical.Analog.Sources.SineVoltage SS2(phase=2*pi/3 + shift);
    Modelica.Electrical.Analog.Sources.SineVoltage SS3(phase=4*pi/3 + shift);
  equation
  theta = 2*pi*time;
  P = sqrt(2)/sqrt(3)*
    [sin(theta), sin(theta+2*pi/3), sin(theta+4*pi/3);
     cos(theta), cos(theta+2*pi/3), cos(theta+4*pi/3);
     1/sqrt(2), 1/sqrt(2), 1/sqrt(2)];
  u_dq0 = P*u_abc;
  i_dq0 = P*i_abc;
  power = u_dq0*i_dq0;

    connect(I2.n, R2.p);
    connect(I1.n, R1.p);
    connect(I3.n, R3.p);
    connect(I1.p, S1.n);
    connect(S3.n, I3.p);
    connect(S2.n, I2.p);
    connect(S1.p, S2.p);
    connect(S2.p, S3.p);
    connect(S3.p, G.p);
    connect(R3.n, SS3.p);
    connect(R2.n, SS2.p);
    connect(R1.n, SS1.p);
    connect(SS1.n, SS2.n);
    connect(SS2.n, SS3.n);
    connect(SS3.n, G.p);
  end Test3PhaseStart;

model Test3PhaseInit
  constant Real pi=Modelica.Constants.pi;
  parameter Real shift=0.4;
  Real i_abc[3]={I1.i,I2.i,I3.i};
  Real i_dq0[3];
  Real power;
  protected
  Real theta;
  Real P[3,3];
  Real u_abc[3]={S1.v,S2.v,S3.v};
  Real u_dq0[3];
  public
  Modelica.Electrical.Analog.Basic.Resistor R1(R=.5);
  Modelica.Electrical.Analog.Basic.Inductor I1;
  Modelica.Electrical.Analog.Basic.Resistor R2(R=.5);
  Modelica.Electrical.Analog.Basic.Inductor I2;
  Modelica.Electrical.Analog.Basic.Resistor R3(R=.5);
  Modelica.Electrical.Analog.Basic.Inductor I3;
  Modelica.Electrical.Analog.Sources.SineVoltage S1;
  Modelica.Electrical.Analog.Sources.SineVoltage S3(phase=4*pi/3);
  Modelica.Electrical.Analog.Sources.SineVoltage S2(phase=2*pi/3);
  Modelica.Electrical.Analog.Basic.Ground G;
  Modelica.Electrical.Analog.Sources.SineVoltage SS1(phase=shift);
  Modelica.Electrical.Analog.Sources.SineVoltage SS2(phase=2*pi/3 + shift);
  Modelica.Electrical.Analog.Sources.SineVoltage SS3(phase=4*pi/3 + shift);
initial equation
  der(i_dq0)={0,0,0};
  //der(u_dq0)={0,0,0};
equation
  theta = 2*pi*time;
  P = sqrt(2)/sqrt(3)*
    [sin(theta), sin(theta+2*pi/3), sin(theta+4*pi/3);
     cos(theta), cos(theta+2*pi/3), cos(theta+4*pi/3);
     1/sqrt(2), 1/sqrt(2), 1/sqrt(2)];
  u_dq0 = P*u_abc;
  i_dq0 = P*i_abc;
  power = u_dq0*i_dq0;
  connect(I2.n, R2.p);
  connect(I1.n, R1.p);
  connect(I3.n, R3.p);
  connect(I1.p, S1.n);
  connect(S3.n, I3.p);
  connect(S2.n, I2.p);
  connect(S1.p, S2.p);
  connect(S2.p, S3.p);
  connect(S3.p, G.p);
  connect(R3.n, SS3.p);
  connect(R2.n, SS2.p);
  connect(R1.n, SS1.p);
  connect(SS1.n, SS2.n);
  connect(SS2.n, SS3.n);
  connect(SS3.n, G.p);
end Test3PhaseInit;

model Test3PhaseInitOver
  constant Real pi=Modelica.Constants.pi;
  parameter Real shift=0.4;
  Real i_abc[3]={I1.i,I2.i,I3.i};
  Real i_dq0[3];
  Real power;
  protected
  Real theta;
  Real P[3,3];
  Real u_abc[3]={S1.v,S2.v,S3.v};
  Real u_dq0[3];
  public
  Modelica.Electrical.Analog.Basic.Resistor R1(R=.5);
  Modelica.Electrical.Analog.Basic.Inductor I1;
  Modelica.Electrical.Analog.Basic.Resistor R2(R=.5);
  Modelica.Electrical.Analog.Basic.Inductor I2;
  Modelica.Electrical.Analog.Basic.Resistor R3(R=.5);
  Modelica.Electrical.Analog.Basic.Inductor I3;
  Modelica.Electrical.Analog.Sources.SineVoltage S1;
  Modelica.Electrical.Analog.Sources.SineVoltage S3(phase=4*pi/3);
  Modelica.Electrical.Analog.Sources.SineVoltage S2(phase=2*pi/3);
  Modelica.Electrical.Analog.Basic.Ground G;
  Modelica.Electrical.Analog.Sources.SineVoltage SS1(phase=shift);
  Modelica.Electrical.Analog.Sources.SineVoltage SS2(phase=2*pi/3 + shift);
  Modelica.Electrical.Analog.Sources.SineVoltage SS3(phase=4*pi/3 + shift);
initial equation
  der(i_dq0)={0,0,0};
  der(u_dq0)={0,0,0};
equation
  theta = 2*pi*time;
  P = sqrt(2)/sqrt(3)*
    [sin(theta), sin(theta+2*pi/3), sin(theta+4*pi/3);
     cos(theta), cos(theta+2*pi/3), cos(theta+4*pi/3);
     1/sqrt(2), 1/sqrt(2), 1/sqrt(2)];
  u_dq0 = P*u_abc;
  i_dq0 = P*i_abc;
  power = u_dq0*i_dq0;
  connect(I2.n, R2.p);
  connect(I1.n, R1.p);
  connect(I3.n, R3.p);
  connect(I1.p, S1.n);
  connect(S3.n, I3.p);
  connect(S2.n, I2.p);
  connect(S1.p, S2.p);
  connect(S2.p, S3.p);
  connect(S3.p, G.p);
  connect(R3.n, SS3.p);
  connect(R2.n, SS2.p);
  connect(R1.n, SS1.p);
  connect(SS1.n, SS2.n);
  connect(SS2.n, SS3.n);
  connect(SS3.n, G.p);
end Test3PhaseInitOver;

model Test3PhaseInitParam
  constant Real pi=Modelica.Constants.pi;
  parameter Real shift(fixed=false,start=0);
  Real i_abc[3]={I1.i,I2.i,I3.i};
  Real i_dq0[3];
  Real power;
  protected
  Real theta;
  Real P[3,3];
  Real u_abc[3]={S1.v,S2.v,S3.v};
  Real u_dq0[3];
  public
  Modelica.Electrical.Analog.Basic.Resistor R1(R=.5);
  Modelica.Electrical.Analog.Basic.Inductor I1;
  Modelica.Electrical.Analog.Basic.Resistor R2(R=.5);
  Modelica.Electrical.Analog.Basic.Inductor I2;
  Modelica.Electrical.Analog.Basic.Resistor R3(R=.5);
  Modelica.Electrical.Analog.Basic.Inductor I3;
  Modelica.Electrical.Analog.Sources.SineVoltage S1;
  Modelica.Electrical.Analog.Sources.SineVoltage S3(phase=4*pi/3);
  Modelica.Electrical.Analog.Sources.SineVoltage S2(phase=2*pi/3);
  Modelica.Electrical.Analog.Basic.Ground G;
  Modelica.Electrical.Analog.Sources.SineVoltage SS1(phase=shift);
  Modelica.Electrical.Analog.Sources.SineVoltage SS2(phase=2*pi/3 + shift);
  Modelica.Electrical.Analog.Sources.SineVoltage SS3(phase=4*pi/3 + shift);
initial equation
  der(i_dq0)={0,0,0};
  power = -0.12865;
equation
  theta = 2*pi*time;
  P = sqrt(2)/sqrt(3)*
    [sin(theta), sin(theta+2*pi/3), sin(theta+4*pi/3);
     cos(theta), cos(theta+2*pi/3), cos(theta+4*pi/3);
     1/sqrt(2), 1/sqrt(2), 1/sqrt(2)];
  u_dq0 = P*u_abc;
  i_dq0 = P*i_abc;
  power = u_dq0*i_dq0;
  connect(I2.n, R2.p);
  connect(I1.n, R1.p);
  connect(I3.n, R3.p);
  connect(I1.p, S1.n);
  connect(S3.n, I3.p);
  connect(S2.n, I2.p);
  connect(S1.p, S2.p);
  connect(S2.p, S3.p);
  connect(S3.p, G.p);
  connect(R3.n, SS3.p);
  connect(R2.n, SS2.p);
  connect(R1.n, SS1.p);
  connect(SS1.n, SS2.n);
  connect(SS2.n, SS3.n);
  connect(SS3.n, G.p);
end Test3PhaseInitParam;

end Test3Phase;
