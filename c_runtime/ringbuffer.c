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

#include "ringbuffer.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>

void allocRingBuffer(RINGBUFFER* rb, int sz, int item_size)
{
	rb->first_element = 0;
	rb->num_element = 0;
	rb->buf_size = (sz > 0) ? sz : 1;
	rb->item_size = item_size;
	rb->buffer = calloc(rb->buf_size, rb->item_size);
	assert(rb->buffer);
}

void freeRingBuffer(RINGBUFFER* rb)
{
	free(rb->buffer);
}

void* getRingData(RINGBUFFER* rb, int nIndex)
{
	assert(nIndex < rb->num_element);
	assert(0 <= nIndex);
	return ((char*)rb->buffer)+(((rb->first_element+nIndex)%rb->buf_size)*rb->item_size);
}

static void expandRingBuffer(RINGBUFFER* rb)
{
	int i;
	void* temp = calloc(2*rb->buf_size, rb->item_size);
	assert(temp);

	for(i=0; i<rb->num_element; i++) {
		memcpy(((char*)temp)+(i*rb->item_size), getRingData(rb, i), rb->item_size);
	}

	free(rb->buffer);
	rb->buffer = temp;
	rb->buf_size *= 2;
	rb->first_element = 0;
}

void appendRingData(RINGBUFFER* rb, void* value)
{
	if(rb->buf_size < (rb->num_element+1)) {
		expandRingBuffer(rb);
	}

	memcpy(((char*)rb->buffer)+(((rb->first_element+rb->num_element)%rb->buf_size)*rb->item_size), value, rb->item_size);
	++rb->num_element;
}

void dequeueNFirstRingDatas(RINGBUFFER* rb, int n)
{
	assert(n <= rb->num_element);
	assert(0 <= n);
	rb->first_element = (rb->first_element+n)%rb->buf_size;
	rb->num_element -= n;
}

int ringBufferLength(const RINGBUFFER* rb)
{
	return rb->num_element;
}
