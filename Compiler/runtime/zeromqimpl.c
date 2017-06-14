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
    printf("Error creating ZeroMQ Server. zmq_bind failed: %s\n", strerror(errno));
    return mmcZmqSocket;
  }
  mmcZmqSocket = mmc_mk_some(zmqSocket);
  return mmcZmqSocket;
}

extern char* ZeroMQImpl_handleRequest(void *mmcZmqSocket)
{
  // Convert the void* to ZeroMQ Socket
  intptr_t zmqSocket = (intptr_t)MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmcZmqSocket),1));
  // Create an empty ZeroMQ message to hold the message part
  zmq_msg_t request;
  int rc = zmq_msg_init(&request);
  assert(rc == 0);
  // Block until a message is available to be received from socket
  int size = zmq_msg_recv(&request, (void*)zmqSocket, 0);
  assert(size != -1);
  // copy the zmq_msg_t to char*
  char *requestStr = (char*)malloc(size + 1);
  memcpy(requestStr, zmq_msg_data(&request), size);
  // release the zmq_msg_t
  zmq_msg_close(&request);
  requestStr[size] = 0;
  //fprintf(stdout, "Recieved message %s with size %d\n", requestStr, size);fflush(NULL);
  return requestStr;
}

void ZeroMQ_sendReply(void *mmcZmqSocket, const char* reply)
{
  // Convert the void* to ZeroMQ Socket
  intptr_t zmqSocket = (intptr_t)MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmcZmqSocket),1));
  // send the reply
  //fprintf(stdout, "Sending message %s\n", reply);fflush(NULL);
  // Create an empty ZeroMQ message to hold the message part
  zmq_msg_t replyMsg;
  zmq_msg_init_size(&replyMsg, strlen(reply));
  // copy the char* to zmq_msg_t
  memcpy(zmq_msg_data(&replyMsg), reply, strlen(reply));
  // send the message
  zmq_msg_send(&replyMsg, (void*)zmqSocket, 0);
  // release the zmq_msg_t
  zmq_msg_close(&replyMsg);
}

void ZeroMQ_close(void *mmcZmqSocket)
{
  // Convert the void* to ZeroMQ Socket
  intptr_t zmqSocket = (intptr_t)MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(mmcZmqSocket),1));
  // close the ZeroMQ socket
  zmq_close((void*)zmqSocket);
}
