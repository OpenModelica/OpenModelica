package FEMForms 
  package Autonomous 
    package Poisson2D "Poisson problem 2D" 
      import PDEbhjl.FEMForms.FEMSolver.*;
      
      // replaceable package Solver = InternalSolver;
      // replaceable package Solver = FEMSolver;
      
      replaceable package domainP = Domain;
      //  replaceable package initialField = ConstField;
      /* (redeclare function value = 
  valfunc); */
      //replaceable function valfunc = ConstField.value;
      
      model Equation "Poisson equation 2D" 
        parameter Real g0=1 "Constant value of field";
        parameter domainP.Data domain;
        parameter Integer nbp=20;
        parameter Real refine=0.7;
        parameter Integer nbc=1;
        parameter BCType bc[nbc]={{1,0,1} for i in 1:nbc};
        //parameter initialField.Parameters inifp;
        
        // internal packages  
        package rhsFieldP = ConstConstField (redeclare package domainP = 
                domainP);
        parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
        
        package uFieldP = Field (redeclare package domainP = domainP);
        parameter uFieldP.Data uField(domain=domain);
        
        // discrete part
        package ddomainP = DiscreteDomain (redeclare package domainP = domainP);
        parameter ddomainP.Data ddomain(
          domain=domain, 
          nbp=nbp, 
          refine=refine);
        
        // Why doesn't these work?
        // parameter FormSize formsize=getFormSize(ddomain.mesh.filename, ddomain.mesh.nv);
        // parameter FormSize formsize=getFormSize("default_mesh2d.txt", 79);
        
        parameter Integer interiorSize=integer(sum(DomainOperators.interior2D(
            ddomain.mesh.nv, ddomain.mesh.x)));
        
        // Assuming boundary blocked, i.e. all dirichlet bc.
        parameter FormSize formsize=FormSize(interiorSize, ddomain.mesh.nv - 
            interiorSize);
        parameter Integer u_indices[formsize.nu]=getUnknownIndices(ddomain.mesh
            .filename, ddomain.mesh.nv, formsize.nu, nbc, bc);
        parameter Integer b_indices[formsize.nb]=getBlockedIndices(ddomain.mesh
            .filename, ddomain.mesh.nv, formsize.nb, nbc, bc);
        
        package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                rhsFieldP, redeclare package ddomainP = ddomainP);
        package interpolationP = Interpolation (redeclare package dfieldP = 
                rhsDFieldP);
        parameter rhsDFieldP.Data g_rhs(
          ddomain=ddomain, 
          field=rhsField, 
          formsize=formsize, 
          u_indices=u_indices, 
          b_indices=b_indices, 
          val_u=interpolationP.interpolate_indirect(ddomain, rhsField, formsize
              .nu, u_indices), 
          val_b=interpolationP.interpolate_indirect(ddomain, rhsField, formsize
              .nb, b_indices));
        
        package uDFieldP = DiscreteField (redeclare package ddomainP = ddomainP, 
              redeclare package fieldP = uFieldP);
        uDFieldP.Data fd(
          ddomain=ddomain, 
          field=uField, 
          formsize=formsize, 
          u_indices=u_indices, 
          b_indices=b_indices, 
          val_u(start={1 for i in 1:formsize.nu}));
        
      protected 
        parameter Real laplace_uu[formsize.nu, formsize.nu]=getForm_gradgrad_uu(
            fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize
            .nb, nbc, bc);
        parameter Real laplace_ub[formsize.nu, formsize.nb]=getForm_gradgrad_ub(
            fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize
            .nb, nbc, bc);
        parameter Real mass_uu[formsize.nu, formsize.nu]=getForm_mass_uu(fd.
            ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.nb, 
            nbc, bc);
        parameter Real mass_ub[formsize.nu, formsize.nb]=getForm_mass_ub(fd.
            ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.nb, 
            nbc, bc);
        parameter Real bvals[formsize.nb]=getBlockedValues(fd.ddomain.mesh.
            filename, fd.ddomain.mesh.nv, formsize.nb, nbc, bc);
      equation 
        laplace_uu*fd.val_u = mass_uu*g_rhs.val_u + mass_ub*g_rhs.val_b - 
          laplace_ub*fd.val_b;
        fd.val_b = bvals;
      end Equation;
      
      annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80, 80; 80, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              fillColor=7, 
              rgbfillColor={255,255,255})), 
          Line(points=[-100, 80; -100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Line(points=[100, 80; 100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Text(
            extent=[60, -20; -60, 0], 
            style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1), 
            string="Poisson 2D"), 
          Line(points=[-70, 100; 70, 100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1)), 
          Line(points=[-70, -100; 70, -100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1))));
      annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80, 80; 80, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              fillColor=7, 
              rgbfillColor={255,255,255})), 
          Line(points=[-100, 80; -100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Line(points=[100, 80; 100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Text(
            extent=[60, -20; -60, 0], 
            style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1), 
            string="Poisson 2D"), 
          Line(points=[-70, 100; 70, 100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1)), 
          Line(points=[-70, -100; 70, -100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1))));
      
    end Poisson2D;
    
    package Diffusion2D "Poisson problem 2D" 
      import PDEbhjl.FEMForms.FEMSolver.*;
      
      //replaceable package Solver = InternalDiffusionSolver;
      //replaceable package Solver = RheolefSolver;
      function interior = DomainOperators.interior2D;
      
      replaceable package domainP = Domain;
      //  replaceable package initialField = ConstField;
      /* (redeclare function value = 
  valfunc); */
      //replaceable function valfunc = ConstField.value;
      
      model Equation "Poisson equation 2D" 
        parameter Real g0=1 "Constant value of field";
        parameter domainP.Data domain;
        parameter Integer nbp=20;
        parameter Real refine=0.7;
        parameter Integer nbc=1;
        parameter BCType bc[nbc]={{1,0,1} for i in 1:nbc};
        //parameter initialField.Parameters inifp;
        
        // internal packages  
        package rhsFieldP = ConstConstField (redeclare package domainP = 
                domainP);
        parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
        
        package uFieldP = Field (redeclare package domainP = domainP);
        parameter uFieldP.Data uField(domain=domain);
        
        // discrete part
        package ddomainP = DiscreteDomain (redeclare package domainP = domainP);
        parameter ddomainP.Data ddomain(
          domain=domain, 
          nbp=nbp, 
          refine=refine);
        
        // Why doesn't these work?
        // parameter FormSize formsize=getFormSize(ddomain.mesh.filename, ddomain.mesh.nv);
        // parameter FormSize formsize=getFormSize("default_mesh2d.txt", 79);
        
        parameter Integer interiorSize=integer(sum(DomainOperators.interior2D(
            ddomain.mesh.nv, ddomain.mesh.x)));
        
        // Assuming boundary blocked, i.e. all dirichlet bc.
        parameter FormSize formsize=FormSize(interiorSize, ddomain.mesh.nv - 
            interiorSize);
        parameter Integer u_indices[formsize.nu]=getUnknownIndices(ddomain.mesh
            .filename, ddomain.mesh.nv, formsize.nu, nbc, bc);
        parameter Integer b_indices[formsize.nb]=getBlockedIndices(ddomain.mesh
            .filename, ddomain.mesh.nv, formsize.nb, nbc, bc);
        
        package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                rhsFieldP, redeclare package ddomainP = ddomainP);
        package interpolationP = Interpolation (redeclare package dfieldP = 
                rhsDFieldP);
        parameter rhsDFieldP.Data g_rhs(
          ddomain=ddomain, 
          field=rhsField, 
          formsize=formsize, 
          u_indices=u_indices, 
          b_indices=b_indices, 
          val_u=interpolationP.interpolate_indirect(ddomain, rhsField, formsize
              .nu, u_indices), 
          val_b=interpolationP.interpolate_indirect(ddomain, rhsField, formsize
              .nb, b_indices));
        
        package uDFieldP = DiscreteField (redeclare package ddomainP = ddomainP, 
              redeclare package fieldP = uFieldP);
        uDFieldP.Data fd(
          ddomain=ddomain, 
          field=uField, 
          formsize=formsize, 
          u_indices=u_indices, 
          b_indices=b_indices, 
          val_u(start={0 for i in 1:formsize.nu}));
        
      protected 
        parameter Real laplace_uu[formsize.nu, formsize.nu]=getForm_gradgrad_uu(
            fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize
            .nb, nbc, bc);
        parameter Real laplace_ub[formsize.nu, formsize.nb]=getForm_gradgrad_ub(
            fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize
            .nb, nbc, bc);
        parameter Real mass_uu[formsize.nu, formsize.nu]=getForm_mass_uu(fd.
            ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.nb, 
            nbc, bc);
        parameter Real mass_ub[formsize.nu, formsize.nb]=getForm_mass_ub(fd.
            ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.nb, 
            nbc, bc);
        parameter Real bvals[formsize.nb]=getBlockedValues(fd.ddomain.mesh.
            filename, fd.ddomain.mesh.nv, formsize.nb, nbc, bc);
      equation 
        mass_uu*der(fd.val_u) = -laplace_uu*fd.val_u - laplace_ub*fd.val_b + 
          mass_uu*g_rhs.val_u + mass_ub*g_rhs.val_b;
        fd.val_b = bvals;
      end Equation;
      
      annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80, 80; 80, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              fillColor=7, 
              rgbfillColor={255,255,255})), 
          Line(points=[-100, 80; -100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Line(points=[100, 80; 100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Text(
            extent=[60, -20; -60, 0], 
            style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1), 
            string="Poisson 2D"), 
          Line(points=[-70, 100; 70, 100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1)), 
          Line(points=[-70, -100; 70, -100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1))));
      annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80, 80; 80, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              fillColor=7, 
              rgbfillColor={255,255,255})), 
          Line(points=[-100, 80; -100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Line(points=[100, 80; 100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Text(
            extent=[60, -20; -60, 0], 
            style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1), 
            string="Poisson 2D"), 
          Line(points=[-70, 100; 70, 100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1)), 
          Line(points=[-70, -100; 70, -100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1))));
      
    end Diffusion2D;
    
    package DiffusionBnd2D "Poisson problem 2D" 
      import FEMSolver.*;
      
      //replaceable package Solver = InternalDiffusionSolver;
      //replaceable package Solver = RheolefSolver;
      function interior = DomainOperators.interior2D;
      
      replaceable package domainP = Domain;
      //  replaceable package initialField = ConstField;
      /* (redeclare function value = 
  valfunc); */
      //replaceable function valfunc = ConstField.value;
      
      model Equation "Poisson equation 2D" 
        parameter Real g0=1 "Constant value of field";
        parameter domainP.Data domain;
        parameter Integer nbp=20;
        parameter Real refine=0.7;
        //parameter initialField.Parameters inifp;
        
        // internal packages  
        package rhsFieldP = ConstConstField (redeclare package domainP = 
                domainP);
        parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
        
        package uFieldP = Field (redeclare package domainP = domainP);
        parameter uFieldP.Data uField(domain=domain);
        
        // discrete part
        package ddomainP = DiscreteDomain (redeclare package domainP = domainP);
        parameter ddomainP.Data ddomain(
          domain=domain, 
          nbp=nbp, 
          refine=refine);
        
        // Why doesn't these work?
        // parameter FormSize formsize=getFormSize(ddomain.mesh.filename, ddomain.mesh.nv);
        // parameter FormSize formsize=getFormSize("default_mesh2d.txt", 79);
        
        parameter Integer interiorSize=integer(sum(DomainOperators.interior2D(
            ddomain.mesh.nv, ddomain.mesh.x)));
        
        // Assuming boundary blocked, i.e. all dirichlet bc.
        parameter FormSize formsize=FormSize(interiorSize, ddomain.mesh.nv - 
            interiorSize);
        parameter Integer u_indices[formsize.nu]=getUnknownIndices(ddomain.mesh
            .filename, ddomain.mesh.nv, formsize.nu);
        parameter Integer b_indices[formsize.nb]=getBlockedIndices(ddomain.mesh
            .filename, ddomain.mesh.nv, formsize.nb);
        
        package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                rhsFieldP, redeclare package ddomainP = ddomainP);
        package interpolationP = Interpolation (redeclare package dfieldP = 
                rhsDFieldP);
        parameter rhsDFieldP.Data g_rhs(
          ddomain=ddomain, 
          field=rhsField, 
          formsize=formsize, 
          u_indices=u_indices, 
          b_indices=b_indices, 
          val_u=interpolationP.interpolate_indirect(ddomain, rhsField, formsize
              .nu, u_indices), 
          val_b=fill(5, formsize.nb));
        //val_b=interpolationP.interpolate_indirect(ddomain, rhsField, formsize.nb, 
        //   b_indices));
        
        package uDFieldP = DiscreteField (redeclare package ddomainP = ddomainP, 
              redeclare package fieldP = uFieldP);
        uDFieldP.Data fd(
          ddomain=ddomain, 
          field=uField, 
          formsize=formsize, 
          u_indices=u_indices, 
          b_indices=b_indices, 
          val_u(start={0 for i in 1:formsize.nu}), 
          val_b(start={0 for i in 1:formsize.nb}));
        
      protected 
        parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd.
            ddomain.mesh.ne};
        //    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv];
        //    parameter Real g[fd.ddomain.mesh.nv];
        parameter Real laplace_uu[formsize.nu, formsize.nu]=getForm_gradgrad_uu(
            fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize
            .nb);
        parameter Real laplace_ub[formsize.nu, formsize.nb]=getForm_gradgrad_ub(
            fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize
            .nb);
        
        parameter Real mass_uu[formsize.nu, formsize.nu]=getForm_mass_uu(fd.
            ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.nb);
        parameter Real mass_ub[formsize.nu, formsize.nb]=getForm_mass_ub(fd.
            ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.nb);
        
        //  initial equation 
        //    (Laplace,g) = getMatrix(fd.ddomain.mesh, fd.ddomain.mesh.nv, g_rhs.val, 
        //      bndcond);
      equation 
        //writeSquareMatrix("mass_uu.txt", formsize.nu, mass_uu);
        //writeMatrix("mass_ub.txt", formsize.nu, formsize.nb, mass_ub);
        //writeSquareMatrix("laplace_uu.txt", formsize.nu, laplace_uu);
        //writeMatrix("laplace_ub.txt", formsize.nu, formsize.nb, laplace_ub);
        //writeVector("g_u.txt", formsize.nu, g_rhs.val_u);
        //writeVector("g_b.txt", formsize.nb, g_rhs.val_b);
        mass_uu*der(fd.val_u) = -laplace_uu*fd.val_u - laplace_ub*fd.val_b + 
          mass_uu*g_rhs.val_u + mass_ub*g_rhs.val_b;
        fd.val_b = zeros(size(fd.val_b, 1));
        //fd.val = g;
      end Equation;
      
      annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80, 80; 80, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              fillColor=7, 
              rgbfillColor={255,255,255})), 
          Line(points=[-100, 80; -100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Line(points=[100, 80; 100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Text(
            extent=[60, -20; -60, 0], 
            style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1), 
            string="Poisson 2D"), 
          Line(points=[-70, 100; 70, 100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1)), 
          Line(points=[-70, -100; 70, -100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1))));
      annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80, 80; 80, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              fillColor=7, 
              rgbfillColor={255,255,255})), 
          Line(points=[-100, 80; -100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Line(points=[100, 80; 100, -80], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2)), 
          Text(
            extent=[60, -20; -60, 0], 
            style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1), 
            string="Poisson 2D"), 
          Line(points=[-70, 100; 70, 100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1)), 
          Line(points=[-70, -100; 70, -100], style(
              color=62, 
              rgbcolor={0,127,127}, 
              thickness=2, 
              fillColor=7, 
              rgbfillColor={255,255,255}, 
              fillPattern=1))));
      
    end DiffusionBnd2D;
  end Autonomous;
  
  package Discretize   end Discretize;
  
  package DiscreteField 
    replaceable package fieldP = Field;
    replaceable package ddomainP = DiscreteDomain;
    //replaceable package valfunc = ConstField.value;
    //replaceable package initialDField = DiscreteConstField;
    //replaceable package initialField = ConstField;
    
    //package initialDField = DiscreteConstField (redeclare package field = 
    //        initialField, redeclare package ddomain = ddomain);
    
    replaceable record Data 
      parameter ddomainP.Data ddomain;
      parameter fieldP.Data field;
      parameter FEMSolver.FormSize formsize;
      parameter Integer u_indices[formsize.nu];
      parameter Integer b_indices[formsize.nb];
      //parameter initialDField.Parameters inip(ddom=p.ddom, fld=p.fld);
      //parameter initialDField.Data inidata(p=inip);
      fieldP.FieldType val_u[formsize.nu](start=zeros(formsize.nu));
      fieldP.FieldType val_b[formsize.nb];
      
      // What should fieldSize be? Just unknowns?
      parameter Integer fieldSize_u=size(val_u, 1);
      parameter Integer fieldSize_b=size(val_b, 1);
    end Data;
    
  end DiscreteField;
  
  package DiscreteDomain 
    replaceable package domainP = Domain extends Domain;
    
    replaceable record Data 
      parameter Integer nbp;
      parameter domainP.Data domain;
      parameter Real refine=0.7;
      
      parameter BPoint boundary[nbp]=domainP.discretizeBoundary(nbp, domain.
          boundary);
      //parameter Point polygon[:]=DomainType.boundaryPoints(p.nbp, bd);
      //parameter Real bc[nbp, 3]=domainP.getBoundaryConditions(nbp, domain.
      //    boundary);
      parameter Mesh.Data mesh(
        n=size(boundary, 1), 
        polygon=boundary[:, 1:2], 
        bc=integer(boundary[:, 3]), 
        refine=refine);
      parameter Integer boundarySize=size(boundary, 1);
    end Data;
    
    function createData 
      input Integer nbp;
      input domainP.Data domain;
      input Real refine=0.7;
      output Data data(
        nbp=nbp, 
        domain=domain, 
        refine=refine);
    algorithm 
    end createData;
    
  end DiscreteDomain;
  
  package Mesh "2D spatial domain" 
    // import MeshGeneration.*;
    
    function generate = MeshGeneration.generate2D;
    function get_s = MeshGeneration.sizes2D;
    function get_v = MeshGeneration.vertices2D;
    function get_e = MeshGeneration.edges2D;
    function get_t = MeshGeneration.triangles2D;
    
    record Data 
      parameter Integer n;
      parameter Point polygon[n];
      parameter Integer bc[n]={1 for i in 1:n};
      parameter Real refine(
        min=0, 
        max=1) = 0.7 "0 < refine < 1, less is finer";
      parameter String filename="default_mesh2D.txt";
      // will be overwritten!
      
      // If Cygwin (BAMG) not installed, bypass generation of grid, just read existing files.
      parameter Integer status=generate(polygon, bc, filename, refine);
      
      //parameter Integer s[3] = get_s(mesh, status);
      // Necessary for dependency! Currently not supported by Dymola (BUG?)
      parameter Integer s[3]=get_s(filename);
      
      parameter Integer nv=s[1] "Number of vertices";
      parameter Integer ne=s[2] "Number of edges on boundary";
      parameter Integer nt=s[3] "Number of triangles";
      parameter Coordinate x[nv, 3]=get_v(filename, nv) 
        "Coordinates of grid-points (1:2) and inner/bd (3)";
      parameter Integer edge[ne, 3]=get_e(filename, ne) 
        "Edges by vertex-tuple (1:2) and index for boundary condition (3)";
      parameter Integer triangle[nt, 4]=get_t(filename, nt) 
        "Triangles by vertex-triple (1:3) and index for dependence of coefficients (4)";
    end Data;
    
    function createMesh 
      input Integer n;
      input Point polygon[n];
      output Data mesh(n=n, polygon=polygon);
    algorithm 
    end createMesh;
  end Mesh;
  
  package MeshGeneration "Grid generation for 1D and triangular 2D" 
    function generate1D "Generates 1D mesh" 
      
      input Real xPolygon[:];
      input Integer bc[size(xPolygon, 1)];
      input String outputfile;
      input Real refine=0.1;
      // 0 < refine < 1, controls refinement of triangles, less is finer.
      output Integer status;
    external "C" oneg_generate_mesh("onegrun.bat", outputfile, status, xPolygon, 
        size(xPolygon, 1), bc, size(bc, 1), refine)
        annotation (Include="#include <oneg_generate_mesh.c>");
      /*  
//for test:
algorithm 
  status := 0;
*/
    end generate1D;
    
    function sizes1D "Reads sizes mesh-data 1D" 
      
      input String mesh;
      input Integer status;
      output Integer s[3] "Sizes of mesh-data {vertices, bdpoints, intervals}";
    external "C" oneg_read_sizes(mesh, s, size(s, 1))
        annotation (Include="#include <oneg_read_sizes.c>");
      /*  
//for test:
algorithm 
  s :={11,2,10};
*/
    end sizes1D;
    
    function vertices1D "Reads vertex coordinates 1D" 
      
      input String mesh;
      input Integer n "Number of vertices";
      output Coordinate v[n, 2];
    external "C" oneD_read_vertices(mesh, v, size(v, 1), size(v, 2))
        annotation (Include="#include <oneg_read_vertices.c>");
      /* 
//for test:
algorithm 
  v := [0,1; 0.1,1; 0.2,1; 0.3,1; 0.4,1; 0.5,1; 0.6,1; 0.7,1; 0.8,1; 0.9,1; 1,1];
*/
    end vertices1D;
    
    function bdpoints1D "Reads sequence of boundary points 1D" 
      
      input String mesh;
      input Integer n "Number of boundary-points";
      output Integer b[n, 2];
    external "C" oneD_read_bdpoints(mesh, b, size(b, 1), size(b, 2))
        annotation (Include="#include <oneg_read_bdpoints.c>");
      /*  
//for test:
algorithm 
  b := [0,1;1,1];
*/
    end bdpoints1D;
    
    function intervals1D "Reads sequence of intervals 1D" 
      
      input String mesh;
      input Integer n "Number of intervals";
      output Integer i[n, 3];
    external "C" oneD_read_intervals(mesh, i, size(i, 1), size(i, 2))
        annotation (Include="#include <oneg_read_intervals.c>");
      /*  
//for test:
algorithm 
  i := [1,2,1; 2,3,1; 3,4,1; 4,5,1; 5,6,1; 6,7,1; 7,8,1; 8,9,1; 9,10,1; 10,11,1];
*/
    end intervals1D;
    
    function generate2D "Generates 2D triangular mesh" 
      annotation (Include="#include <bamg.h>", Library="bamg");
      input Real xPolygon[:, 2];
      input Integer bc[size(xPolygon, 1)];
      input String outputfile;
      input Real refine=0.5;
      // h in (0,1) controls the refinement of triangles, less is finer
      output Integer status;
    external "C" bamg_generate_mesh("bamgrun.bat", outputfile, status, xPolygon, 
        size(xPolygon, 1), size(xPolygon, 2), bc, size(bc, 1), refine);
      /*  
//for test:  
algorithm 
  status := 0;
*/
    end generate2D;
    
    function sizes2D "Reads sizes mesh-data 2D" 
      annotation (Include="#include <bamg.h>", Library="bamg");
      input String meshfile;
      output Integer s[3] "Sizes of mesh-data {vertices, edges, triangles}";
    external "C" bamg_read_sizes(meshfile, s, size(s, 1));
      /*  
//for test:
algorithm 
  s :={2,2,2};
*/
    end sizes2D;
    
    function vertices2D "Reads vertex coordinates 2D" 
      annotation (Include="#include <bamg.h>", Library="bamg");
      input String mesh;
      input Integer n "Number of vertices";
      output Real v[n, 3];
    external "C" bamg_read_vertices(mesh, v, size(v, 1), size(v, 2));
      /*  
//for test:
algorithm 
  v := [1,2,3;0.1,0.2,4];
*/
    end vertices2D;
    
    function edges2D "Reads sequence of edges on boundary 2D" 
      annotation (Include="#include <bamg.h>", Library="bamg");
      
      input String mesh;
      input Integer n "Number of edges";
      output Integer e[n, 3];
    external "C" bamg_read_edges(mesh, e, size(e, 1), size(e, 2));
      /*  
//for test:
algorithm 
  e := [1,2,3;4,5,6];
*/
    end edges2D;
    
    function triangles2D "Reads sequence of triangles 2D" 
      annotation (Include="#include <bamg.h>", Library="bamg");
      
      input String mesh;
      input Integer n "Number of triangles";
      output Integer t[n, 4];
    external "C" bamg_read_triangles(mesh, t, size(t, 1), size(t, 2));
      /*  
//for test:
algorithm 
  t := [1,2,3,4;5,6,7,8];
*/
    end triangles2D;
    
  end MeshGeneration;
  
  package DiscreteConstField 
    replaceable package fieldP = Field;
    
    replaceable package ddomainP = DiscreteDomain;
    
    //  package interpolation = Interpolation (redeclare package field = field);
    
    redeclare replaceable record Data 
      parameter ddomainP.Data ddomain;
      parameter fieldP.Data field;
      parameter FEMSolver.FormSize formsize;
      parameter Integer u_indices[formsize.nu];
      parameter Integer b_indices[formsize.nb];
      parameter fieldP.FieldType val_u[formsize.nu]=fill(5, formsize.nu);
      parameter fieldP.FieldType val_b[formsize.nb]=fill(5, formsize.nb);
      parameter Integer fieldSize_u=size(val_u, 1);
      parameter Integer fieldSize_b=size(val_b, 1);
    end Data;
    
  end DiscreteConstField;
  
  package Interpolation 
    
    replaceable package dfieldP = DiscreteField;
    
    function interpolate 
      //input Mesh.Data mesh;
      //input Integer fieldSize;
      input dfieldP.ddomainP.Data ddomain;
      input dfieldP.fieldP.Data field;
      input Integer fieldSize;
      output dfieldP.fieldP.FieldType val[fieldSize];
    protected 
      Point x;
    algorithm 
      for i in 1:size(val, 1) loop
        x := ddomain.mesh.x[i, 1:2];
        val[i] := dfieldP.fieldP.value(x, field);
      end for;
    end interpolate;
    
    function interpolate_indirect 
      //input Mesh.Data mesh;
      //input Integer fieldSize;
      input dfieldP.ddomainP.Data ddomain;
      input dfieldP.fieldP.Data field;
      input Integer vecSize;
      input Integer indices[vecSize];
      output dfieldP.fieldP.FieldType val[vecSize];
    protected 
      Point x;
    algorithm 
      for i in 1:size(val, 1) loop
        x := ddomain.mesh.x[indices[i], 1:2];
        val[i] := dfieldP.fieldP.value(x, field);
      end for;
    end interpolate_indirect;
    
  end Interpolation;
  
  package FEMSolver 
    
    record FormSize 
      parameter Integer nu;
      parameter Integer nb;
    end FormSize;
    
    record Form 
      parameter Integer nu;
      parameter Integer nb;
      parameter Real uu[nu, nu];
      parameter Real ub[nu, nb];
      parameter Real bu[nb, nu];
      parameter Real bb[nb, nb];
    end Form;
    
    function getFormSize 
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nbc;
      input BCType bc[nbc];
      output FormSize s;
    algorithm 
      (s.nu,s.nb) := getFormSize_internal(meshfilename, meshnv, nbc, bc);
    end getFormSize;
    
    function getForm_gradgrad 
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input FormSize s;
      input Integer nbc;
      input BCType bc[nbc];
      output Form form(nu=s.nu, nb=s.nb);
    protected 
      Real auu[s.nu, s.nu];
      Real aub[s.nu, s.nb];
      Real abu[s.nb, s.nu];
      Real abb[s.nb, s.nb];
    algorithm 
      (auu,aub,abu,abb) := getForm_gradgrad_internal(meshfilename, meshnv, s, 
        nbc, bc);
      form.uu := auu;
      form.ub := aub;
      form.bu := abu;
      form.bb := abb;
      form.nu := s.nu;
      form.nb := s.nb;
    end getForm_gradgrad;
    
    function getUnknownIndices 
      annotation (Include="#include <poisson_rheolef.h>", Library=
            "poisson_rheolef");
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nbr_unknowns;
      input Integer nbc;
      input BCType bc[nbc];
      output Integer indices[nbr_unknowns];
    external "C" get_rheolef_unknown_indices(meshfilename, meshnv, nbr_unknowns, 
        indices, nbc, size(bc, 2), bc);
    end getUnknownIndices;
    
    function getForm_gradgrad_internal 
      annotation (Include="#include <poisson_rheolef.h>", Library=
            "poisson_rheolef");
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nu;
      input Integer nb;
      input Integer nbc;
      input BCType bc[nbc];
      output Real auu[nu, nu];
      output Real aub[nu, nb];
      output Real abu[nb, nu];
      output Real abb[nb, nb];
    external "C" get_rheolef_form_grad_grad(meshfilename, meshnv, nu, nb, auu, 
        aub, abu, abb, nbc, size(bc, 2), bc);
    end getForm_gradgrad_internal;
    /* For debugging */
    
    function writeMatrix 
      annotation (Include="#include <read_matrix.h>", Library="poisson_rheolef");
      input String filename="foomatrix.txt";
      input Integer n;
      input Integer m;
      input Real M[n, m];
    external "C" write_matrix(filename, n, m, M);
    end writeMatrix;
    
    function writeVector 
      annotation (Include="#include <read_matrix.h>", Library="poisson_rheolef");
      input String filename="foovector.txt";
      input Integer nv;
      input Real v[nv];
    external "C" write_vector(filename, nv, v);
    end writeVector;
    
    function getForm_gradgrad_uu 
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nu;
      input Integer nb;
      input Integer nbc;
      input BCType bc[nbc];
      output Real uu[nu, nu];
    protected 
      Real auu[nu, nu];
      Real aub[nu, nb];
      Real abu[nb, nu];
      Real abb[nb, nb];
    algorithm 
      (auu,aub,abu,abb) := getForm_gradgrad_internal(meshfilename, meshnv, nu, 
        nb, nbc, bc);
      uu := auu;
    end getForm_gradgrad_uu;
    
    function getFormSize_internal 
      annotation (Include="#include <poisson_rheolef.h>", Library=
            "poisson_rheolef");
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nbc;
      input BCType bc[nbc];
      output Integer nu;
      output Integer nb;
    external "C" get_rheolef_form_size(meshfilename, meshnv, nu, nb, nbc, size(
        bc, 2), bc);
    end getFormSize_internal;
    
    function getBlockedIndices 
      annotation (Include="#include <poisson_rheolef.h>", Library=
            "poisson_rheolef");
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nbr_blockeds;
      input Integer nbc;
      input BCType bc[nbc];
      output Integer indices[nbr_blockeds];
    external "C" get_rheolef_blocked_indices(meshfilename, meshnv, nbr_blockeds, 
        indices, nbc, size(bc, 2), bc);
    end getBlockedIndices;
    
    function getForm_mass_internal 
      annotation (Include="#include <poisson_rheolef.h>", Library=
            "poisson_rheolef");
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nu;
      input Integer nb;
      input Integer nbc;
      input BCType bc[nbc];
      output Real auu[nu, nu];
      output Real aub[nu, nb];
      output Real abu[nb, nu];
      output Real abb[nb, nb];
    external "C" get_rheolef_form_mass(meshfilename, meshnv, nu, nb, auu, aub, 
        abu, abb, nbc, size(bc, 2), bc);
    end getForm_mass_internal;
    
    function getForm_mass 
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input FormSize s;
      input Integer nbc;
      input BCType bc[nbc];
      output Form form(nu=s.nu, nb=s.nb);
    protected 
      Real auu[s.nu, s.nu];
      Real aub[s.nu, s.nb];
      Real abu[s.nb, s.nu];
      Real abb[s.nb, s.nb];
    algorithm 
      (auu,aub,abu,abb) := getForm_mass_internal(meshfilename, meshnv, s, nbc, 
        bc);
      form.uu := auu;
      form.ub := aub;
      form.bu := abu;
      form.bb := abb;
      form.nu := s.nu;
      form.nb := s.nb;
    end getForm_mass;
    
    function getForm_mass_uu 
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nu;
      input Integer nb;
      input Integer nbc;
      input BCType bc[nbc];
      output Real uu[nu, nu];
    protected 
      Real auu[nu, nu];
      Real aub[nu, nb];
      Real abu[nb, nu];
      Real abb[nb, nb];
    algorithm 
      (auu,aub,abu,abb) := getForm_mass_internal(meshfilename, meshnv, nu, nb, 
        nbc, bc);
      uu := auu;
    end getForm_mass_uu;
    
    function getForm_mass_ub 
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nu;
      input Integer nb;
      input Integer nbc;
      input BCType bc[nbc];
      output Real ub[nu, nb];
    protected 
      Real auu[nu, nu];
      Real aub[nu, nb];
      Real abu[nb, nu];
      Real abb[nb, nb];
    algorithm 
      (auu,aub,abu,abb) := getForm_mass_internal(meshfilename, meshnv, nu, nb, 
        nbc, bc);
      ub := aub;
    end getForm_mass_ub;
    
    function getForm_gradgrad_ub 
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nu;
      input Integer nb;
      input Integer nbc;
      input BCType bc[nbc];
      output Real ub[nu, nb];
    protected 
      Real auu[nu, nu];
      Real aub[nu, nb];
      Real abu[nb, nu];
      Real abb[nb, nb];
    algorithm 
      (auu,aub,abu,abb) := getForm_gradgrad_internal(meshfilename, meshnv, nu, 
        nb, nbc, bc);
      ub := aub;
    end getForm_gradgrad_ub;
    
    function writeSquareMatrix 
      annotation (Include="#include <read_matrix.h>", Library="poisson_rheolef");
      input String filename="foomatrix.txt";
      input Integer nv;
      input Real M[nv, nv];
    external "C" write_square_matrix(filename, nv, M);
    end writeSquareMatrix;
    
    function getBlockedValues 
      annotation (Include="#include <poisson_rheolef.h>", Library=
            "poisson_rheolef");
      //input Mesh.Data mesh;
      input String meshfilename;
      input Integer meshnv;
      input Integer nbr_blockeds;
      input Integer nbc;
      input BCType bc[nbc];
      output Real values[nbr_blockeds];
    external "C" get_rheolef_blocked_values(meshfilename, meshnv, nbr_blockeds, 
        values, nbc, size(bc, 2), bc);
    end getBlockedValues;

    function getForm 
      input String formname;
      input String meshfilename;
      input Integer meshnv;
      input FormSize s;
      input Integer nbc;
      input BCType bc[nbc];
      output Form form(nu=s.nu, nb=s.nb);
    protected 
      Real auu[s.nu, s.nu];
      Real aub[s.nu, s.nb];
      Real abu[s.nb, s.nu];
      Real abb[s.nb, s.nb];
    algorithm 
      (auu,aub,abu,abb) := getForm_internal(formname, meshfilename, meshnv, s, 
        nbc, bc);
      form.uu := auu;
      form.ub := aub;
      form.bu := abu;
      form.bb := abb;
      form.nu := s.nu;
      form.nb := s.nb;
    end getForm;

    function getForm_internal 
      annotation (Include="#include <poisson_rheolef.h>", Library=
            "poisson_rheolef");
      //input Mesh.Data mesh;
      input String formname;
      input String meshfilename;
      input Integer meshnv;
      input Integer nu;
      input Integer nb;
      input Integer nbc;
      input BCType bc[nbc];
      output Real auu[nu, nu];
      output Real aub[nu, nb];
      output Real abu[nb, nu];
      output Real abb[nb, nb];
    external "C" get_rheolef_form(formname, meshfilename, meshnv, nu, nb, auu, 
        aub, abu, abb, nbc, size(bc, 2), bc);
    end getForm_internal;
  end FEMSolver;
  
  package DomainOperators 
    "Domain operators return the values of the field on the interior of the domain" 
    
    function interior1D "Field in the interior of 2D domain" 
      input Integer nVertices;
      input Real vertices[nVertices, 2];
      output Real interior[nVertices];
      
    algorithm 
      interior := zeros(nVertices);
      for i in 1:nVertices loop
        interior[i] := if vertices[i, 2] > 0 then 0 else 1;
      end for;
      annotation (Documentation(info="<HTML>
<pre>
Returns a vector with value 0 for boundary-vertices and 1 for other vertices .
</pre>
</HTML>
"));
    end interior1D;
    
    function interior2D "Field in the interior of 2D domain" 
      input Integer nVertices;
      input Real vertices[nVertices, 3];
      output Real interior[nVertices];
      
    algorithm 
      interior := zeros(nVertices);
      for i in 1:nVertices loop
        interior[i] := if vertices[i, 3] > 0 then 0 else 1;
      end for;
      annotation (Documentation(info="<HTML>
<pre>
Returns a vector with value 0 for boundary-vertices and 1 for other vertices .
</pre>
</HTML>
"));
    end interior2D;
    annotation (Documentation(info=""), Icon);
    
  end DomainOperators;
  
end FEMForms;
