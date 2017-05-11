within TwoTanksExample.Design.Components;

function limitValue
input Real pMin; input Real pMax;
input Real p; output Real pLim; protected
algorithm
pLim := if p>pMax then pMax
else if p<pMin then pMin else p;
end limitValue;