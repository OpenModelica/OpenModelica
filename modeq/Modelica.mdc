/*
   Modelica Standard Library
   (Modelica Language Definition, Version 1, September 97)
*/

package Modelica
/* The Modelica package is a standardized, pre-defined package,
   that is shipped together with a Modelica translator. The package
   provides constants, types, connectors, partial models and some
   often used model components in various disciplines. Especially,
   the following sub-packages are available:

   SIunit   : Types defining SIunits of ISO 1000.
   Constant : Mathematical and physical constants.
   Interface: Basic interfaces in various disciplines
   Signal   : Real and Boolean signal generators.


   The following conventions are used in the whole package:

   - Class and instance names are written in upper and lower case
   letters, e.g., "ElectricCurrent". An underscore is only used 
   at the end of a name to characterize a lower or upper index,
   e.g., body_low_up.

   - Type names start always with an upper case letter. Instance names start
   always with a lower case letter with only a few exceptions according to
   common engineering practice, such as "T" for a temperature instance.

   - Usually, SIunits are used via pre-defined SIunit types.

   - Preferred instance names for connectors:
   p,n: positive and negative side of a partial model.
   a,b: side "a" and side "b" of partial model,
   if the two connectors are completely equivalent.
*/


package SIunit

/* This package provides predefined types based on the international standard
   on units (ISO 31-1992 "General principles concerning quantities, units and
   symbols" and ISO 1000-1992 "SI units and recommendations for the use of
   their multiples and of certain other units"). The ordering of the type
   declarations follows ISO 31. The naming of  the types follows the following 
   convention:

   - Modelica quantity names are defined according to the recommendations of
   ISO 31. Some of these name are rather long, such as 
   "ThermodynamicTemperature". Shorter alias names are defined in
   appropriate subpackages, e.g., "type Temp_K = ThermodynamicTemperature;".   

   - Modelica units are defined according to the SI base units without
   multiples (only exception "kg").

   - For some quantities, more convenient units for an engineer are defined as 
   "displayUnit", i.e., the default unit for display purposes
   (e.g., displayUnit="deg" for quantity="Angle"). 

   - The type name is identical to the quantity name, following
   the convention of type names.
   
   - All quantity and unit attributes are defined as final in order
   that they cannot be redefined to another value.

   - Some quantities, which are obviously also important but are not
   explicitly mentioned in the ISO 1000 standard, such as 
   "AngularAcceleration", are also included.
*/

// Part 1: Space and time
type Angle               = Real(final quantity="Angle",
				final unit    ="rad", 
				Displayunit   ="deg");
type SolidAngle          = Real(final quantity="SolidAngle",
				final unit    ="sr"); 
type Length              = Real(final quantity="Length",
				final unit    ="m");
type Area                = Real(final quantity="Area",
				final unit    ="m2");
type Volume              = Real(final quantity="Volume",
				final unit    ="m3");
type Time                = Real(final quantity="Time", 
				final unit    ="s");
type AngularVelocity     = Real(final quantity="AngularVelocity",
				final unit    ="rad/s");
type Velocity            = Real(final quantity="Velocity",
				final unit    ="m/s");
type AngularAcceleration = Real(final quantity="AngularAcceleration",
				final unit    ="rad/s2");
type Acceleration        = Real(final quantity="Acceleration",
				final unit    ="m/s2");

// Part 2: Periodic and related phenomens
//...

// Part 3: Mechanics
type Mass               = Real(final quantity="Mass",
			       final unit    ="kg", min=0);
type Density            = Real(final quantity="Density",
			       final unit    ="kg/m3", min=0);
type LinearDensity      = Real(final quantity="LinearDensity",
			       final unit    ="kg/m", min=0);
type MomentOfInertia    = Real(final quantity="MomentOfInertia",
			       final unit    ="kg*m^2");
type Momentum           = Real(final quantity="Mass",
			       final unit    ="kg.m/s");
type Force              = Real(final quantity="Force",
			       final unit    ="N");
type AngularMomentum    = Real(final quantity="Mass",
			       final unit    ="kg.m2/s");
type MomentOfForce      = Real(final quantity="MomentOfForce",
			       final unit    ="N.m");
type Pressure           = Real(final quantity="Pressure",
			       final unit    ="Pa", min=0);
type NormalStress       = Real(final quantity="NormalStress",
			       final unit    ="Pa");
type DynamicViscosity   = Real(final quantity="DynamicViscosity",
			       final unit    ="Pa.s", min=0);
type KinematicViscosity = Real(final quantity="KinematicViscosity",
			       final unit    ="m2/s", min=0);
type SurfaceTension     = Real(final quantity="SurfaceTension",
			       final unit    ="N/m");
type Energy             = Real(final quantity="Energy",
			       final unit    ="J");
type Power              = Real(final quantity="Power",
			       final unit    ="W");

// Part 4: Heat
type ThermodynamicTemperature = Real(final quantity="ThermodynamicTemperature",
				     final unit    ="K", min=0,
				     Displayunit   ="degC");
type CelsiusTemperature       = Real(final quantity="CelsiusTemperature",
				     final unit    ="degC", min = -273.15);

type LinearExpansionCoefficient       = Real(final quantity=" LinearExpansionCoefficient",
					     final unit ="1/K");
type CubicExpansionCoefficient        = Real(final quantity="CubicExpansionCoefficient",
					     final unit ="1/K");
type RelativePressureCoefficient      = Real(final quantity="RelativePressureCoefficient",
					     final unit ="1/K");
type PressureCoefficient              = Real(final quantity="PressureCoefficient",
					     final unit ="Pa/K");
type IsothermalCompressibility        = Real(final quantity="IsothermalCompressibility",
					     final unit ="1/Pa");
type IsentropicCompressibility        = Real(final quantity="IsentropicCompressibility",
					     final unit ="1/Pa");
type Heat                             = Energy;
type HeatFlowRate                     = Real(final quantity="HeatFlowRate",
					     final unit ="W");
type DensityOfHeatFlowRate            = Real(final quantity="DensityOfHeatFlowRate",
					     final unit ="W/m^2");
type ThermalConductivity              = Real(final quantity="ThermalConductivity",
					     final unit ="W/(m.K)");
type CoefficientOfHeatTransfer        = Real(final quantity="CoefficientOfHeatTransfer",
					     final unit ="W/(m^2.K)");
type SurfaceCoefficientOfHeatTransfer = Real(final quantity="SurfaceCoefficientOfHeatTransfer",
					     final unit ="W/(m^2.K)");
type ThermalInsulance                 = Real(final quantity="ThermalInsulance",
					     final unit ="m^2.K/W");
type ThermalResistance                = Real(final quantity="ThermalResistance",
					     final unit ="K/W");
type ThermalConductance               = Real(final quantity="ThermalConductance",
					     final unit ="W/K");
type ThermalDiffusivity               = Real(final quantity="ThermalDiffusivity",
					     final unit ="m^2/s");
type HeatCapacity                     = Real(final quantity="HeatCapacity",
					     final unit ="J/K");
type SpecificHeatCapacity             = Real(final quantity="SpecificHeatCapacity",
					     final unit ="J/(kg.K)");

/* The specific heat capacity is most often taken in a "direction"
   i. e. at constant pressure or constant volume. which one is meant 
   should be specified in the appropriate aliases
*/

type RatioOfSpecificHeatCapacities = Real(final quantity="RatioOfSpecificHeatCapacities",
					  final unit ="1");
type IsentropicExponent            = Real(final quantity="IsentropicExponent",
					  final unit ="1");
type Entropy                       = Real(final quantity="Entropy",
					  final unit ="J/K");
type SpecificEntropy               = Real(final quantity="SpecificEntropy",
					  final unit ="J/(kg.K)");
type SpecificEnergy                = Real(final quantity="SpecificEnergy",
					  final unit ="J/kg");

/* In thermodynamics, energy comes in many flavors. The ones defined by the ISO 
   are defined as aliases to the basic one. All of these energy forms are also 
   defined in a specific, i. e. divided by mass version.
*/

type ThermodynamicEnergy         = Energy;
type HelmholtzFreeEnergy         = Energy;
type GibbsFreeEnergy             = Energy;
type Enthalpy                    = Energy;

type SpecificThermodynamicEnergy = SpecificEnergy;
type SpecificHelmholtzFreeEnergy = SpecificEnergy;
type SpecificGibbsFreeEnergy     = SpecificEnergy;
type SpecificEnthalpy            = SpecificEnergy;


type PlanckFunction  = Real(final quantity="PlanckFunction",
			    final unit ="J/kg");


// Part 5: Electricity and magnetism
type ElectricCurrent   = Real(final quantity="ElectricCurrent",
			      final unit    ="A");
type ElectricCharge    = Real(final quantity="ElectricCharge",
			      final unit    ="C");
type ElectricPotential = Real(final quantity="ElectricPotential",
			      final unit    ="V");
type Capacitance       = Real(final quantity="Capacitance",
			      final unit    ="F", min=0);
type Inductance        = Real(final quantity="Inductance",
			      final unit    ="H", min=0);
type Resistance        = Real(final quantity="Resistance",
			      final unit    ="Ohm", min=0);
type Conductance       = Real(final quantity="Conductance",
			      final unit    ="S", min=0);
//...


// Part 6: Light and related electromagnetic radiations
type LuminousIntensity = Real(final quantity="LuminousIntensity",
			      final unit    ="cd");
//...

// Part 7: Acoustics
//...

// Part 8: Physical chemistry and molecular physics
type AmountOfSubstance = Real(final quantity="AmountOfSubstance",
			      final unit    ="mol", min=0);
//...

// Part 9: Atomic and nuclear physics
//...

// Part 10: Nuclear reactions and ionizing radiations
//...

// Part 11: Characteristic numbers
// Momentum transport
type ReynoldsNumber = Real(final quantity="ReynoldsNumber",
			   final unit ="1"); 
type EulerNumber    = Real(final quantity="EulerNumber",
			   final unit ="1");
type FroudeNumber   = Real(final quantity="FroudeNumber",
			   final unit ="1");
type GrashofNumber  = Real(final quantity="GrashofNumber",
			   final unit ="1");
type WeberNumber    = Real(final quantity="WeberNumber",
			   final unit ="1");
type MachNumber     = Real(final quantity="MachNumber",
			   final unit ="1");
type KnudsenNumber  = Real(final quantity="KnudsenNumber",
			   final unit ="1");
type StrouhalNumber = Real(final quantity="StrouhalNumber",
			   final unit ="1");

// Transport of heat
type FourierNumber  = Real(final quantity="FourierNumber",
			   final unit ="1");
type PecletNumber   = Real(final quantity="PecletNumber",
			   final unit ="1");
type RayleighNumber = Real(final quantity="RayleighNumber",
			   final unit ="1");
type NusseltNumber  = Real(final quantity="NusseltNumber",
			   final unit ="1");
type BiotNumber     = NusseltNumber;   // The name Biot number, Bi, is used
				       // when the Nusselt number is reserved
				       // for convective transport of heat.
type StantonNumber  = Real(final quantity="StantonNumber",
			   final unit ="1");

// Constants of matter
type PrandtlNumber = Real(final quantity="PrandtlNumber",
			  final unit ="1");
type SchmidtNumber = Real(final quantity="SchmidtNumber",
			  final unit ="1");
type LewisNumber   = Real(final quantity="Number",
			  final unit ="1");

// Part 12: Solid state physics
//...

end SIunit;


package Constant

/* This package provides often needed constants */
extends SIunit;

// Mathematical constants
constant Real PI = 3.14159265358979;
constant Real E  = 2.71828182845904;

/* Constants of nature 
   (from: E.R. Cohen, and B.N. Taylor: The 1986 Adjustment of the Fundamental
   Physical Constants, CODATA Bulletin, Pergamon: Elmsford, NY, 1986.
   see also: http://physics.nist.gov/PhysRefData/codata86/article.html
   http://physics.nist.gov/PhysRefData/codata86/codata86.html)
*/

constant Real         N_A     (final unit="mol-1")
  = 6.0221367e23  "Avogadro constant";
constant Velocity     C       = 299792458     "Velocity of light in vacuum";
constant Real         G       (final unit="m3.kg-1.s-2")
  = 6.67259e-11   "Universal gravity constant";
constant Acceleration G_EARTH = 9.81          "Gravity acceleration on earth";
constant Real         H       (final unit="J.s")
  = 6.6260755e-34 "Plancks constant";
constant Real         K       (final unit="J.K-1") 
  = 1.380658e-23  "Boltzmann constant";
constant Real         R0      (final unit="J.mol-1.K-1")
  = 8.314510      "Universal gas constant";
constant Real         SIGMA   (final unit="W.m-2.K-4")
  = 5.67051e-8    "Stefan Boltzmann constant";
constant Real         T_ZERO  (final unit="degC")
  = -273.15       "Absolute zero temperature";
// ...

end Constant;


package Interface

/* This package provides interface definitions, i.e.,types, connectors and
   partial models, in various disciplines. It is organized in sub-packages:

   Block        : Interfaces for input/output blocks.
   BondGraph    : Interfaces for bondgraphs.
   Electric     : Interfaces for electric systems.
   Mechanic     : Interfaces for mechanic systems.
   Thermodynamic: Interfaces for thermodynamic systems.
*/


package Block

/* This package provides types, connectors and partial models for
   input/output blocks.
*/
extends SIunit;

// Partial models for continuous input/output control blocks
partial block SISO "Single input, single output (continuous) block"
  input  Real u  "Input signal";
  output Real y  "Output signal";
end SISO;

partial block MISO "Multiple input, single output (continuous) block"
  input  Real u[:]  "Input signal vector";
  output Real y    "Output signal";
end MISO;

partial block MIMO "Multiple input, multiple output (continuous) block"
  input  Real u[:]  "Input signal vector";
  output Real y[:]  "Output signal vector";
end MIMO;

partial block MIMOs "Multiple input, single output (continuous) block"
		    "with equal number of inputs and outputs"
  input  Real u[:]           "Input signal vector";
  output Real y[size(u,1)]  "Output signal vector";
end MIMOs;

partial block SO "Single output (continuous) block"
  output Real y  "Output signal";
end SO;

partial block MO "Multiple output (continuous) block"
  output Real y[:]  "Output signal vector";
end MO;

// Partial models for Boolean input/output blocks
partial block SISOb "Single input, single output (Boolean) block"
  input  Boolean u  "Input signal";
  output Boolean y  "Output signal";
end SISOb;

partial block MISOb "Multiple input, single output (Boolean) block"
  input  Boolean u[:]  "Input signal vector";
  output Boolean y    "Output signal";
end MISOb;

partial block MIMOb "Multiple input, multiple output (Boolean) block"
  input  Boolean u[:]  "Input signal vector";
  output Boolean y[:]  "Output signal vector";
end MIMOb;

partial block MIMOsb "Multiple input, single output (Boolean) block"
		     "with equal number of inputs and outputs"
  input  Boolean u[:]           "Input signal vector";
  output Boolean y[size(u,1)]  "Output signal vector";
end MIMOsb;

partial block SOb "Single output (Boolean) block"
  output Boolean y  "Output signal";
end SOb;

partial block MOb "Multiple output (Boolean) block"
  output Boolean y[:]  "Output signal vector";
end MOb;
end Block;



package BondGraph

/* This package provides types, connectors and partial models for 
   bond graphs
*/
extends SIunit;

// Bond Graph power connector. 
// Both effort and flow are "across" variables. 

connector BondPort "Bond Graph power port"
  Real e  "Effort variable";
  Real f  "Flow variable";
end BondPort;

partial model OnePortPassive "One port passive bond graph element"
  BondPort p "Generic power port p";
equation
  assert(cardinality(p)==1, "Power ports have only one edge connected to");
  assert(direction(p)  ==1, "Power direction towards element for passivity");
end OnePortPassive;

partial model OnePortEnergetic "One port storage element, being passive"
  extends OnePortPassive;

  Real state "Conserved quantity";
end OnePortEnergetic;

partial model OnePortActive "One port active bond graph element: the sources"
  BondPort p;
equation
  assert(cardinality(p)== 1, "Power ports have only one edge connected to");
  assert(direction(p)  ==-1, "Power direction from the element for active elements");
end OnePortActive;

partial model TwoPortPassive "Two port passive bond graph element"
  BondPort PowIn, PowOut;
equation
  assert(cardinality(Powin) == 1, "Power ports have only one edge connected to");
  assert(direction  (PowIn) ==+1, "power direction towards the element for passivity");
  assert(cardinality(Powout)== 1, "Power ports have only one edge connected to");
  assert(direction  (PowOut)==-1, "Power direction from the element for passivity");
end TwoPortPassive;

end BondGraph;



package Electric

/* This package providestypes, connectors and partial models for
   the electric domain.
*/
extends SIunit;

// Commonly used short names for electric types
type Current = ElectricCurrent;
type Charge  = ElectricCharge;
type Voltage = ElectricPotential;

// Connector types for electric components
connector Pin "Pin of an electric component"
  Voltage      v  "Potential at the pin";
  flow Current i  "Current flowing into the pin";
end Pin;

// Partial models for electric components
partial model TwoPin "Component with two electric pins"
  Pin     p  "Positive pin";
  Pin     n  "Negative pin";
  Voltage v  "Voltage drop between the two pins";
equation
  v = p.v - n.v;
end TwoPin;

partial model TwoPort "Component with two electric ports"
  Pin     pl  "Positive pin of the left port";
  Pin     nl  "Negative pin of the left port";
  Pin     pr  "Positive pin of the right port";
  Pin     nr  "Negative pin of the right port";
  Voltage vl  "Voltage drop over the left port";
  Voltage vr  "Voltage drop over the right port";
equation
  vl = pl.v - nl.v;
  vr = pr.v - nr.v;
end TwoPort;
end Electric;



package Mechanic

/* This package provides types, connectors and partial models for
   the mechanic domain.
*/
extends SIunit;

// Commonly used short names for mechanic types
type Position = Length;
type Distance = Length(final min=0);
type Inertia  = MomentOfInertia;
type Torque   = MomentOfForce;

// Connector types for mechanic components
connector TransVel  "1D translational mechanical flange cut on velocity level."
  Velocity   v  "Absolute velocity of the flange with respect to base";
  flow Force f  "Cut-force directed into the flange to drive it";
end TransVel;

connector DriveVel  "1D rotational mechanical flange cut on velocity level."
  AngularVelocity w  "Absolute angular velocity of flange with respect to base";
  flow Torque     t  "Cut-torque directed into the flange to drive it";
end DriveVel;

connector TransPos "1D translational mechanical flange cut" 
  Position     s  "Absolute position of flange with respect to base";
  Velocity     v  "Absolute velocity of flange with respect to base";
  Acceleration a  "Absolute acceleration of flange with respect to base";
  flow Force   f  "Cut-force directed into flange to drive it";
end TransPos;

connector DrivePos "1D rotational mechanical flange cut"
		   "for positional drive trains."
  Angle               r  "Absolute rotation angle of flange cut with respect to base";
  AngularVelocity     w  "Absolute angular velocity of flange with respect to base";
  AngularAcceleration a  "Absolute angular acceleration of flange with "
			 "respect to base";
  flow Torque         t  "Cut-torque directed into flange to drive it";
end DrivePos;

connector CutFrame "3D mechanical cut-frame for multibody systems" 
  Real                S[3,3] "Rotation matrix describing the cut-frame "
			     "with respect to the inertial frame";
  Position            r0[3]  "Vector from the origin of the inertial frame to the "
			     "origin of the cut-frame, resolved in the inertial frame";
  Velocity            v[3]   "Absolute translational velocity of the cut-frame, "
			     "resolved in the cut-frame ( v = S'*der(r0) )";
  AngularVelocity     w[3]   "Absolute angular velocity of the cut-frame, "
			     "resolved in the cut-frame ( w = vec(S'*der(S)) )";
  Acceleration        a[3]   "Absolute translational acceleration of the cut-frame, "
			     "resolved in the cut-frame ( a = S'*der(S*v) )";
  AngularAcceleration z[3]   "Absolute angular acceleration of the cut-frame, "
			     "resolved in the cut-frame ( z = S'*der(S*w) )";
  flow Force          f[3]   "Resultant cut-force acting at the origin of the "
			     "cut-frame, resolved in the cut-frame";
  flow Torque         t[3]   "Resultant cut-torque with respect to the origin of the "
			     "cut-frame, resolved in the cut-frame";
end CutFrame;

// Partial models for mechanic components
partial model TransVel2 "1D translational component with two cuts" 
  TransVel a  "Cut a of component";
  TransVel b  "Cut b of component";
end TransVel2;

partial model DriveVel2 "1D rotational component with two cuts" 
  DriveVel a  "Flange a of component";
  DriveVel b  "Flange b of component";
end DriveVel2;

partial model TransPos2 "1D translational component with two cuts" 
			"for positional drive trains."
  TransPos a  "Cut a of component";
  TransPos b  "Cut b of component";
end TransPos2;

partial model DrivePos2 "1D rotational component with two cuts" 
			"for positional drive trains."
  DrivePos a  "Flange a of component";
  DrivePos b  "Flange b of component";
end DrivePos2;

partial model CutFrame2 "Multi-body system component with two cut frames" 
  CutFrame a  "cut frame a";
  CutFrame b  "cut frame b";
end CutFrame2;
end Mechanic;



package Thermodynamic

/* Connector types for thermodynamical components. This is a minimum 
   set! Defining more is not difficult, but only useful if a library 
   based on them is provided as well. Shorthands for basic types 
   used here are provided as well.
*/

// Short hands
type HeatFlux = HeatFlowRate;
type Temp_K   = ThermodynamicTemperature;
type Temp_C   = CelsiusTemperature;

// connectors
connector TQ  "Heat exchange interface"
  Temp_C         T  "Temperature";
  flow HeatFlux  q  "Transported heat into interface";
end TQ;

connector MT  "Single directional flow of tempered fluid, no pressure"
  flow MassFlow  m_dot  "Massflow into port";
  Temp_C         T      "Fluid temperature";
end MT;

connector PM  "Bidirectional flow of a fluid"
  Pressure       p      "Fluid total pressure";
  flow MassFlow  m_dot  "Massflow into port";
end PM;

connector PMT  "Single directional flow of tempered fluid"
  Pressure       p      "Fluid total pressure";
  flow MassFlow  m_dot  "Massflow into port";
  Temp_C         T      "Fluid temperature";
end PMT;

connector PMH  "Single directional flow of tempered fluid"
  Pressure          p      "Fluid total pressure";
  flow MassFlow     m_dot  "Massflow into port";
  SpecificEnthalpy  h      "Fluid enthalpy";
end PMH;

connector PMTQ  "Bidirectional flow of tempered fluid"
  Pressure       p       "Fluid total pressure";
  flow MassFlow  m_dot   "Massflow into port";
  Temp_C         T       "Fluid temperature";
  flow HeatFlux  q       "Heat convected by fluid into port";
end PMTQ;

connector PMHQ  "Bidirectional flow of tempered fluid"
  Pressure          p      "Fluid total pressure";
  flow Massflow     m_dot  "Massflow into port";
  SpecificEnthalpy  h      "Fluid enthalpy";
  flow HeatFlux     q      "Heat convected by fluid into port";
end PMHQ;

end Thermodynamic;


end Interface;

end Modelica;
