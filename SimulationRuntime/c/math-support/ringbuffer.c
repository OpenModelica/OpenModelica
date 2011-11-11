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

  rb->firstElement = 0;
  rb->nElements = 0;
  rb->bufferSize = bufferSize > 0 ? bufferSize : 1;
  rb->itemSize = itemSize;
  rb->buffer = calloc(rb->bufferSize, rb->itemSize);
  ASSERT(rb->buffer, "out of memory");
}

void freeRingBuffer(RINGBUFFER *rb)
{
  free(rb->buffer);
  free(rb);
}

void *getRingData(RINGBUFFER *rb, int i)
{
  ASSERT(i < rb->nElements, "index out of range");
  ASSERT(-rb->nElements < i, "index out of range");
  return ((char*)rb->buffer)+(((rb->firstElement+i)%rb->bufferSize)*rb->itemSize);
}

void expandRingBuffer(RINGBUFFER *rb)
{
  int i;

  void *temp = calloc(2*rb->bufferSize, rb->itemSize);
  ASSERT(temp, "out of memory");

  for(i=0; i<rb->nElements; i++)
    memcpy(((char*)temp)+(i*rb->itemSize), getRingData(rb, i), rb->itemSize);

  free(rb->buffer);
  rb->buffer = temp;
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
  ASSERT(n <= rb->nElements, "index out of range");
  ASSERT(0 <= n, "index out of range)");

  rb->firstElement = (rb->firstElement+n)%rb->bufferSize;
  rb->nElements -= n;
}

int ringBufferLength(RINGBUFFER *rb)
{
  return rb->nElements;
}
