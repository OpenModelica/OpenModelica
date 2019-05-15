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

encapsulated package GraphStream
" file:        GraphStream
  package:     GraphStream
  description: GraphStream contains functions to send the graph dynamically to a GraphStream viewer.
               For more info see:
                 http://graphstream-project.org/
                 http://graphstream-project.org/doc/Tutorials/Storing-retrieving-and-displaying-data-in-graphs_1.0/
                 http://graphstream-project.org/doc/Tutorials/GraphStream-CSS-Reference_1.0/


  Most of the implementation is external in GraphStreamExt.

"

public
import Values;

protected
import Autoconf;
import GraphStreamExt;
import System;
import Settings;

public function startExternalViewer
  input String host;
  input Integer port;
  output Integer status;
algorithm
  status := matchcontinue(host, port)
    local
      String omhome, command, commandWin, commandLinux;

    case (_, _)
      equation
        omhome = Settings.getInstallationDirectoryPath();
        commandWin = "start /b java -jar " + omhome + "/share/omc/java/org.omc.graphstream.jar";
        commandLinux = "java -jar " + omhome + "/share/omc/java/org.omc.graphstream.jar &";
        command = if "Windows_NT" == Autoconf.os then commandWin else commandLinux;
        status = System.systemCall(command, "");
        true = status == 0;
      then
        status;

    else
      equation
        print("GraphStream: failed to start the external viewer!\n");
      then
        fail();
  end matchcontinue;
end startExternalViewer;

public function newStream
  input String streamName;
  input String host;
  input Integer port;
  input Boolean debug;
algorithm
  GraphStreamExt.newStream(streamName, host, port, debug);
end newStream;

public function addNode
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeId;
algorithm
  GraphStreamExt.addNode(streamName, sourceId, timeId, nodeId);
end addNode;

public function addEdge
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeIdSource;
  input String nodeIdTarget;
  input Boolean directed;
algorithm
  GraphStreamExt.addEdge(streamName, sourceId, timeId, nodeIdSource, nodeIdTarget, directed);
end addEdge;

public function addNodeAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeId;
  input String attributeName;
  input Values.Value attributeValue;
algorithm
  GraphStreamExt.addNodeAttribute(streamName, sourceId, timeId, nodeId, attributeName, attributeValue);
end addNodeAttribute;

public function changeNodeAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeId;
  input String attributeName;
  input Values.Value attributeValueOld;
  input Values.Value attributeValueNew;
algorithm
  GraphStreamExt.changeNodeAttribute(streamName, sourceId, timeId, nodeId, attributeName, attributeValueOld, attributeValueNew);
end changeNodeAttribute;

public function addEdgeAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String nodeIdSource;
  input String nodeIdTarget;
  input String attributeName;
  input Values.Value attributeValue;
algorithm
  GraphStreamExt.addEdgeAttribute(streamName, sourceId, timeId, nodeIdSource, nodeIdTarget, attributeName, attributeValue);
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
algorithm
  GraphStreamExt.changeEdgeAttribute(streamName, sourceId, timeId, nodeIdSource, nodeIdTarget, attributeName, attributeValueOld, attributeValueNew);
end changeEdgeAttribute;

public function addGraphAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String attributeName;
  input Values.Value attributeValue;
algorithm
  GraphStreamExt.addGraphAttribute(streamName, sourceId, timeId, attributeName, attributeValue);
end addGraphAttribute;

public function changeGraphAttribute
  input String streamName;
  input String sourceId;
  input Integer timeId;
  input String attributeName;
  input Values.Value attributeValueOld;
  input Values.Value attributeValueNew;
algorithm
  GraphStreamExt.changeGraphAttribute(streamName, sourceId, timeId, attributeName, attributeValueOld, attributeValueNew);
end changeGraphAttribute;

public function cleanup
algorithm
  GraphStreamExt.cleanup();
end cleanup;

annotation(__OpenModelica_Interface="frontend");
end GraphStream;
