package FEMExternalMesh 
  package Autonomous 
    package Poisson2D "Poisson problem 2D" 
      import PoissonSolver.*;
      
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
            getMatrix_Laplace(fd.ddomain.mesh, fd.ddomain.mesh.nv, fd.ddomain.
            mesh.ne, g_rhs.val, bndcond);
        parameter Real g[fd.ddomain.mesh.nv]=getMatrix_g(fd.ddomain.mesh, fd.
            ddomain.mesh.nv, fd.ddomain.mesh.ne, g_rhs.val, bndcond);
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
      fieldP.FieldType val[ddomain.mesh.nv];
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
      
      parameter Point polygon[nbp]=domainP.discretizeBoundary(nbp, domain.
          boundary);
      //zeros(nbp, 2);
      //parameter Point polygon[:]=DomainType.boundaryPoints(p.nbp, bd);
      parameter Mesh.Data mesh(
        n=size(polygon, 1), 
        polygon=polygon, 
        refine=refine);
      parameter Integer boundarySize=nbp;
    end Data;
    
  end DiscreteDomain;
  
  package Mesh "2D spatial domain" 
    import PDEbhjl.FEMExternalMesh.MeshGeneration.*;
    
    function get_s = getSizes;
    function get_vertex = getVertex;
    function get_e = getEdge;
    function get_t = getTriangle;
    
    function get_x 
      input Data mesh;
      input Integer i;
      output Coordinate x[3];
    algorithm 
      x := get_vertex(mesh.meshData, i);
    end get_x;
    
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
      parameter MeshData meshData=MeshData(polygon, bc, refine);
      
      //parameter Integer s[3] = get_s(mesh, status);
      // Necessary for dependency! Currently not supported by Dymola (BUG?)
      parameter Integer s[3]=get_s(meshData);
      
      parameter Integer nv=s[1] "Number of vertices";
      parameter Integer ne=s[2] "Number of edges on boundary";
      parameter Integer nt=s[3] "Number of triangles";
      
    end Data;
    
  end Mesh;
  
  package MeshGeneration "Grid generation for 1D and triangular 2D" 
    
    class MeshData 
      extends ExternalObject;
      function constructor 
        annotation (Include="#include <meshext.h>", Library="meshext");
        input Real xPolygon[:, 2];
        input Integer bc[size(xPolygon, 1)];
        input Real refine=0.5;
        //  h in (0,1) controls the refinement of triangles, less is finer
        output MeshData mesh;
      external "C" mesh = create_mesh2d_data(xPolygon, size(xPolygon, 1), size(
          xPolygon, 2), bc, size(bc, 1), refine);
        
      end constructor;
      
      function destructor "Release storage of table" 
        annotation (Include="#include <meshext.h>", Library="meshext");
        input MeshData mesh;
      external "C" free_mesh2d_data(mesh);
      end destructor;
    end MeshData;
    
    function getSizes "Reads sizes mesh-data 2D" 
      annotation (Include="#include <meshext.h>", Library="meshext");
      input MeshData mesh;
      output Integer s[3] "Sizes of mesh-data {vertices, edges, triangles}";
    external "C" get_mesh2d_sizes(mesh, s, size(s, 1));
      
    end getSizes;
    
    function getVertex "Reads one vertex coordinate" 
      annotation (Include="#include <meshext.h>", Library="meshext");
      input MeshData mesh;
      input Integer i "Vertex index";
      output Real v[3];
    external "C" get_mesh2d_vertex(mesh, i, v, size(v, 1));
    end getVertex;
    
    function getEdge "Reads one edgeon boundary 2D" 
      input MeshData mesh;
      input Integer i "Edge index";
      output Integer e[3];
    algorithm 
      e := {1,2,3};
      // not implemented yet. Not needed?
    end getEdge;
    
    function getTriangle "Reads one triangle 2D" 
      
      input MeshData mesh;
      input Integer i "Triangle index";
      output Integer t[4];
    algorithm 
      t := {1,2,3,4};
      // Not implemented yet. Needed?
    end getTriangle;
    
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
        x := Mesh.get_x(ddomain.mesh, i);
        val[i] := dfieldP.fieldP.value(x, field);
      end for;
    end interpolate;
    
  end Interpolation;
  
  package PoissonSolver 
    
    function getMatrix_Laplace 
      input Mesh.Data mesh;
      input Integer nv;
      input Integer ne;
      input Real g_rhs_val[nv];
      input Integer bndcond[ne, 2];
      output Real Laplace[nv, nv];
    algorithm 
      Laplace := get_rheolef_poisson_laplace(mesh.filename, nv);
    end getMatrix_Laplace;
    
    function getMatrix_g 
      input Mesh.Data mesh;
      input Integer nv;
      input Integer ne;
      input Real g_rhs_val[nv];
      input Integer bndcond[ne, 2];
      output Real g[nv];
    algorithm 
      g := get_rheolef_poisson_g(mesh.filename, nv);
    end getMatrix_g;
    
    function get_rheolef_poisson_laplace 
      annotation (Include="#include <poisson_rheolef_ext.h>", Library="rheolef");
      input String meshData;
      input Integer nv;
      output Real laplace[nv, nv];
    external "C" get_rheolef_poisson_laplace(meshData, nv, laplace);
      
    end get_rheolef_poisson_laplace;
    
    function get_rheolef_poisson_g 
      annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
      input String meshData;
      input Integer nv;
      output Real g[nv];
    external "C" get_rheolef_poisson_g(meshData, nv, g);
      
    end get_rheolef_poisson_g;
    
    function writeMatrix_Laplace 
      annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
      input Integer nv;
      input Real Laplace[nv, nv];
    external "C" put_rheolef_poisson_laplace("intsolver_laplace.txt", nv, 
        Laplace);
    end writeMatrix_Laplace;
    
    function writeMatrix_g 
      annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
      input Integer nv;
      input Real g[nv];
    external "C" put_rheolef_poisson_g("intsolver_g.txt", nv, g);
    end writeMatrix_g;
    
  end PoissonSolver;
  
end FEMExternalMesh;
