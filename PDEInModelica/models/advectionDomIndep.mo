package advectionDomIndep "advection equation"
  class AdvectionEq
    //omega - to be redefined in constructor. Or is it possible to avoid omega deffinition here at all?
    replaceable omega = DomainLineSegment1D;
    parameter Real c = 1;
    field Real u(domain = omega);
  equation
    pder(u,time) + c*grad(u) = 0  in omega.interior;
  end advectionEq

  model advectionModel
    import C = Modelica.Constants;
    parameter Real L = 1; // length
    DomainLineSegment1D omega(length = L);
    AdvectionEq advEq(omega = omega)
      initial equation
      advEq.u = 1;
  equation
    //boundary condition
    advEq.u = cos(2*C.pi*time)            in omega.left;
  end advectionModel
end advectionDomIndep;