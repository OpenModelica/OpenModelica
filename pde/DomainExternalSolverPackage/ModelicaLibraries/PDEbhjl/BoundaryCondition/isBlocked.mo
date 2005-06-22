function isBlocked 
  input TypeEnum bcType;
  output Boolean blocked;
algorithm 
  blocked := if bcType == dirichlet or bcType == timedepdirichlet then true
     else false;
end isBlocked;
