 class CelestialBody "Celestial Body"
   Real mass;
   String name;
   constant Real g = 6.672e-11;
   parameter Real radius;
 end CelestialBody;

 class Body "Generic Body"
   Real mass;
   String name;
 end Body;

 class CelestialBody "Celestial Body"
   extends Body;
   constant Real g = 6.672e-11;
   parameter Real radius;
 end CelestialBody;
 
 