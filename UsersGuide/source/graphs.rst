.. _graphs :

Generating Graph Representations for Models
===========================================


The system of equations after symbolic transformation is represented by a graph.
OpenModelica can generate graph representations which can be displayed in the graph tool *yed* (http://www.yworks.com/products/yed).
The graph generation is activated with the debug flag

| +d=graphml

Two different graphml- files are generated in the working directory.
*TaskGraph_model.graphml*, showing the strongly-connected components of the model and *BipartiteGraph_CompleteDAE_model.graphml* showing all variables and equations.
When loading the graphs with *yEd*, all nodes are in one place. Please use the various layout algorithms to get a better overview.

.. figure :: media/taskgraph.png
  :name: task-graph
  
  A task-graph representation of a model in yEd
  
.. figure :: media/bipartit.png
  :name: biparite graph
  
  A biparite graph representation of a model in yEd
  
