model CombiTimeTableTest
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Text(visible=true, fillPattern=FillPattern.Solid, extent={{-100,-150},{100,-110}}, textString="%name")}),Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})));
  Modelica.Blocks.Sources.CombiTimeTable combiTimeTable1(table=[0,0;1,0;1,1;2,4;3,9;4,16]) annotation(Placement(visible=true,transformation(x=-60.1927,y=27.1198,scale=0.075)));
  Modelica.Blocks.Sources.CombiTimeTable combiTimeTable2(tableName="A",fileName="testTables2.txt",tableOnFile=true);
end CombiTimeTableTest;


