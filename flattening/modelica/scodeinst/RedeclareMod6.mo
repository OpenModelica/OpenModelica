// name: RedeclareMod6
// keywords:
// status: correct
// cflags: -d=newInst
//

record BaseCable
end BaseCable;

record Generic
  extends BaseCable;
end Generic;

partial model PartialBaseLine
  replaceable parameter Generic commercialCable;
end PartialBaseLine;

partial model PartialNetwork
  replaceable parameter PartialGrid grid;
  replaceable PartialBaseLine[grid.nLinks] lines;
end PartialNetwork;

model Line
  extends PartialBaseLine;
end Line;

record PartialGrid
  parameter Integer nLinks;
  replaceable BaseCable[nLinks] cables;
end PartialGrid;

record TestGrid2Nodes
  extends PartialGrid(nLinks = 1);
end TestGrid2Nodes;

model RedeclareMod6
  extends PartialNetwork(
    redeclare replaceable TestGrid2Nodes grid,
    redeclare Line lines(commercialCable = grid.cables));
end RedeclareMod6;

// Result:
// class RedeclareMod6
//   parameter Integer grid.nLinks = 1;
// end RedeclareMod6;
// endResult
