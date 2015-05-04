within SiemensPower.Interfaces;
connector FluidPort
  "Interface for quasi one-dimensional fluid flow in a piping network (incompressible or compressible, one or more phases, one or more substances)"
  import SI = Modelica.SIunits;

 // replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
 //   "Medium model" annotation (choicesAllMatching=true);

  flow SI.MassFlowRate m_flow
    "Mass flow rate from the connection point into the component";
  SI.AbsolutePressure p "Thermodynamic pressure in the connection point";
  stream SI.SpecificEnthalpy h_outflow
    "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
  //stream SI.MassFraction Xi_outflow[Medium.nXi]
  //  "Independent mixture mass fractions m_i/m close to the connection point if m_flow < 0";
  //stream SI.ExtraProperty C_outflow[Medium.nC]
  //  "Properties c_i/m close to the connection point if m_flow < 0";
end FluidPort;
