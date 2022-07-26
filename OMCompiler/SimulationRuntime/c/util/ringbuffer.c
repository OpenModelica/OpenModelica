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

/**
 * @brief Allcoate memroy for ring buffer.
 *
 * Free memory with `freeRingBuffer`.
 *
 * @param bufferSize      Number of elements in buffer.
 * @param itemSize        Size of single element in bits.
 * @return RINGBUFFER*    Pointer to allocated ring buffer.
 */
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

/**
 * @brief Free ring buffer
 *
 * @param rb  Pointer to ring buffer
 */
void freeRingBuffer(RINGBUFFER *rb)
{
  free(rb->buffer);
  free(rb);
}

/**
 * @brief Get data of i-th ring buffer element.
 *
 * Starts at rb->firstElement.
 *
 * @param rb        Non-empty ring buffer.
 * @param i         Index of element to get data of. Must be in range of the buffer.
 * @return void*    Pointer to data of i-th ring buffer item.
 */
void *getRingData(RINGBUFFER *rb, int i)
{
  assertStreamPrint(NULL, rb->nElements > 0, "empty RingBuffer");
  assertStreamPrint(NULL, i < rb->nElements, "index [%d] out of range [%d:%d]", i, -rb->nElements+1, rb->nElements-1);
  assertStreamPrint(NULL, -rb->nElements < i, "index [%d] out of range [%d:%d]", i, -rb->nElements+1, rb->nElements-1);
  return ((char*)rb->buffer)+(((rb->firstElement+i)%rb->bufferSize)*rb->itemSize);
}

/**
 * @brief Increase maximum number of elements of ring buffer.
 *
 * Doubles the size of the original ring buffer
 * and copies all values into updated buffer.
 *
 * @param rb    Pointer to ring buffer.
 */
void expandRingBuffer(RINGBUFFER *rb)
{
  rb->bufferSize *= 2;
  rb->buffer = realloc(rb->buffer, rb->bufferSize*rb->itemSize);
  assertStreamPrint(NULL, 0 != rb->buffer, "out of memory");
}

/**
 * @brief Add element to ring buffer.
 *
 * Will add to the end of the filled buffer.
 * If the buffer isn't big enough it will be expanded.
 *
 * @param rb      Pointer to ring buffer.
 * @param value   Data to add to ring buffer.
 */
void appendRingData(RINGBUFFER *rb, void *value)
{
  if(rb->bufferSize < rb->nElements+1)
    expandRingBuffer(rb);

  memcpy(((char*)rb->buffer)+(((rb->firstElement+rb->nElements)%rb->bufferSize)*rb->itemSize), value, rb->itemSize);
  ++rb->nElements;
}

/**
 * @brief Deque first n ring data elements.
 *
 * Will only update pointer to fist element
 * to be n elementes further.
 * Dequeued data is not freed yet.
 *
 * @param rb
 * @param n
 */
void dequeueNFirstRingDatas(RINGBUFFER *rb, int n)
{
  assertStreamPrint(NULL, rb->nElements > 0, "empty RingBuffer");
  assertStreamPrint(NULL, n < rb->nElements, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);
  assertStreamPrint(NULL, n > 0, "Can't deque nothing or negative amount.");

  rb->firstElement = (rb->firstElement+n)%rb->bufferSize;
  rb->nElements -= n;
}

/**
 * @brief Deque last n elements from ring buffer.
 *
 * Decrease counter nElements.
 * Dequeued data is not freed yet.
 *
 * @param rb    Pointer to ring buffer.
 * @param n     Number of elements to remove.
 */
void removeLastRingData(RINGBUFFER *rb, int n)
{
  assertStreamPrint(NULL, rb->nElements >= n, "empty RingBuffer");

  rb->nElements -= n;
}

/**
 * @brief Returns length of ring buffer.
 *
 * @param rb      Pointer to ring buffer.
 * @return int    Length of ring buffer.
 */
int ringBufferLength(RINGBUFFER *rb)
{
  return rb->nElements;
}

/**
 * @brief Rotate start point of ring buffer by n elements.
 *
 * @param rb        Pointer to ring buffer.
 * @param n         Number of items to rotate.
 */
void rotateRingBuffer(RINGBUFFER *rb, int n)
{
  TRACE_PUSH

  assertStreamPrint(NULL, rb->nElements > 0, "empty RingBuffer");
  assertStreamPrint(NULL, n < rb->nElements, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);
  assertStreamPrint(NULL, 0 <= n, "index [%d] out of range [%d:%d]", n, 0, rb->nElements-1);

  rb->firstElement = (rb->firstElement+(n*(rb->bufferSize-1)))%rb->bufferSize;

  TRACE_POP
}

/**
 * @brief Copy addresses of all buffer elements in order.
 *
 * @param rb        Pointer to ring buffer.
 * @param lookup    Pointer to array of buffer element pointer type and of length buffer->nElements.
 *                  Ring data addresses will be written into lookup.
 */
void lookupRingBuffer(RINGBUFFER *rb, void **lookup)
{
  TRACE_PUSH

  assertStreamPrint(NULL, rb->nElements > 0, "empty RingBuffer");
  assertStreamPrint(NULL, lookup, "Target buffer is NULL");

  for (int i = 0; i < rb->nElements; i++) {
    lookup[i] = ((char*)rb->buffer) + (((rb->firstElement+i)%rb->bufferSize)*rb->itemSize);
  }

  TRACE_POP
}

/**
 * @brief Dumps information about ring buffer to LOG_UTIL.
 *
 * @param rb    Pointer to ring buffer.
 */
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

/**
 * @brief Print a ringbuffer with provided print function.
 *
 * @param rb                Ringbuffer to print.
 * @param stream            Stream of type LOG_STREAM.
 * @param printDataFunc     Function to print address of buffer element and its data to stream.
 */
void printRingBuffer(RINGBUFFER *rb, int stream, void (*printDataFunc)(void*,int,void*)) {
  int i;
  void* bufferElemData;

  if (useStream[stream]) {
    infoStreamPrint(stream, 1, "Printing ring buffer:");
    infoRingBuffer(rb);

    for(i = 0; i < rb->nElements; ++i) {
      bufferElemData = getRingData(rb, i);
      printDataFunc(bufferElemData, stream, (void*) bufferElemData);
    }

    messageClose(stream);
  }
}
