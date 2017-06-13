/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <zmq.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include "modelica_string.h"

void* ZeroMQ_initialize(int port)
{
  // Create a pointer for storing the ZeroMQ socket
  void *mmcZmqSocket = mmc_mk_some(0);
  // Create the ZeroMQ context
  void *context = zmq_ctx_new();
  void *zmqSocket = zmq_socket(context, ZMQ_REP);
  char hostname[20];
  sprintf(hostname, "tcp://*:%d", port);
  int rc = zmq_bind(zmqSocket, hostname);
  if (rc != 0) {
    printf("Error creating ZeroMQ Server\n");
    return mmcZmqSocket;
  }
  mmcZmqSocket = mmc_mk_some(zmqSocket);
  return mmcZmqSocket;
}

extern char* ZeroMQImpl_handleRequest(void *mmcZmqSocket)
{
  int bufferSize = 4000;
  char *buffer = (char*)malloc(bufferSize + 1);
  // Convert the void* to ZeroMQ Socket
  intptr_t zmqSocket = (intptr_t)MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmcZmqSocket),1));
  zmq_recv((void*)zmqSocket, buffer, bufferSize, 0);
  fprintf(stdout, "Recieved message %s\n", buffer);fflush(NULL);
  return buffer;
}

void ZeroMQ_sendReply(void *mmcZmqSocket, const char* reply)
{
  // Convert the void* to ZeroMQ Socket
  intptr_t zmqSocket = (intptr_t)MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmcZmqSocket),1));
  // send the reply
  fprintf(stdout, "Sending message %s\n", reply);fflush(NULL);
  zmq_send((void*)zmqSocket, reply, strlen(reply) + 1, 0);
}

void ZeroMQ_close(void *mmcZmqSocket)
{
  // Convert the void* to ZeroMQ Socket
  intptr_t zmqSocket = (intptr_t)MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmcZmqSocket),1));
  // close the ZeroMQ socket
  zmq_close((void*)zmqSocket);
}
