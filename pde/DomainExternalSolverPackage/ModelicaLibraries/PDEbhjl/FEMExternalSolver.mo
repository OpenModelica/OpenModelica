package FEMExternalSolver 
  package Autonomous 
    package Poisson2D "Poisson problem 2D" 
      
      //replaceable package Solver = InternalSolver;
      replaceable package Solver = RheolefSolver;
      
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
        
        package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                rhsFieldP, redeclare package ddomainP = ddomainP);
        package interpolationP = Interpolation (redeclare package dfieldP = 
                rhsDFieldP);
        parameter rhsDFieldP.Data g_rhs(
          ddomain=ddomain, 
          field=rhsField, 
          val=interpolationP.interpolate(ddomain, rhsField, ddomain.mesh.nv));
        
        package uDFieldP = DiscreteField (redeclare package ddomainP = ddomainP, 
              redeclare package fieldP = uFieldP);
        uDFieldP.Data fd(
          ddomain=ddomain, 
          field=uField, 
          val(start={1 for i in 1:ddomain.mesh.nv}));
        
      protected 
        parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd.
            ddomain.mesh.ne};
        //    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv];
        //    parameter Real g[fd.ddomain.mesh.nv];
        parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=
            Solver.getMatrix_Laplace(fd.ddomain.mesh, fd.ddomain.mesh.nv, fd.
            ddomain.mesh.ne, g_rhs.val, bndcond);
        parameter Real g[fd.ddomain.mesh.nv]=Solver.getMatrix_g(fd.ddomain.mesh, 
            fd.ddomain.mesh.nv, fd.ddomain.mesh.ne, g_rhs.val, bndcond);
        /*   
    parameter Real Lg[:, :]=assemble(fd.ddomain.mesh.nt, fd.ddomain.mesh.nv, fd
        .ddomain.mesh.triangle, fd.ddomain.mesh.x, g_rhs.val);
    parameter Real LgBd[:, :]=assembleBd(fd.ddomain.mesh.ne, fd.ddomain.mesh.nv, 
        fd.ddomain.mesh.edge, fd.ddomain.mesh.x, Lg, bndcond);
    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=LgBd[1:fd.
        ddomain.mesh.nv, 1:fd.ddomain.mesh.nv];
    parameter Real g[fd.ddomain.mesh.nv]=LgBd[1:fd.ddomain.mesh.nv, fd.ddomain.
        mesh.nv + 1];
  */
        //  initial equation 
        //    (Laplace,g) = getMatrix(fd.ddomain.mesh, fd.ddomain.mesh.nv, g_rhs.val, 
        //      bndcond);
      equation 
        -Laplace*fd.val = g;
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
      
    end Poisson2D;
    
    package Diffusion2D "Poisson problem 2D" 
      
      replaceable package Solver = InternalDiffusionSolver;
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
        
        package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                rhsFieldP, redeclare package ddomainP = ddomainP);
        package interpolationP = Interpolation (redeclare package dfieldP = 
                rhsDFieldP);
        parameter rhsDFieldP.Data g_rhs(
          ddomain=ddomain, 
          field=rhsField, 
          val=interpolationP.interpolate(ddomain, rhsField, ddomain.mesh.nv));
        
        package uDFieldP = DiscreteField (redeclare package ddomainP = ddomainP, 
              redeclare package fieldP = uFieldP);
        uDFieldP.Data fd(
          ddomain=ddomain, 
          field=uField, 
          val(start={0 for i in 1:ddomain.mesh.nv}));
        
      protected 
        parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd.
            ddomain.mesh.ne};
        //    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv];
        //    parameter Real g[fd.ddomain.mesh.nv];
        parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=
            Solver.getMatrix_Laplace(fd.ddomain.mesh, fd.ddomain.mesh.nv, fd.
            ddomain.mesh.ne, g_rhs.val, bndcond);
        parameter Real M[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=
            Solver.getMatrix_Mass(fd.ddomain.mesh, fd.ddomain.mesh.nv, fd.
            ddomain.mesh.ne, g_rhs.val, bndcond);
        parameter Real g[fd.ddomain.mesh.nv]=Solver.getMatrix_g(fd.ddomain.mesh, 
            fd.ddomain.mesh.nv, fd.ddomain.mesh.ne, g_rhs.val, bndcond);
        //  initial equation 
        //    (Laplace,g) = getMatrix(fd.ddomain.mesh, fd.ddomain.mesh.nv, g_rhs.val, 
        //      bndcond);
      equation 
        diagonal(interior(fd.ddomain.mesh.nv, fd.ddomain.mesh.x))*M*der(fd.val)
          = Laplace*fd.val + g;
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
      
    end Diffusion2D;
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
      //parameter initialDField.Parameters inip(ddom=p.ddom, fld=p.fld);
      //parameter initialDField.Data inidata(p=inip);
      fieldP.FieldType val[ddomain.mesh.nv](start=zeros(ddomain.mesh.nv));
      //(start=inidata.val);
      parameter Integer fieldSize=size(val, 1);
    end Data;
    
  end DiscreteField;
  
  package DiscreteDomain 
    replaceable package domainP = Domain extends Domain;
    
    replaceable record Data 
      parameter Integer nbp;
      parameter domainP.Data domain;
      parameter Real refine=0.7;
      
      parameter Point polygon[:]=domainP.discretizeBoundary(nbp, domain.
          boundary);
      //parameter Point polygon[:]=DomainType.boundaryPoints(p.nbp, bd);
      parameter Mesh.Data mesh(
        n=size(polygon, 1), 
        polygon=polygon, 
        refine=refine);
      parameter Integer boundarySize=size(polygon, 1);
    end Data;
    
  end DiscreteDomain;
  
  package Mesh "2D spatial domain" 
    import MeshGeneration.*;
    
    function generate = generate2D;
    function get_s = sizes2D;
    function get_v = vertices2D;
    function get_e = edges2D;
    function get_t = triangles2D;
    
    record Data 
      parameter Integer n;
      parameter Point polygon[n];
      parameter Integer bc[:]={1 for i in 1:n};
      parameter Real refine(
        min=0, 
        max=1) = 0.7 "0 < refine < 1, less is finer";
      parameter String filename="default_mesh2D.txt";
      // will be overwritten!
      
      // If Cygwin (BAMG) not installed, bypass generation of grid, just read existing files.
      parameter Integer status=generate(polygon, bc, filename, refine);
      
      //parameter Integer s[3] = get_s(mesh, status);
      // Necessary for dependency! Currently not supported by Dymola (BUG?)
      parameter Integer s[3]=get_s(filename, 1);
      
      parameter Integer nv=s[1] "Number of vertices";
      parameter Integer ne=s[2] "Number of edges on boundary";
      parameter Integer nt=s[3] "Number of triangles";
      parameter Coordinate x[:, 3]=get_v(filename, nv) 
        "Coordinates of grid-points (1:2) and inner/bd (3)";
      parameter Integer edge[:, 3]=get_e(filename, ne) 
        "Edges by vertex-tuple (1:2) and index for boundary condition (3)";
      parameter Integer triangle[:, 4]=get_t(filename, nt) 
        "Triangles by vertex-triple (1:3) and index for dependence of coefficients (4)";
    end Data;
    
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
      
      input Real xPolygon[:, 2];
      input Integer bc[size(xPolygon, 1)];
      input String outputfile;
      input Real refine=0.5;
      // h in (0,1) controls the refinement of triangles, less is finer
      output Integer status;
    external "C" bamg_generate_mesh("bamgrun.bat", outputfile, status, xPolygon, 
        size(xPolygon, 1), size(xPolygon, 2), bc, size(bc, 1), refine)
        annotation (Include="#include <bamg_generate_mesh.c>");
      /*  
//for test:  
algorithm 
  status := 0;
*/
    end generate2D;
    
    function sizes2D "Reads sizes mesh-data 2D" 
      
      input String mesh;
      input Integer status;
      output Integer s[3] "Sizes of mesh-data {vertices, edges, triangles}";
    external "C" bamg_read_sizes(mesh, s, size(s, 1))
        annotation (Include="#include <bamg_read_sizes.c>");
      /*  
//for test:
algorithm 
  s :={2,2,2};
*/
    end sizes2D;
    
    function vertices2D "Reads vertex coordinates 2D" 
      
      input String mesh;
      input Integer n "Number of vertices";
      output Real v[n, 3];
    external "C" bamg_read_vertices(mesh, v, size(v, 1), size(v, 2))
        annotation (Include="#include <bamg_read_vertices.c>");
      /*  
//for test:
algorithm 
  v := [1,2,3;0.1,0.2,4];
*/
    end vertices2D;
    
    function edges2D "Reads sequence of edges on boundary 2D" 
      
      input String mesh;
      input Integer n "Number of edges";
      output Integer e[n, 3];
    external "C" bamg_read_edges(mesh, e, size(e, 1), size(e, 2))
        annotation (Include="#include <bamg_read_edges.c>");
      /*  
//for test:
algorithm 
  e := [1,2,3;4,5,6];
*/
    end edges2D;
    
    function triangles2D "Reads sequence of triangles 2D" 
      
      input String mesh;
      input Integer n "Number of triangles";
      output Integer t[n, 4];
    external "C" bamg_read_triangles(mesh, t, size(t, 1), size(t, 2))
        annotation (Include="#include <bamg_read_triangles.c>");
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
      parameter fieldP.FieldType val[ddomain.mesh.nv];
      parameter Integer fieldSize=size(val, 1);
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
    
  end Interpolation;
  
  package FEMSolver 
    
    replaceable partial function getMatrix_Laplace 
      input Mesh.Data mesh;
      input Integer nv;
      input Integer ne;
      input Real g_rhs_val[nv];
      input Integer bndcond[ne, 2];
      output Real Laplace[nv, nv];
    end getMatrix_Laplace;
    
    replaceable partial function getMatrix_Mass 
      input Mesh.Data mesh;
      input Integer nv;
      input Integer ne;
      input Real g_rhs_val[nv];
      input Integer bndcond[ne, 2];
      output Real Mass[nv, nv];
    end getMatrix_Mass;
    
    replaceable partial function getMatrix_g 
      input Mesh.Data mesh;
      input Integer nv;
      input Integer ne;
      input Real g_rhs_val[nv];
      input Integer bndcond[ne, 2];
      output Real g[nv];
    end getMatrix_g;
    
    /* For debugging */
    
    replaceable function writeMatrix 
      input String filename="foomatrix.txt";
      input Integer nv;
      input Real M[nv, nv];
    end writeMatrix;
    
    replaceable function writeVector 
      input String filename="foovector.txt";
      input Integer nv;
      input Real v[nv];
    end writeVector;
    
  end FEMSolver;
  
  package RheolefSolver 
    extends FEMSolver;
    
    redeclare function extends getMatrix_Laplace 
    algorithm 
      Laplace := get_rheolef_poisson_laplace(mesh.filename, nv);
    end getMatrix_Laplace;
    
    redeclare function extends getMatrix_Mass 
    algorithm 
      Mass := get_rheolef_poisson_mass(mesh.filename, nv);
    end getMatrix_Mass;
    
    redeclare function extends getMatrix_g 
    algorithm 
      g := get_rheolef_poisson_g(mesh.filename, nv);
    end getMatrix_g;
    
    redeclare function extends writeMatrix 
      annotation (Include="#include <read_matrix.h>", Library="rheolef");
    external "C" write_square_matrix(filename, nv, M);
    end writeMatrix;
    
    redeclare function extends writeVector 
      annotation (Include="#include <read_matrix.h>", Library="rheolef");
    external "C" write_vector(filename, nv, v);
    end writeVector;
    
    /* Package specific internal functions */
    
    function get_rheolef_poisson_laplace 
      annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
      input String meshData;
      input Integer nv;
      output Real laplace[nv, nv];
    external "C" get_rheolef_poisson_laplace(meshData, nv, laplace);
      
    end get_rheolef_poisson_laplace;
    
    function get_rheolef_poisson_mass 
      annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
      input String meshData;
      input Integer nv;
      output Real mass[nv, nv];
    external "C" get_rheolef_poisson_mass(meshData, nv, mass);
    end get_rheolef_poisson_mass;
    
    function get_rheolef_poisson_g 
      annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
      input String meshData;
      input Integer nv;
      output Real g[nv];
    external "C" get_rheolef_poisson_g(meshData, nv, g);
      
    end get_rheolef_poisson_g;
    
  end RheolefSolver;
  
  package InternalSolver 
    extends FEMSolver;
    
    redeclare function extends getMatrix_Laplace 
    protected 
      parameter Real Lg[mesh.nv, mesh.nv + 1]=assemble(mesh.nt, mesh.nv, mesh.
          triangle, mesh.x, g_rhs_val);
      parameter Real LgBd[mesh.nv, mesh.nv + 1]=assembleBd(mesh.ne, mesh.nv, 
          mesh.edge, mesh.x, Lg, bndcond);
    algorithm 
      Laplace := LgBd[1:mesh.nv, 1:mesh.nv];
      // For debugging
      // FEMExternal.PoissonSolver.writeMatrix_Laplace(nv,Laplace);
    end getMatrix_Laplace;
    
    redeclare function extends getMatrix_g 
    protected 
      parameter Real Lg[mesh.nv, mesh.nv + 1]=assemble(mesh.nt, mesh.nv, mesh.
          triangle, mesh.x, g_rhs_val);
      parameter Real LgBd[mesh.nv, mesh.nv + 1]=assembleBd(mesh.ne, mesh.nv, 
          mesh.edge, mesh.x, Lg, bndcond);
    algorithm 
      g := LgBd[1:mesh.nv, mesh.nv + 1];
      // For debugging    
      // FEMExternal.PoissonSolver.writeMatrix_g(nv,g);
    end getMatrix_g;
    
    /* Internal functions */
    
    function assemble "Assembles stiffness and mass matrix" 
      input Integer nTriangles;
      input Integer nVertices;
      input Integer triangles[nTriangles, 4];
      input Real vertices[nVertices, 3];
      input Real g_val[:];
      output Real Ab[nVertices, nVertices + 1];
    protected 
      Integer Tk[3];
      Real Ak[3, 3];
      Real Lk[3];
      
      Integer i;
      Integer j;
    algorithm 
      Ab := zeros(nVertices, nVertices + 1);
      
      for k in 1:nTriangles loop
        Tk := triangles[k, 1:3];
        (Ak,Lk) := element(vertices[Tk, 1], vertices[Tk, 2], g_val[Tk]);
        
        for local_1 in 1:3 loop
          i := Tk[local_1];
          for local_2 in 1:3 loop
            j := Tk[local_2];
            Ab[i, j] := Ab[i, j] - Ak[local_1, local_2];
          end for;
          Ab[i, nVertices + 1] := Ab[i, nVertices + 1] + Lk[local_1];
          
        end for;
        
      end for;
      
      annotation (Documentation(info="<HTML>
<pre>
Assembles the stiffness and mass matrix according to the differential equation.
The boundary conditions are treated separately. 
</pre>
</HTML>"));
    end assemble;
    
    function assembleBd "Includes boundary conditions into stiffnes matrix" 
      
      input Integer nEdges;
      input Integer nVertices;
      input Integer edges[nEdges, 3];
      input Real vertices[nVertices, 3];
      input Real Ab[nVertices, nVertices + 1];
      input Integer type_bc[:, :];
      output Real AbBd[nVertices, nVertices + 1];
    protected 
      Real v[2, 3];
      
    algorithm 
      AbBd := Ab;
      
      for i in 1:nEdges loop
        
        if edges[i, 3] > 0 then
          v := vertices[edges[i, 1:2], :];
          //if type_bc[integer(v[1,3]),1] == 0 or type_bc[integer(v[2,3]),1] == 0 then
          
          if type_bc[integer(edges[i, 3]), 1] == 0 then
            
            for j in 1:nVertices loop
              AbBd[edges[i, 1], j] := 0;
              AbBd[edges[i, 2], j] := 0;
              
            end for;
            AbBd[edges[i, 1], edges[i, 1]] := 1;
            AbBd[edges[i, 2], edges[i, 2]] := 1;
            // Put inhomogenous Dirichlet conditions here!!
            AbBd[edges[i, 1], nVertices + 1] := 0;
            AbBd[edges[i, 2], nVertices + 1] := 0;
            
          else
            // Put inhomogenous Neumann conditions here!!
            AbBd[edges[i, 1], nVertices + 1] := 0;
            AbBd[edges[i, 2], nVertices + 1] := 0;
            
          end if;
          
        end if;
        
      end for;
      
      annotation (Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
    end assembleBd;
    
    function element "Stiffness contributions per triangle" 
      input Real Px[3];
      input Real Py[3];
      input Real g[3];
      output Real Ak[3, 3];
      output Real Lk[3];
    protected 
      Real md;
      Real mk;
      Real detk;
      Real F;
      Integer l;
      Integer j;
      Integer k;
    algorithm 
      detk := abs((Px[2] - Px[1])*(Py[3] - Py[1]) - (Px[3] - Px[1])*(Py[2] - Py[
        1]));
      F := detk/2;
      
      for i in 1:3 loop
        
        for j in i + 1:3 loop
          l := if i + j == 3 then 3 else if i + j == 4 then 2 else 1;
          Ak[i, j] := 1/2/detk*((Px[i] - Px[l])*(Px[l] - Px[j]) + (Py[i] - Py[l])
            *(Py[l] - Py[j]));
          Ak[j, i] := Ak[i, j];
          
        end for;
        
      end for;
      
      for i in 1:3 loop
        j := if i == 1 then 2 else if i == 2 then 3 else 1;
        k := if i == 1 then 3 else if i == 2 then 1 else 2;
        Ak[i, i] := 1/2/detk*((Px[j] - Px[k])^2 + (Py[j] - Py[k])^2);
        
      end for;
      md := 1/12*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
         - Px[1]));
      mk := 1/24*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
         - Px[1]));
      Lk := {md*g[1] + mk*g[2] + mk*g[3],mk*g[1] + md*g[2] + mk*g[3],mk*g[1] + 
        mk*g[2] + md*g[3]};
      annotation (Documentation(info=""));
    end element;
  end InternalSolver;
  
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
  
  package InternalDiffusionSolver 
    extends FEMSolver;
    
    redeclare function extends getMatrix_Laplace 
    protected 
      parameter Real AMb[mesh.nv, 2*mesh.nv + 1]=assemble(mesh.nt, mesh.nv, 
          mesh.triangle, mesh.x, g_rhs_val);
      parameter Real AMbBd[mesh.nv, 2*mesh.nv + 1]=assembleBd(mesh.ne, mesh.nv, 
          mesh.edge, mesh.x, AMb, bndcond);
    algorithm 
      Laplace := AMbBd[1:mesh.nv, 1:mesh.nv];
      // For debugging
      RheolefSolver.writeMatrix("intsolver_laplace2.txt", nv, diagonal(
        DomainOperators.interior2D(nv, mesh.x)));
      RheolefSolver.writeMatrix("intsolver_laplace.txt", nv, Laplace);
    end getMatrix_Laplace;
    
    redeclare function extends getMatrix_Mass 
    protected 
      parameter Real AMb[mesh.nv, 2*mesh.nv + 1]=assemble(mesh.nt, mesh.nv, 
          mesh.triangle, mesh.x, g_rhs_val);
      parameter Real AMbBd[mesh.nv, 2*mesh.nv + 1]=assembleBd(mesh.ne, mesh.nv, 
          mesh.edge, mesh.x, AMb, bndcond);
    algorithm 
      Mass := AMbBd[1:mesh.nv, mesh.nv + 1:2*mesh.nv];
      // For debugging
      RheolefSolver.writeMatrix("intsolver_mass.txt", nv, Mass);
    end getMatrix_Mass;
    
    redeclare function extends getMatrix_g 
    protected 
      parameter Real AMb[mesh.nv, 2*mesh.nv + 1]=assemble(mesh.nt, mesh.nv, 
          mesh.triangle, mesh.x, g_rhs_val);
      parameter Real AMbBd[mesh.nv, 2*mesh.nv + 1]=assembleBd(mesh.ne, mesh.nv, 
          mesh.edge, mesh.x, AMb, bndcond);
    algorithm 
      g := AMbBd[1:mesh.nv, 2*mesh.nv + 1];
      // For debugging    
      RheolefSolver.writeVector("intsolver_g.txt", nv, g);
    end getMatrix_g;
    
    /* Internal functions */
    
    function assemble "Assembles stiffness and mass matrix" 
      input Integer nTriangles;
      input Integer nVertices;
      input Integer triangles[nTriangles, 4];
      input Real vertices[nVertices, 3];
      input Real g_val[:];
      output Real AMb[nVertices, 2*nVertices + 1];
    protected 
      Integer Tk[3];
      Real Ak[3, 3];
      Real Mk[3, 3];
      Real Lk[3];
      
      Integer i;
      Integer j;
    algorithm 
      AMb := zeros(nVertices, 2*nVertices + 1);
      
      for k in 1:nTriangles loop
        Tk := triangles[k, 1:3];
        (Ak,Mk,Lk) := element(vertices[Tk, 1], vertices[Tk, 2], g_val[Tk]);
        
        for local_1 in 1:3 loop
          i := Tk[local_1];
          
          for local_2 in 1:3 loop
            j := Tk[local_2];
            AMb[i, j] := AMb[i, j] - Ak[local_1, local_2];
            AMb[i, nVertices + j] := AMb[i, nVertices + j] + Mk[local_1, 
              local_2];
            
          end for;
          AMb[i, 2*nVertices + 1] := AMb[i, 2*nVertices + 1] + Lk[local_1];
          
        end for;
        
      end for;
      
      annotation (Documentation(info="<HTML>
<pre>
Assembles the stiffness and mass matrix according to the differential equation.
The boundary conditions are treated separately. 
</pre>
</HTML>"));
    end assemble;
    
    function assembleBd "Includes boundary conditions into stiffnes matrix" 
      input Integer nEdges;
      input Integer nVertices;
      input Integer edges[nEdges, 3];
      input Real vertices[nVertices, 3];
      input Real AMb[nVertices, 2*nVertices + 1];
      input Integer type_bc[:, :];
      output Real AMbBd[nVertices, 2*nVertices + 1];
    protected 
      Real v[2, 3];
      
    algorithm 
      AMbBd := AMb;
      
      for i in 1:nEdges loop
        
        if edges[i, 3] > 0 then
          v := vertices[edges[i, 1:2], :];
          //if type_bc[integer(v[1,3]),1] == 0 or type_bc[integer(v[2,3]),1] == 0 then
          
          if type_bc[integer(edges[i, 3]), 1] == 0 then
            
            for j in 1:nVertices loop
              AMbBd[edges[i, 1], j] := 0;
              AMbBd[edges[i, 2], j] := 0;
              
            end for;
            AMbBd[edges[i, 1], edges[i, 1]] := 1;
            AMbBd[edges[i, 2], edges[i, 2]] := 1;
            // Put inhomogenous Dirichlet conditions here!!
            AMbBd[edges[i, 1], 2*nVertices + 1] := 0;
            AMbBd[edges[i, 2], 2*nVertices + 1] := 0;
            
          else
            // Put inhomogenous Neumann conditions here!!
            AMbBd[edges[i, 1], 2*nVertices + 1] := 0;
            AMbBd[edges[i, 2], 2*nVertices + 1] := 0;
            
          end if;
          
        end if;
        
      end for;
      
      annotation (Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
    end assembleBd;
    
    function element "Stiffness contributions per triangle" 
      input Real Px[3];
      input Real Py[3];
      input Real g[3];
      output Real Ak[3, 3];
      output Real Mk[3, 3];
      output Real Lk[3];
    protected 
      Real md;
      Real mk;
      Real detk;
      Real F;
      Integer l;
      Integer j;
      Integer k;
    algorithm 
      detk := abs((Px[2] - Px[1])*(Py[3] - Py[1]) - (Px[3] - Px[1])*(Py[2] - Py[
        1]));
      F := detk/2;
      
      for i in 1:3 loop
        
        for j in i + 1:3 loop
          l := if i + j == 3 then 3 else if i + j == 4 then 2 else 1;
          Ak[i, j] := 1/2/detk*((Px[i] - Px[l])*(Px[l] - Px[j]) + (Py[i] - Py[l])
            *(Py[l] - Py[j]));
          Ak[j, i] := Ak[i, j];
          
        end for;
        
      end for;
      
      for i in 1:3 loop
        j := if i == 1 then 2 else if i == 2 then 3 else 1;
        k := if i == 1 then 3 else if i == 2 then 1 else 2;
        Ak[i, i] := 1/2/detk*((Px[j] - Px[k])^2 + (Py[j] - Py[k])^2);
        
      end for;
      md := 1/12*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
         - Px[1]));
      mk := 1/24*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
         - Px[1]));
      Mk := [md, mk, mk; mk, md, mk; mk, mk, md];
      Lk := Mk*{g[1],g[2],g[3]};
    end element;
  end InternalDiffusionSolver;
end FEMExternalSolver;
