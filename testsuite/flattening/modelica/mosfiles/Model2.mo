model Model2
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  inner Modelica.Mechanics.MultiBody.World world annotation(Placement(visible=true, transformation(origin={-86.5408,13.2292}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Joints.Revolute revolute1(useAxisFlange=true) annotation(Placement(visible=true, transformation(origin={-50.0,13.2292}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder1(r={0,0.1,0}) annotation(Placement(visible=true, transformation(origin={-16.0634,15.3559}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Joints.Revolute revolute2 annotation(Placement(visible=true, transformation(origin={17.0877,14.6072}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder2(r={0,0.2,0}) annotation(Placement(visible=true, transformation(origin={50.0,13.6486}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Joints.Prismatic prismatic1(n={0,-1,0}) annotation(Placement(visible=true, transformation(origin={-7.717,84.1341}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation1(r={0,0.4,0}, animation=false) annotation(Placement(visible=true, transformation(origin={-51.5386,84.3359}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder3(r={0,-0.1,0}) annotation(Placement(visible=true, transformation(origin={102.678,57.3921}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-450)));
  Modelica.Mechanics.Rotational.Components.Inertia inertia1(J=1, phi.start=0, w.start=10, phi.stateSelect=StateSelect.always, w.stateSelect=StateSelect.always) annotation(Placement(visible=true, transformation(origin={-50.0,53.2292}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Joints.RevolutePlanarLoopConstraint revolutePlanarLoopConstraint1 annotation(Placement(visible=true, transformation(origin={82.1311,14.3316}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
equation
  connect(bodyCylinder2.frame_b,revolutePlanarLoopConstraint1.frame_a) annotation(Line(visible=true, origin={66.2983,13.9901}, points={{-6.2983,-0.3415},{0.2328,-0.3415},{0.2328,0.3415},{5.8328,0.3415}}));
  connect(bodyCylinder3.frame_b,revolutePlanarLoopConstraint1.frame_b) annotation(Line(visible=true, origin={99.1623,25.3518}, points={{3.5156,22.0403},{3.5156,-11.0202},{-7.0312,-11.0202}}));
  connect(revolute2.frame_b,bodyCylinder2.frame_a) annotation(Line(visible=true, origin={34.7719,14.1279}, points={{-7.6842,0.4793},{1.2281,0.4793},{1.2281,-0.4793},{5.2281,-0.4793}}));
  connect(bodyCylinder1.frame_b,revolute2.frame_a) annotation(Line(visible=true, origin={0.7999,14.9816}, points={{-6.8633,0.3743},{0.2878,0.3743},{0.2878,-0.3743},{6.2878,-0.3743}}));
  connect(inertia1.flange_b,revolute1.axis) annotation(Line(visible=true, origin={-40.8,37.6292}, points={{0.8,15.6},{8.8,15.6},{8.8,-8.4},{-9.2,-8.4},{-9.2,-14.4}}));
  connect(bodyCylinder3.frame_a,prismatic1.frame_b) annotation(Line(visible=true, origin={69.213,78.5534}, points={{33.465,-11.1613},{33.465,5.5807},{-66.93,5.5807}}, color={95,95,95}));
  connect(revolute1.frame_b,bodyCylinder1.frame_a) annotation(Line(visible=true, origin={-31.5475,14.2925}, points={{-8.4525,-1.0634},{1.4842,-1.0634},{1.4842,1.0634},{5.4842,1.0634}}));
  connect(fixedTranslation1.frame_b,prismatic1.frame_a) annotation(Line(visible=true, origin={-27.6724,84.235}, points={{-13.8662,0.1009},{1.9554,0.1009},{1.9554,-0.1009},{9.9554,-0.1009}}));
  connect(fixedTranslation1.frame_a,world.frame_b) annotation(Line(visible=true, origin={-69.0903,48.7826}, points={{7.5516,35.5534},{-0.0505,35.5534},{-0.0505,-35.5534},{-7.4505,-35.5534}}));
  connect(world.frame_b,revolute1.frame_a) annotation(Line(visible=true, origin={-68.2704,13.2292}, points={{-8.2704,0.0},{8.2704,-0.0}}));
end Model2;
