import "PDE.mo";


package testField 
  model CircleFieldTest 
    import PDE2D.Boundaries.*;
    import PDE2D.*;
    parameter Integer n=20;
    parameter Real refine=0.5;
    parameter Circle.Parameters bndparams(c={0,0}, r=2);
    parameter Circle.Data circle(p=bndparams);
    package myDomain = Domain (redeclare package boundaryP = Circle);
    parameter myDomain.Data mydomain(boundary=circle);
    
    function myfunc 
      input Point x;
      input myField.Data d;
      output myField.FieldType y;
    algorithm 
      y := cos(2*Arc.pi*x[1]/6) + sin(2*Arc.pi*x[2]/6);
    end myfunc;
    
    function peaks 
      input Point x;
      input myField.Data d;
      output myField.FieldType y;
    algorithm 
      y := 3*(1 - x[1])^2.*exp(-(x[1]^2) - (x[2] + 1)^2) - 10*(x[1]/5 - x[1]^3
         - x[2]^5)*exp(-x[1]^2 - x[2]^2) - 1/3*exp(-(x[1] + 1)^2 - x[2]^2);
    end peaks;
    
    package myField = Field (redeclare package domainP = myDomain, redeclare 
          function value = myfunc);
    myField.Data myfield(domain=mydomain);
    
    Real u[10]={myField.value({x,x}, myfield) for x in 1:10};
  end CircleFieldTest;
  
  model CircleDiscreteFieldTest 
    import PDE2D.Boundaries.*;
    import PDE2D.*;
    parameter Integer n=20;
    parameter Real refine=0.5;
    parameter Circle.Parameters bndparams(c={0,0}, r=2);
    parameter Circle.Data circle(p=bndparams);
    
    package myDomain = Domain (redeclare package boundaryP = Circle);
    parameter myDomain.Data mydomain(boundary=circle);
    
    function myfunc 
      input Point x;
      input myField.Data d;
      output myField.FieldType y;
    algorithm 
      y := cos(2*Arc.pi*x[1]/6) + sin(2*Arc.pi*x[2]/6);
    end myfunc;
    
    function peaks 
      input Point x;
      input myField.Data d;
      output myField.FieldType y;
    algorithm 
      y := 3*(1 - x[1])^2.*exp(-(x[1]^2) - (x[2] + 1)^2) - 10*(x[1]/5 - x[1]^3
         - x[2]^5)*exp(-x[1]^2 - x[2]^2) - 1/3*exp(-(x[1] + 1)^2 - x[2]^2);
    end peaks;
    
    package myField = Field (redeclare package domainP = myDomain, redeclare 
          function value = myfunc);
    
    myField.Data myfield(domain=mydomain);
    
    package myDDomain = FEM.DiscreteDomain (redeclare package domainP = 
            myDomain);
    myDDomain.Data myddomain(
      nbp=n, 
      domain=mydomain, 
      refine=refine);
    
    package myDField = FEM.DiscreteField (redeclare package fieldP = myField, 
          redeclare package ddomainP = myDDomain);
    
    myDField.Data dfield(
      ddomain=myddomain, 
      field=myfield, 
      val(start=interpolation.interpolate(myddomain, myfield, myddomain.mesh.nv)));
    package interpolation = FEM.Interpolation (redeclare package dfieldP = 
            myDField);
  equation 
    //  dfield.val = {i for i in 1:dfield.fieldSize};
    dfield.val = interpolation.interpolate(myddomain, myfield, myddomain.mesh.
      nv);
  end CircleDiscreteFieldTest;

  model MyBoundaryFieldTest 
    import PDE2D.Boundaries.*;
    import PDE2D.*;
    parameter Integer n=64;
    parameter Real refine=0.7;
    parameter Point p0={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    
    package MyBoundary = testDomain.MyBoundary;
    
    parameter MyBoundary.Parameters bndparams(
      p=p0, 
      w=w, 
      h=h, 
      r=r);
    parameter MyBoundary.Data myboundary(p=bndparams);
    
    package myDomainP = Domain (redeclare package boundaryP = MyBoundary);
    parameter myDomainP.Data mydomain(boundary=myboundary);
    
    function myfunc 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := cos(2*Arc.pi*x[1]/6) + sin(2*Arc.pi*x[2]/6);
    end myfunc;
    
    function peaks 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := 3*(1 - x[1])^2.*exp(-(x[1]^2) - (x[2] + 1)^2) - 10*(x[1]/5 - x[1]^3
         - x[2]^5)*exp(-x[1]^2 - x[2]^2) - 1/3*exp(-(x[1] + 1)^2 - x[2]^2);
    end peaks;
    
    package myFieldP = Field (redeclare package domainP = myDomainP, redeclare 
          function value = myfunc);
    
    myFieldP.Data myfield(domain=mydomain);
    
    package myDDomain = FEM.DiscreteDomain (redeclare package domainP = 
            myDomainP);
    myDDomain.Data myddomain(
      nbp=n, 
      domain=mydomain, 
      refine=refine);
    
    package myDField = FEM.DiscreteField (redeclare package fieldP = myFieldP, 
          redeclare package ddomainP = myDDomain);
    
    myDField.Data dfield(
      ddomain=myddomain, 
      field=myfield, 
      val(start=interpolation.interpolate(myddomain, myfield, myddomain.mesh.nv)));
    package interpolation = FEM.Interpolation (redeclare package dfieldP = 
            myDField);
  equation 
    //  dfield.val = {i for i in 1:dfield.fieldSize};
    dfield.val = interpolation.interpolate(myddomain, myfield, myddomain.mesh.
      nv);
  end MyBoundaryFieldTest;

  model MyGenericBoundaryFieldTest 
    import PDE2D.Boundaries.*;
    import PDE2D.*;
    parameter Integer n=64;
    parameter Real refine=0.7;
    parameter Point p0={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    
    package MyBoundary = testDomain.MyGenericBoundary;
    
    parameter MyBoundary.Parameters bndparams(
      p0=p0, 
      w=w, 
      h=h, 
      r=r, 
      cw=cw);
    parameter MyBoundary.Data myboundary(p=bndparams);
    
    package myDomainP = Domain (redeclare package boundaryP = MyBoundary);
    parameter myDomainP.Data mydomain(boundary=myboundary);
    
    function myfunc 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := cos(2*Arc.pi*x[1]/6) + sin(2*Arc.pi*x[2]/6);
    end myfunc;
    
    function peaks 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := 3*(1 - x[1])^2.*exp(-(x[1]^2) - (x[2] + 1)^2) - 10*(x[1]/5 - x[1]^3
         - x[2]^5)*exp(-x[1]^2 - x[2]^2) - 1/3*exp(-(x[1] + 1)^2 - x[2]^2);
    end peaks;
    
    package myFieldP = Field (redeclare package domainP = myDomainP, redeclare 
          function value = myfunc);
    
    myFieldP.Data myfield(domain=mydomain);
    
    package myDDomain = FEM.DiscreteDomain (redeclare package domainP = 
            myDomainP);
    myDDomain.Data myddomain(
      nbp=n, 
      domain=mydomain, 
      refine=refine);
    
    package myDField = FEM.DiscreteField (redeclare package fieldP = myFieldP, 
          redeclare package ddomainP = myDDomain);
    
    myDField.Data dfield(
      ddomain=myddomain, 
      field=myfield, 
      val(start=interpolation.interpolate(myddomain, myfield, myddomain.mesh.nv)));
    package interpolation = FEM.Interpolation (redeclare package dfieldP = 
            myDField);
  equation 
    //  dfield.val = {i for i in 1:dfield.fieldSize};
    dfield.val = interpolation.interpolate(myddomain, myfield, myddomain.mesh.
      nv);
  end MyGenericBoundaryFieldTest;
end testField;
