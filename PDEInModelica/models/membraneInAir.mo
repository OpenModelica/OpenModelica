model membraneInAir
  import C = Modelica.Constants;
  record Room
    extends DomainBlock3D;
    parameter Real ax, ay, az, R; //je tohle mo¾ný??
    function shapeCircular
      input Real r, phi;
      output Real x,y,z;
      algorithm
        x := ax + r*cos(phi);
        y := az + r*sin(phi);
        z := az;
    end shapeCylinder
    Region2D membranePosition(shape = shapeCircular, range = {{0,R},{0,2*C.pi}});
  end Room
  parameter Real lx = 5, ly = 4, lz = 3;
  Room room(Lx=lx, Ly=ly, Lz=lz);


  field Real T(domain = room, start = Tout);
  field Real[3] W(domain = room, start = {0,0,0});
  parameter Real c = 1012;
  parameter Real rho = 1.204;
  parameter Real lambda = 0.0257;
  parameter Real Tout = 0;
  parameter Real kappa = 0.2;
  Real Ts;
  Real P;
  parameter Real kp = 100, ki = 200, kd = 100;
  parameter Real Td = 20;
  Real eInt;
 equation
  1/(c*rho)*diverg(W) = - pder(T,t)    in room.interior;
  W = -lambda*grad(T)                  in room.interior;
//TODO: use normal vector:
  W[1] = P/(lx*ly)                     in room.left;
  W[2] = 0                             in room.front + room.rare;
  W[3] = 0                             in room.top + room.bottom;
  W[1] = kappa*(T - Tout)              in room.right;
  Ts = T                               in room.sensorPosition;
  e = Td - Ts;
  der(eInt) = e;
  P = kp*e + ki*eInt + kd*der(e);
end membraneInAir;