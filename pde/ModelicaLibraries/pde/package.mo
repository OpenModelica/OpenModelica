package PDE "PDE Package for Finite Differences and Finite Elements in 1 and 2 Space Dimensions."
  extends Modelica.Icons.Library;
  import SI = Modelica.SIunits;


annotation(Documentation(info="<HTML>
<p>
This PDE package cointains an outline for treating partial differential equations 
in Modelica, using both the finite difference method (FDM) and 
the finite element method (FEM) in one- and two-dimensional space.
</p>
<p>
The current version of the library was created June 20.-30. 2004. It is divided into the following parts:
</p>
<ul>
<li> <b>Elements:</b> basic geometrical elements.</li>
<li> <b>FDM:</b> finite difference methods.</li>
<li> <b>FEM:</b> finite element methods.</li>
<li> <b>Shape:</b> rudimentary shaping functions.</li>
</ul> 
<p>
<li> A separate small test package <b>TestPDE</b> is also available.</li>
</p>
<p>
<br><b>Authors:</b>
<br>
<br> Hansj&uuml;rg Wiesmann, ABB Corporate Research, CH-5405 Baden
<br>hj.wiesmann@bluewin.ch
<br>
<br> Bernhard Bachmann, University of Applied Sciences, D-33609 Bielefeld
<br> bernhard.bachmann@fh-bielefeld.de
<br>
<br> Levon Saldamli, Link&ouml;ping University, SE-587 23 Link&ouml;ping
<br> levsa@ida.liu.se
<br>
</p>
<p>
<br><b>Concept, implementation and testing is not yet completed! </b> (June 2004)</b>
<br> Bernhard and Hansj&uuml;rg are grateful to Peter Fritzson for his hospitality
<br> and the possibility to work at Link&ouml;ping University.
</p>
</HTML>
"));
end PDE;
