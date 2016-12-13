/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/*
 * this does not work
 * we need to separate RingBuffer and expandable queue
 */

#include "ringbuffer.h"
#include "omc_error.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>


struct RINGBUFFER
{
  void *buffer;       /* buffer itself */
  int itemSize;       /* size of one item in bytes */
  int firstElement;   /* position of first element in buffer */
  int nElements;      /* number of elements in buffer */
  int bufferSize;     /* number of elements which could be stored in buffer */
};
#include "ringbuffer.h"

RINGBUFFER *allocRingBuffer(int bufferSize, int itemSize)
{
  RINGBUFFER *rb = (RINGBUFFER*)malloc(sizeof(RINGBUFFER));
  assertStreamPrint(NULL, 0 != rb, "out of memory");

  rb->firstElement = 0;
  rb->nElements = 0;
  rb->bufferSize = bufferSize > 0 ? bufferSize : 1;
  rb->itemSize = itemSize;
  rb->buffer = calloc(rb->bufferSize, rb->itemSize);
  assertStreamPrint(NULL, 0 != rb->buffer, "out of memory");

  return rb;
}

void freeRingBuffer(RINGBUFFER *rb)
{
  free(rb->buffer);
  free(rb);
}

void *getRingData(RINGBUFFER *rb, int i)
{
  assertStreamPrint(NULL, rb->nElements > 0, "empty RingBuffer");
  assertStreamPrint(NULL, i < rb->nElements, "index [%d] out of range [%d:%d]", i, -rb->nElements+1, rb->nElements-1);
  assertStreamPrint(NULL, -rb->nElements < i, "index [%d] out of range [%d:%d]", i, -rb->nElements+1, rb->nElements-1);
  return ((char*)rb->buffer)+(((rb->firstElement+i)%rb->bufferSize)*rb->itemSize);
}

void expandRingBuffer(RINGBUFFER *rb)
{
  int i;

  void *tmp = calloc(2*rb->bufferSize, rb->itemSize);
  assertStreamPrint(NULL, 0!=tmp, "out of memory");

  for(i=0; i<rb->nElements; i++) {
    memcpy(((char*)tmp)+(i*rb->itemSize), getRingData(rb, i), rb->itemSize);
  }

  free(rb->buffer);
  rb->buffer = tmp;
  rb->bufferSize *= 2;
  rb->firstElement = 0;
}

void appendRingData(RINGBUFFER *rb, void *value)
{
  if(rb->bufferSize < rb->nElements+1)
    expandRingBuffer(rb);

  memcpy(((char*)rb->buffer)+(((rb->firstElement+rb->nElements)%rb->bufferSize)*rb->itemSize), value, rb->itemSize);
  ++rb->nElements;
}

void dequeueNFirstRingDatas(RINGBUFFER *rb, int n)
{
  assertStreamPrint(NULL, rb->nElements > 0, "empty RingBuffer");
  assertStreamPrint(NULL, n < rb->nElements, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);
  assertStreamPrint(NULL, 0 <= n, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);

  rb->firstElement = (rb->firstElement+n)%rb->bufferSize;
  rb->nElements -= n;
}

int ringBufferLength(RINGBUFFER *rb)
{
  return rb->nElements;
}

void rotateRingBuffer(RINGBUFFER *rb, int n, void **lookup)
{
  TRACE_PUSH

  assertStreamPrint(NULL, rb->nElements > 0, "empty RingBuffer");
  assertStreamPrint(NULL, n < rb->nElements, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);
  assertStreamPrint(NULL, 0 <= n, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);

  rb->firstElement = (rb->firstElement+(n*(rb->bufferSize-1)))%rb->bufferSize;

  if(lookup)
  {
    long i;

    for(i=0; i<rb->nElements; ++i){
      lookup[i] = getRingData(rb, i);
    }
  }

  TRACE_POP
}

void infoRingBuffer(RINGBUFFER *rb)
{
  if (ACTIVE_STREAM(LOG_UTIL)) {
    infoStreamPrint(LOG_UTIL, 1, "RingBuffer-Info");
    infoStreamPrint(LOG_UTIL, 0, "itemSize: %d [size of one item in bytes]", rb->itemSize);
    infoStreamPrint(LOG_UTIL, 0, "firstElement: %d [position of first element in buffer]", rb->firstElement);
    infoStreamPrint(LOG_UTIL, 0, "nElements: %d [number of elements in buffer]", rb->nElements);
    infoStreamPrint(LOG_UTIL, 0, "bufferSize: %d [number of elements which could be stored in buffer]", rb->bufferSize);
    messageClose(LOG_UTIL);
  }
}
