model DefaultCompartment "Default model for a compartment"
  annotation(preferedView="info", Documentation(info="<html>
 <p>
 Default compartment model.
 </p>
 </html>
 \",revisions=\"
 <html>
 <ul>
 Main Author 2006: Erik Ulfhielm <br>
 Main Author 2004-2005: Emma Larsdotter Nilsson <br> <br>
 Copyright (c) 2005-2006  Link[ODoubleDot]pings universitet and Modelica Association <br> <br>
 The BioChem package is free software and can be redistributed <br>
 and/or modified under the terms of the Modelica License with <br>
 the additional provision that changed parts of BioChem also <br>
 must be made available under this License. <br>
 </ul>
 </html>
 "), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-191.31,-134.36},{190.73,-103.24}}, textString="%name", fontSize=20.0, fontName="Arial")}));
  extends BioChem.Interfaces.CompartmentProperties.LiquidCompartmentProperties;
  extends BioChem.Interfaces.Icons.DefaultCompartment;
  inner parameter BioChem.Units.Concentration tolerance=(-1)/1000000 "Tolerance for concentration";
  annotation(defaultComponentName="compartment", defaultComponentPrefixes="inner", Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}), graphics={Text(extent={{-150.0,-120.0},{150.0,-140.0}}, fillColor={0,0,255}, rgbcolor={0,0,255}, textString="%name")}));
end DefaultCompartment;
model A
  annotation(foo=bar);
  annotation(defaultComponentName="AAABB",defaultComponentPrefixes="inner parameter");
  Real x;
equation
x=1;
end A;
model A2
  Real x;
end A2;
model A3
  annotation(defaultComponentPrefixes="outer replaceable");
  Real a3;
end A3;
model B
end B;
