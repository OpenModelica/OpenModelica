//This code is generated from a ModelicaML model.

within TwoTanksSystemExample.Design.Library;

function limitValue
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-37.381,-45.476}, points={{-57.619,-9.524},{-57.619,20.476},{-37.619,20.476},{-37.619,40.476},{-17.619,40.476},{-17.619,50.476},{12.381,50.476},{12.381,40.476},{32.381,40.476},{32.381,20.476},{52.381,20.476},{52.381,-9.524},{32.381,-9.524},{32.381,-29.524},{12.381,-29.524},{12.381,-39.524},{-17.619,-39.524},{-17.619,-29.524},{-37.619,-29.524},{-37.619,-9.524},{-57.619,-9.524}}, thickness=10),Line(visible=true, origin={-38.654,-42.2231}, points={{-13.846,4.615},{-3.846,4.615},{-3.846,14.615},{6.154,14.615},{6.154,4.615},{16.154,4.615},{16.154,-5.385},{6.154,-5.385},{6.154,-15.385},{-3.846,-15.385},{-3.846,-5.385},{-13.846,-5.385},{-13.846,4.615}}, color={128,128,128}, thickness=5),Line(visible=true, origin={45.4776,34.524}, points={{-57.619,-9.524},{-57.619,20.476},{-37.619,20.476},{-37.619,40.476},{-17.619,40.476},{-17.619,50.476},{12.381,50.476},{12.381,40.476},{32.381,40.476},{32.381,20.476},{52.381,20.476},{52.381,-9.524},{32.381,-9.524},{32.381,-29.524},{12.381,-29.524},{12.381,-39.524},{-17.619,-39.524},{-17.619,-29.524},{-37.619,-29.524},{-37.619,-9.524},{-57.619,-9.524}}, thickness=10),Line(visible=true, origin={41.0348,40.385}, points={{-13.846,4.615},{-3.846,4.615},{-3.846,14.615},{6.154,14.615},{6.154,4.615},{16.154,4.615},{16.154,-5.385},{6.154,-5.385},{6.154,-15.385},{-3.846,-15.385},{-3.846,-5.385},{-13.846,-5.385},{-13.846,4.615}}, color={128,128,128}, thickness=5)}));
  input Real pMin;
  input Real pMax;
  output Real pLim;
  input Real p;
  algorithm

  // code generated from the Activity "limit value algorithm" (ConditionalAlgorithm(Diagram))

  // if/when-else code
  if p < pMin then
      // OpaqueAction: "limit value algorithm.pLim := pMin;"
      pLim := pMin;
    elseif p > pMax then
      // OpaqueAction: "limit value algorithm.pLim := pMax;"
      pLim := pMax;
    else
      // OpaqueAction: "limit value algorithm.pLim := p;"
      pLim := p;
  end if;
end limitValue;

