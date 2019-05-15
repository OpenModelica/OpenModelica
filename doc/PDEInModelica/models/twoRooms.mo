class twoRooms
  ...
  parameter Real lx1 = 5, ly = 4, lz = 3, lx2 = 6;
  coordinates x, y, z;
  DomainBlock3D room1(Lx=lx1, Ly=ly, Lz=lz, ax = 0, ay = 0, az = 0, x=x, y=y, z=z);
  DomainBlock3D room2(Lx=lx2, Ly=ly, Lz=lz, ax = 0, ay = 0, az = 0, x=x-lx1, y=y, z=z);

  field Real u1(domain = room1);
  field Real u2(domain = room2);

equation
  ...
  u1 = u2  in room1.right; //or "in room2.left;", it is equivalent
  ...
end twoRooms

