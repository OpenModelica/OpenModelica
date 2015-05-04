
package p
connector Out = output Real "'output Real' as connector";
connector In = input Real "'input Real' as connector";

block A
  Out y;
equation
  y = sin(time);
end A;

model B
  In u;
  Out y;
  Real x(start=1);
equation
  y = u * x;
  der(x) = y;
end B;

model C
 Real x1(start=1);
 Real x2(start=2);
 In u1,u2;
 Out y,y1;
 parameter Real a=6,b=2,c=4;
equation
 der(x1) = a*x1-b*x2;
 der(x2) = c*x1-a*x2;
 y = der(x1) + der(x2) + u1;
 y1 = der(x1) + der(x2) +  u2;
end C;


model nonlinsys
 A a1,a2;
 B b1;
 C c1;
 Out y1,y2;
 In u1;
equation
 connect(b1.u,a1.y);
 connect(c1.u1,a2.y);
 connect(b1.y,c1.u2);
 connect(c1.u1,y1);
 connect(c1.u2,y2);
end nonlinsys;
end p;
