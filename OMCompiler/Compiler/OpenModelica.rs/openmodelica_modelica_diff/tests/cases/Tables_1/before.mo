within Modelica.Blocks;
package Tables
  package Internal
      function getTable1DValueDer
      input Real u;
      input Real tableAvailable
        "Dummy input to ensure correct sorting of function calls";
      external"C" der_y = ModelicaStandardTables_CombiTable1D_getDerValue(tableID, icol, u, der_u);
      end getTable1DValueDer;
  end Internal;
end Tables;
