model membraneInAir
  import C = Modelica.Constants;
  //membrane variables:
  r = 0.15; //membrane radius
  parameter Real c_m = 100; //wave speed traversing the membrane

  DomainCircular2D membrane(radius = r);
  
  function u0
    input x, y;
    output u0 = cos(sqrt(x^2 + y^2)*C.pi/(2*r));
  end u0;
  
  field Real u(domain = membrane, start[0] = u0, start[1] = 0);  //

  //room variables

  record Room
    extends DomainBlock3D;
    parameter Real ax, ay, az, r; //x, y, and z center of membrane and radius
    function shapeCircular
      input Real r, phi;
      output Real x,y,z;
      algorithm
        x := ax + r*cos(phi);
        y := az + r*sin(phi);
        z := az;
    end shapeCylinder
    Region2D membrane(shape = shapeCircular, interval = {{0,r},{0,2*C.pi}});
  end Room

  parameter Real lx = 5, ly = 4, lz = 3; //room dimensions
  parameter Real ax = lx/2, ay = ly/2, az = 1;  //membrane center position in room
  parameter Real p_0 = 101300;  //mean pressure
  
  Room room(Lx=lx, Ly=ly, Lz=lz, ax = ax, ay = ay, az = az, r = r);

  //room variables:
  parameter Real rho_0 = 1.2;   //air density
  parameter Real c_a = 340;     //speed of sound in air
  field Real v[3](domain=room, start = zeros(3)); //air speed
  field Real p(domain=rooom, start = p_0);   //air pressure
  
equation
  //membrane equations:
  pder(u,t,t) = c_m^2*grad(diverg(u))  in membrane.interior;
  u = 0  in membrane.boundary;

  //room equations:
  rho_0*pder(v,t) + grad(p) = 0  in room.interior;
  pder(p,t) + rho_0*c_0^2*diverg(v)  in room.interior;
  v*region.n = 0  in room.boundary;
  v(dom.x,dom.y,dom.z,t)*region.n = pder(u,t)(dom.x - a_x,dom.y - a_y,t)  in room.membrane;
end membraneInAir;