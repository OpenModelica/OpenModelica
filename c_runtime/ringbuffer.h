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

#ifndef RINGBUFFER_H
#define RINGBUFFER_H

template<typename T>

/*
 * This is an expanding ring buffer.
 * When it gets full, it doubles in size.
 * It's basically a queue which has get(ix) instead of get_first()/delete_first().
 */

class ringbuffer { 
private:

  T* buffer;
  int first_element;
  int num_element;
  int buf_size;

  T& fast_get(const int nIndex) {
    return buffer[(first_element+nIndex)%buf_size];
  }

  void expand_buffer() {
    T* nb = new T[buf_size*2];
    for (int i=0; i<num_element; i++)
      nb[i] = fast_get(i);
    delete buffer;
    buffer = nb;
    buf_size *= 2;
    // fprintf(stderr, "expanded to sz %d\n", buf_size);
  }

public:
  ringbuffer(int sz) : first_element(0),num_element(0),buf_size(sz) {
    buffer = new T[buf_size];
  }

  ~ringbuffer() {}

  void append(T value) {
    if (buf_size < num_element+1)
      expand_buffer();
    buffer[(first_element+num_element)%buf_size] = value;
    ++num_element;
  }

  T& operator[] (const int nIndex) {
    assert(nIndex < num_element);
    return fast_get(nIndex);
  }

  void dequeue_n_first(const int n) {
    assert(n <= num_element);
    first_element = (first_element+n)%buf_size;
    num_element -= n;
  }

  T& get(const int nIndex) {
    assert(nIndex < num_element);
    return fast_get(nIndex);
  }

  int length() {
    return num_element;
  }
};

#endif
