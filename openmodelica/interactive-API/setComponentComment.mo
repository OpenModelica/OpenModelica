// Fake MSL structure so we don't have to load it.
package Modelica
  package Electrical
    package Analog
      package Basic
        model EMF end EMF;
      end Basic;
    end Analog;
  end Electrical;
end Modelica;

model model1
 Modelica.Electrical.Analog.Basic.EMF emf1;
end model1;

