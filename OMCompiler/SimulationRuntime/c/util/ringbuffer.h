/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#ifndef _RINGBUFFER_H_
#define _RINGBUFFER_H_

/*
 * This is an expanding ring buffer.
 * When it gets full, it doubles in size.
 * It's basically a queue which has get(ix) instead of get_first()/delete_first().
 */

#ifdef __cplusplus
extern "C" {
#endif

  struct RINGBUFFER;
  typedef struct RINGBUFFER RINGBUFFER;

  RINGBUFFER *allocRingBuffer(int bufferSize, int itemSize);
  void freeRingBuffer(RINGBUFFER *rb);

  void *getRingData(RINGBUFFER *rb, int nIndex);

  void appendRingData(RINGBUFFER *rb, void *value);
  void dequeueNFirstRingDatas(RINGBUFFER *rb, int n);
  void removeLastRingData(RINGBUFFER *rb, int n);

  int ringBufferLength(RINGBUFFER *rb);

  void rotateRingBuffer(RINGBUFFER *rb, int n);
  void lookupRingBuffer(RINGBUFFER *rb, void **lookup);

  void infoRingBuffer(RINGBUFFER *rb, int stream);

  void printRingBuffer(RINGBUFFER *rb, int stream, void (*printDataFunc)(void*,int,void*));
#ifdef __cplusplus
}
#endif

#endif
