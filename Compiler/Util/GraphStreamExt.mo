/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package GraphStreamExt
" file:        GraphStreamExt
  package:     GraphStreamExt
  description: GraphStreamExt contains functions to send the graph dynamically to a GraphStreamExt viewer.



  The implementation is external.

"

public
import Values;

public function newStream
  input String streamName;
  input String host;
  input Integer port;
  input Boolean debug;

  external "C" GraphStreamExt_newStream(OpenModelica.threadData(), streamName, host, port, debug) annotation(Library = "omcruntime");
end newStream;

public function addNode
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeId;

  external "C" GraphStreamExt_addNode(OpenModelica.threadData(), streamName, sourceId, timeId, nodeId) annotation(Library = "omcruntime");
end addNode;

public function addEdge
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeIdSource;
  input String nodeIdTarget;
  input Boolean directed;

  external "C" GraphStreamExt_addEdge(OpenModelica.threadData(), streamName, sourceId, timeId, nodeIdSource, nodeIdTarget, directed) annotation(Library = "omcruntime");
end addEdge;

public function addNodeAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeId;
  input String attributeName;
  input Values.Value attributeValue;

  external "C" GraphStreamExt_addNodeAttribute(OpenModelica.threadData(), streamName, sourceId, timeId, nodeId, attributeName, attributeValue) annotation(Library = "omcruntime");
end addNodeAttribute;

public function changeNodeAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeId;
  input String attributeName;
  input Values.Value attributeValueOld;
  input Values.Value attributeValueNew;

  external "C" GraphStreamExt_changeNodeAttribute(OpenModelica.threadData(), streamName, sourceId, timeId, nodeId, attributeName, attributeValueOld, attributeValueNew) annotation(Library = "omcruntime");
end changeNodeAttribute;

public function addEdgeAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeIdSource;
  input String nodeIdTarget;
  input String attributeName;
  input Values.Value attributeValue;

  external "C" GraphStreamExt_addEdgeAttribute(OpenModelica.threadData(), streamName, sourceId, timeId, nodeIdSource, nodeIdTarget, attributeName, attributeValue) annotation(Library = "omcruntime");
end addEdgeAttribute;

public function changeEdgeAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeIdSource;
  input String nodeIdTarget;
  input String attributeName;
  input Values.Value attributeValueOld;
  input Values.Value attributeValueNew;

  external "C" GraphStreamExt_changeEdgeAttribute(OpenModelica.threadData(), streamName, sourceId, timeId, nodeIdSource, nodeIdTarget, attributeName, attributeValueOld, attributeValueNew) annotation(Library = "omcruntime");
end changeEdgeAttribute;

public function addGraphAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String attributeName;
  input Values.Value attributeValue;

  external "C" GraphStreamExt_addGraphAttribute(OpenModelica.threadData(), streamName, sourceId, timeId, attributeName, attributeValue) annotation(Library = "omcruntime");
end addGraphAttribute;

public function changeGraphAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String attributeName;
  input Values.Value attributeValueOld;
  input Values.Value attributeValueNew;

  external "C" GraphStreamExt_changeGraphAttribute(OpenModelica.threadData(), streamName, sourceId, timeId, attributeName, attributeValueOld, attributeValueNew) annotation(Library = "omcruntime");
end changeGraphAttribute;

public function cleanup
  external "C" GraphStreamExt_cleanup(OpenModelica.threadData()) annotation(Library = "omcruntime");
end cleanup;

annotation(__OpenModelica_Interface="frontend");
end GraphStreamExt;
