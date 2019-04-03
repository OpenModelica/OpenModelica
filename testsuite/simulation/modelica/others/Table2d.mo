model Table2d
  Modelica.Blocks.Tables.CombiTable2D combitable2d1(tableOnFile = true,
      tableName = "tab1", fileName = "Table2d.txt");
  Modelica.Blocks.Sources.Constant zeile(k = 60);
  Modelica.Blocks.Sources.Constant const(k = 2);
equation
  connect(const.y,combitable2d1.u2);
  connect(zeile.y,combitable2d1.u1);
end Table2d;

