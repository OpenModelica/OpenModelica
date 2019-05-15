encapsulated package FGraphStream

function start
end start;

function finish = start;

function edge<A,B>
  input A name;
  input B source;
  input B target;
end edge;

function node<N>
  input N n;
end node;

annotation(__OpenModelica_Interface="frontend");
end FGraphStream;
