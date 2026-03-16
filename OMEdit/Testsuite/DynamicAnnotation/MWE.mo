within ;
package MWE
  model Unnamed
    inner Modelica.Mechanics.MultiBody.World world(animateWorld= false) annotation (Placement(transformation(extent={{-80,70},{-60,90}})));
    Test test(a = 4)  annotation (Placement(transformation(extent={{48,-16},{68,4}})));
    annotation ();
  end Unnamed;

  model Test
    parameter Real a=3 annotation(Dialog(enable=world.animateWorld));
    outer Modelica.Mechanics.MultiBody.World world;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(coordinateSystem(preserveAspectRatio=false)));
  end Test;
  annotation (uses(Modelica(version="4.0.0")));
end MWE;
