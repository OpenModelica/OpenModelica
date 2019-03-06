// name: RedeclareMod5
// keywords:
// status: correct
// cflags: -d=newInst
//

model Line
  parameter Real l;
end Line;

record PartialGrid
  parameter Integer nLinks;
  parameter Real[nLinks, 1] l;
end PartialGrid;

record TestGrid2Nodes
  extends PartialGrid(nLinks = 1, l = [200]);
end TestGrid2Nodes;

partial model PartialNetwork
  replaceable parameter PartialGrid grid;
  replaceable Line[grid.nLinks] lines(l = fill(1, grid.nLinks));
end PartialNetwork;

model RedeclareMod5
  extends PartialNetwork(redeclare replaceable TestGrid2Nodes grid, redeclare Line lines);
end RedeclareMod5;

// Result:
// class RedeclareMod5
//   parameter Integer grid.nLinks = 1;
//   parameter Real grid.l[1,1] = 200.0;
//   parameter Real lines[1].l = 1.0;
// end RedeclareMod5;
// endResult
