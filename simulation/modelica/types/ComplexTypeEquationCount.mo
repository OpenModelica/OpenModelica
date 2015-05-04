package Modelica
  package Icons
    type TypeReal
      extends Real;
    end TypeReal;
  end Icons;
end Modelica;

model ComplexTypeEquationCount
  type Transparency= Modelica.Icons.TypeReal(min=0, max=1);
  type Shininess= Modelica.Icons.TypeReal(min=0, max=1);
  input Transparency transparency=0 ;
  Shininess shininess=0 ;
end ComplexTypeEquationCount;
