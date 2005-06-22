package BoundaryCondition 
constant Integer bcBegin=1;
constant TypeEnum dirichlet=bcBegin + 0;
constant TypeEnum neumann=bcBegin + 1;
constant TypeEnum robin=bcBegin + 2;
constant TypeEnum timedepdirichlet=bcBegin + 3;
constant Integer bcEnd=bcBegin + 3;
end BoundaryCondition;
