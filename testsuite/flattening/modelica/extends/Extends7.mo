// name:     Extends7
// keywords: extends
// status:   correct
//
// Testing that you can extend a partial package in a package that extends the same package.
// See bug: http://openmodelica.ida.liu.se:8080/cb/issue/1184?navigation=true

package Modelica
package Utilities
  package Files
    function fullPathName
      input String name "Absolute or relative file or directory name";
      output String fullName "Full path of 'name'";
      external "C";
    end fullPathName;
  end Files;
end Utilities;
end Modelica;

package Utilities "Utility classes usually not directly utilized by the user"
  extends Icons.Package;
  constant String RootDir = ".";

  package Icons
    extends Package;
    partial class Package "Icon for a package class"
      annotation(Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}, grid={1,1}), graphics={Rectangle(extent={{-60,100},{100,-60}}, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid),Polygon(points={{-100,60},{-60,100},{-60,60},{-100,60}}, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid),Polygon(points={{60,-60},{100,-60},{60,-100},{60,-60}}, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid),Rectangle(extent={{-100,60},{60,-100}}, lineColor={0,0,255}, fillColor={215,215,215}, fillPattern=FillPattern.Solid)}));
    end Package;
  end Icons;
end Utilities;

// Result:
// class Utilities "Utility classes usually not directly utilized by the user"
//   constant String RootDir = ".";
// end Utilities;
// endResult
