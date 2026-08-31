package ModelicaServices
  package ExternalReferences
    function loadResource
      extends
        Modelica.Utilities.Internal.PartialModelicaServices.ExternalReferences.PartialLoadResource;
    algorithm
      _ := test();
    end loadResource;
  end ExternalReferences;

  annotation(Documentation(info = "Fake ModelicaServices used by the UnpatchedModelicaServices test case"));
end ModelicaServices;
