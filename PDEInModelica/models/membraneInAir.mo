model membraneInAir
  import C = Modelica.Constants;

  //room deffinitions:
  parameter Real lx = 5, ly = 4, lz = 3;
  coordinates cartesian[3];
  DomainBlock3D room(cartesian = cartesian, Lx=lx, Ly=ly, Lz=lz);

  parameter Real p_0 = 101300;  //mean pressure

  field Real v[3](domain=room, start = zeros(3)); //air speed
  field Real p(domain=rooom, start = p_0);   //air pressure

  parameter Real rho_0 = 1.2;   //air density
  parameter Real c_a = 340;     //speed of sound in air

  //membrane deffinitions
  parameter Point membranePos(x=lx/2,y=ly/2,z=lz/2); //position of membrane center in the room
  r = 0.15; //membrane radius


//There are several options to define membrane domain. They are not concurrent, but should be all possible.

  //two options, first per coordinates
  CircularDomian2D membrane1(radius = r, x=x-membranePos.x, y=y-membranePos.y, 0=z-membranePos.z); //equation "0=z-membranePos.z" holds just in "membrane" domain. Perhaps should not be considered to be an equation but somethik else.

  //other in vector notation
  coordinates shiftCartesian[3] = cartesian - {membranePos.x, membranePos.y, membranePos.z};
  CircularDomain2D membrane2(radius = r, cat(1,cartesian,{0}) = shiftCartesian); //3th of the vector equations "cat(1,cartesian,{0}) = shiftCartesian" i.e. "0=z-membranePos.z" holds only in membrane.

//if the membrane is rotated then, first option:
  parameter Real phi = C.Pi/2;
  CircularDomain2D membrane3(radius = r, x=cos(phi)*(x-membranePos.x) + sin(phi)*(z-membranePos.z), y=y-membranePos.y, 0=-sin(phi)*(x-membranePos.x)+ cos(phi)*(z-membranePos.z)); //"0=-sin(phi)*(x-membranePos.x)+ cos(phi)*(z-membranePos.z)" - same, hold only in "membrane"

//other option in matrix notation:
  parameter Real rotM[3,3] = {{cos(phi),0,sin(phi)},{0,1,0},{-sin(phi),0,cos(phi)}};
  CircularDomain2D membrane4(radius = r, cat(1,cartesian,{0})=rotM*shiftCartesian); //last row of matrix eq. holds only in "membrane"



  parameter Real c_m = 100; //wave speed traversing the membrane
  
  function u0
    input x, y;
    output u0 = cos(sqrt(x^2 + y^2)*C.pi/(2*r));
  end u0;
  
  field Real u(domain = membrane, start[0] = u0, start[1] = 0);  

  
equation
  //membrane equations:
  pder(u,t,t) = c_m^2*grad(diverg(u))  in membrane.interior;
  u = 0  in membrane.boundary;

  //room equations:
  rho_0*pder(v,t) + grad(p) = 0          in room.interior;
  pder(p,t) + rho_0*c_0^2*diverg(v) = 0  in room.interior;
  v*region.n = 0  in room.boundary;

  v*region.n = pder(u,t)  in membrane.interior; 
end membraneInAir;
















//Another aproach - class defining coordinates encloses domains :
class RoomAndMembrane
  ...
  parameter Real lx = 5, ly = 4, lz = 3;

  coordinates x, y, z;
  coordinates shiftCoord[3] = {x-membranePos.x,y-membranePos.y,z-membranePos.z};
  DomainBlock3D room(x=x, y=y, z=z, Lx=lx, Ly=ly, Lz=lz, ax = 0, ay = 0, az = 0);

//3 options to define membrane and and inner and outer coordinate transformation:

//1st:

//2nd rotated membrane

 //3th rotated, in matrix notation

  //air:
  field Real v[3](domain=room, start = zeros(3)); //speed
  field Real p(domain=rooom, start = p_0);   //pressure
  //membrane:
  field Real u(domain = membrane, start[0] = u0, start[1] = 0);  //displacement
equation
  ...
  v*region.n = pder(u,t)  in room.membrane; //relation between membrane and air fields
  ...  
end RoomAndMembrane

