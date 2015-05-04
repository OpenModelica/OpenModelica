within ;
function getStopTime
 input String modelName;
 output Real stopTime;
protected
 String s;
 Integer l;
algorithm
 // Get Annotation and its length
 s := ModelManagement.Structure.AST.GetAnnotation(modelName, "experiment.StopTime");
 l := Modelica.Utilities.Strings.length(s);
 if (l == 0) then
  stopTime := 1.0;
 else
  // cut first character ('=') off
  s := Modelica.Utilities.Strings.substring(s, 2, l);
  // convert it into a real
  stopTime := Modelica.Utilities.Strings.scanReal(s);
 end if;
  annotation (uses(Modelica(version="3.2.1")));
end getStopTime;
