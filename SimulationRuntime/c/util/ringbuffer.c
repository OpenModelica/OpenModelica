/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

/*
 * this does not work
 * we need to seperate RingBuffer and expandable queue
 */

#include "ringbuffer.h"
#include "omc_error.h"

#include <assert.h>
#include <stdlib.h>
#include <memory.h>

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
  ASSERT(rb, "out of memory");

  rb->firstElement = 0;
  rb->nElements = 0;
  rb->bufferSize = bufferSize > 0 ? bufferSize : 1;
  rb->itemSize = itemSize;
  rb->buffer = calloc(rb->bufferSize, rb->itemSize);
  ASSERT(rb->buffer, "out of memory");

  return rb;
}

void freeRingBuffer(RINGBUFFER *rb)
{
  free(rb->buffer);
  free(rb);
}

void *getRingData(RINGBUFFER *rb, int i)
{
  ASSERT(rb->nElements > 0, "empty RingBuffer");
  ASSERT3(i < rb->nElements, "index [%d] out of range [%d:%d]", i, -rb->nElements+1, rb->nElements-1);
  ASSERT3(-rb->nElements < i, "index [%d] out of range [%d:%d]", i, -rb->nElements+1, rb->nElements-1);
  return ((char*)rb->buffer)+(((rb->firstElement+i)%rb->bufferSize)*rb->itemSize);
}

void expandRingBuffer(RINGBUFFER *rb)
{
  int i;

  void *tmp = calloc(2*rb->bufferSize, rb->itemSize);
  ASSERT(tmp, "out of memory");

  for(i=0; i<rb->nElements; i++)
    memcpy(((char*)tmp)+(i*rb->itemSize), getRingData(rb, i), rb->itemSize);

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
  ASSERT(rb->nElements > 0, "empty RingBuffer");
  ASSERT3(n < rb->nElements, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);
  ASSERT3(0 <= n, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);

  rb->firstElement = (rb->firstElement+n)%rb->bufferSize;
  rb->nElements -= n;
}

int ringBufferLength(RINGBUFFER *rb)
{
  return rb->nElements;
}

void rotateRingBuffer(RINGBUFFER *rb, int n, void **lookup)
{
  long i;

  ASSERT(rb->nElements > 0, "empty RingBuffer");
  ASSERT3(n < rb->nElements, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);
  ASSERT3(0 <= n, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);

  rb->firstElement = (rb->firstElement+(n*(rb->bufferSize-1)))%rb->bufferSize;

  if(lookup)
  {
    for(i=0; i<rb->nElements; ++i){
      lookup[i] = getRingData(rb, i);
    }
  }
}

void infoRingBuffer(RINGBUFFER *rb)
{
  INFO(LOG_UTIL, "RingBuffer-Info");
  INDENT(LOG_UTIL);
  INFO1(LOG_UTIL, "itemSize: %d [size of one item in bytes]", rb->itemSize);
  INFO1(LOG_UTIL, "firstElement: %d [position of first element in buffer]", rb->firstElement);
  INFO1(LOG_UTIL, "nElements: %d [number of elements in buffer]", rb->nElements);
  INFO1(LOG_UTIL, "bufferSize: %d [number of elements which could be stored in buffer]", rb->bufferSize);
  RELEASE(LOG_UTIL);
}
