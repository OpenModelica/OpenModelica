model Tearing18 "Modified example from Book Continous System Simulation by F. Cellier page 261"
   Real x0;
   Real x3;
   Real x4;
   Real x5;
   Real x6;
   Real x7;
   Real x8;
equation
   x0 = sin(5*time);
   sin(time)*x3 + x4 + x0 = 0;
   x5 + cos(time)*x6 - x0 = 0;
   sin(x7) + x8 = 0;
   x3 - x7 + 2 = 0;
   x5 + sin(time)*x7 + 2*x0 = 0;
   x4 + x6 + cos(time)*x8 = 0;
end Tearing18;