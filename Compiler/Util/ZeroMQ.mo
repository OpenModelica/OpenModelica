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

encapsulated package ZeroMQ
" file:        ZeroMQ.mo
  package:     ZeroMQ
  description: ZeroMQ communication module


  This is the ZeroMQ connection module of the compiler
  Used in interactive mode if omc is started with +d=interactiveZMQ
  Implemented in ./runtime/zeromqimpl.c"

public function initialize
  input Integer port;
  output Option<Integer> zmqSocket;

  external "C" zmqSocket = ZeroMQ_initialize(port) annotation(Library = "omcruntime");
end initialize;

public function handleRequest
  input Option<Integer> zmqSocket;
  output String request;

  external "C" request = ZeroMQ_handleRequest(zmqSocket) annotation(Library = "omcruntime");
end handleRequest;

public function sendReply
  input Option<Integer> zmqSocket;
  input String reply;

  external "C" ZeroMQ_sendReply(zmqSocket, reply) annotation(Library = "omcruntime");
end sendReply;

public function close
  input Option<Integer> zmqSocket;

  external "C" ZeroMQ_close(zmqSocket) annotation(Library = "omcruntime");
end close;

annotation(__OpenModelica_Interface="util");
end ZeroMQ;
