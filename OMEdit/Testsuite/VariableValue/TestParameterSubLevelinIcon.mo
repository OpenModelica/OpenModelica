package TestParameterSubLevelinIcon
  model testmodel1
    extends testmodel2;
    parameter Real a = 1;

    testrecord testrecord1
      annotation (Placement(transformation(extent={{-76,26},{-56,46}})));
    annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={Text(lineColor = {28, 108, 200}, extent = {{-48, 76}, {40, 26}}, textString = "a = %a"),
          Text(lineColor = {28, 108, 200}, extent = {{-50, 8}, {40, -46}}, textString = "b = %{b}"),
          Text(lineColor = {28, 108, 200}, extent = {{-60, -60}, {72, -90}}, textString = "c = %{testrecord1.c}")}),                    Diagram(
          coordinateSystem(preserveAspectRatio=false)));
  end testmodel1;

  model testmodel2
    parameter Real b = 2;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
          coordinateSystem(preserveAspectRatio=false)));
  end testmodel2;

  record testrecord
    parameter Real c = 3;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
          coordinateSystem(preserveAspectRatio=false)));
  end testrecord;


  model ClassWhereTestModelisUsed
    TestParameterSubLevelinIcon.testmodel1 testmodel1 annotation(
      Placement(visible = true, transformation(origin = {-26, 12}, extent = {{-46, -32}, {46, 32}}, rotation = 0)));
  equation

  end ClassWhereTestModelisUsed;

end TestParameterSubLevelinIcon;
