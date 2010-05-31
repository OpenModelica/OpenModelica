package Modelica "Modelica Standard Library (Version 3.0)"


  package Blocks
    import SI = Modelica.SIunits;
 
    package Interfaces
      import Modelica.SIunits;
 
    connector RealOutput = output Real "'output Real' as connector" ;

        
        partial block SO "Single Output continuous control block"
        

          RealOutput y "Connector of Real output signal"   ;

        end SO;
    end Interfaces;

    package Sources
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
    
          block Trapezoid "Generate trapezoidal signal of type Real"
            parameter Real amplitude=1 "Amplitude of trapezoid";
            parameter SIunits.Time rising(final min=0) = 0
        "Rising duration of trapezoid";
            parameter SIunits.Time width(final min=0) = 0.5
        "Width duration of trapezoid";
            parameter SIunits.Time falling(final min=0) = 0
        "Falling duration of trapezoid";
            parameter SIunits.Time period(final min=Modelica.Constants.small, start= 1)
        "Time for one period";
            parameter Integer nperiod=-1
        "Number of periods (< 0 means infinite number of periods)";
            parameter Real offset=0 "Offset of output signal";
            parameter SIunits.Time startTime=0
        "Output = offset for time < startTime";
            extends Interfaces.SO;
    protected
            parameter SIunits.Time T_rising=rising
        "End time of rising phase within one period";
            parameter SIunits.Time T_width=T_rising + width
        "End time of width phase within one period";
            parameter SIunits.Time T_falling=T_width + falling
        "End time of falling phase within one period";
            SIunits.Time T0(final start=startTime)
        "Start time of current period";
            Integer counter(start=nperiod) "Period counter";
            Integer counter2(start=nperiod);
            
          equation
            when pre(counter2) <> 0 and sample(startTime, period) then
              T0 = time;
              counter2 = pre(counter);
              counter = pre(counter) - (if pre(counter) > 0 then 1 else 0);
            end when;
            y = offset + (if (time < startTime or counter2 == 0 or time >= T0 +
              T_falling) then 0 else if (time < T0 + T_rising) then (time - T0)*
              amplitude/T_rising else if (time < T0 + T_width) then amplitude else 
              (T0 + T_falling - time)*amplitude/(T_falling - T_width));
          end Trapezoid;
    end Sources;
  end Blocks;

  package Constants
  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;

    final constant Real small=1.e-60
    "Smallest number such that small and -small are representable on the machine";
    
  end Constants;

  

  package SIunits
  "Library of type and unit definitions based on SI units according to ISO 31-1992"
   
    package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
      

      package NonSIunits "Type definitions of non SI units"
        
      end NonSIunits;
    end Conversions;

    type Time = Real (final quantity="Time", final unit="s");
  end SIunits;
end Modelica;

package SimpleFun
function tryFunction
  input Real a;
  output Real tmp1; // !!! name mangling should be used
algorithm
  tmp1 := a * 10;
end tryFunction;

function otherFun
  input Real ia;
  input Real ib;
  output Real yy;
  output Real xx;
protected
  //Integer i;
  Real s;
algorithm
  s := 0;
  for i in 1:10 loop
    s := s + ia * i;
  end for; 
  yy := ia * 10 + ib + s;
  for i in 1:10 loop
    s := s + ia * i;
  end for;
  s:= if yy > 10 then s + 4 else s-2;
  xx := yy / s;
end otherFun;

function recFun
  input Try_Rec tr;
  output Real rr;
algorithm
  rr := tr.r1;
end recFun;

function mk_rec
  input Real a;
  input Real b;
  output Try_Rec out;
algorithm
  //out := Try_Rec(a,b);
  out.r1 := a + b;
  out.r2 := b;
end mk_rec;

record Try_Rec
  Real r1;
  Real r2;
end Try_Rec;
end SimpleFun;

model TrapezTestTotal
  annotation (uses(Modelica(version="3.0")));
  Modelica.Blocks.Sources.Trapezoid trapezoid(
    amplitude=6,
    rising=0.1,
    width=0.5,
    falling=0.2,
    period=3,
    nperiod=10,
    offset=7,
    startTime=4) 
    annotation (Placement(transformation(extent={{-34,10},{-14,30}})));
  Modelica.Blocks.Interfaces.RealOutput y;
  output Real x;
  //output TryRec tr;
  output Real r;
equation
  (x,y) = SimpleFun.otherFun(SimpleFun.tryFunction(trapezoid.y),21.5);
  r = SimpleFun.recFun(SimpleFun.mk_rec(1.37, y));
  //tr := recFun(10.0,34);
end TrapezTestTotal;
