function tempInterpol2
  "temporary routine for vectorized linear interpolation (will be removed)"

  input Real u "input value (first column of table)";
  input Real table[:, :] "table to be interpolated";
  input Integer icol[:] "column(s) of table to be interpolated";
  output Real y[1, size(icol, 1)]
    "interpolated input value(s) (column(s) icol of table)";
protected
  Integer i;
  Integer n "number of rows of table";
  Real u1;
  Real u2;
  Real y1[1, size(icol, 1)];
  Real y2[1, size(icol, 1)];
algorithm
  n := size(table, 1);

  if n <= 1 then
    y := transpose([table[1, icol]]);

  else
    // Search interval

    if u <= table[1, 1] then
      i := 1;

    else
      i := 2;
      // Supports duplicate table[i, 1] values
      // in the interior to allow discontinuities.
      // Interior means that
      // if table[i, 1] = table[i+1, 1] we require i>1 and i+1<n

      while i < n and u >= table[i, 1] loop
        i := i + 1;

      end while;
      i := i - 1;

    end if;

    // Get interpolation data
    u1 := table[i, 1];
    u2 := table[i + 1, 1];
    y1 := transpose([table[i, icol]]);
    y2 := transpose([table[i + 1, icol]]);

    assert(u2 > u1, "Table index must be increasing");
    // Interpolate
    y := y1 + (y2 - y1)*(u - u1)/(u2 - u1);

  end if;
end tempInterpol2;


model tempInterpol2test
  Real u = 1.6;
  Real[2,2] table=[1,2;3,4];
  //Integer[2] icol={1,2};
  Real[1,2] y;
equation
  y = tempInterpol2(u,table,{1,2});
end tempInterpol2test;