/*
 * busywaitingbarrier.hpp
 *
 *  Created on: 03.11.2014
 *      Author: marcus
 */

#ifndef BUSYWAITINGBARRIER_HPP_
#define BUSYWAITINGBARRIER_HPP_

#ifdef USE_THREAD
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

VAR_ALIGN_PRE class alignedLock
{
  private:
    mutex _lock;
  public:
    alignedLock() : _lock() {}

    ~alignedLock() {}

    void* operator new(size_t size)
    {
       //see: http://stackoverflow.com/questions/12504776/aligned-malloc-in-c
       void *p1;
       void **p2;
       size_t alignment = 64;
       int offset=alignment - 1 + sizeof(void*);
       p1 = malloc(size + offset);
       p2=(void**)(((size_t)(p1)+offset)&~(alignment-1));
       p2[-1]=p1; //line 6

       if(((size_t)p2) % 64 != 0)
          throw std::runtime_error("Memory was not aligned correctly!");

       return p2;
    }
    void operator delete(void *p)
    {
       void* p1 = ((void**)p)[-1];         // get the pointer to the buffer we allocated
       free( p1 );
    }

    FORCE_INLINE void lock()
    {
        _lock.lock();
    }

    FORCE_INLINE void unlock()
    {
        _lock.unlock();
    }
} VAR_ALIGN_POST;

VAR_ALIGN_PRE class alignedSpinlock
{
    volatile bool locked;
  public:
    alignedSpinlock() : locked(false) {}

    ~alignedSpinlock() {}

    void* operator new(size_t size)
    {
       //see: http://stackoverflow.com/questions/12504776/aligned-malloc-in-c
       void *p1;
       void **p2;
       size_t alignment = 64;
       int offset=alignment - 1 + sizeof(void*);
       p1 = malloc(size + offset);
       p2=(void**)(((size_t)(p1)+offset)&~(alignment-1));
       p2[-1]=p1; //line 6

       if(((size_t)p2) % 64 != 0)
          throw std::runtime_error("Memory was not alligned correctly!");

       return p2;
    }
    void operator delete(void *p)
    {
       void* p1 = ((void**)p)[-1];         // get the pointer to the buffer we allocated
       free( p1 );
    }

    FORCE_INLINE void lock()
    {
        while(locked) {}
        locked = true;
    }

    FORCE_INLINE void unlock()
    {
        locked = false;
    }
} VAR_ALIGN_POST;

class busywaiting_barrier
{
  public:
    busywaiting_barrier(int counterValueMax) : counterValue(counterValueMax), counterValueRelease(0), ready(true), counterValueMax(counterValueMax) {}
    ~busywaiting_barrier() {}

    FORCE_INLINE void wait()
    {
        //std::cerr << "entering wait function (counterValueMax: " << counterValueMax << ")" << std::endl;
        while(!ready) {}

        bool reset = (counterValue.fetch_sub(1,memory_order_release ) == 1); //decrement counter value
        if(reset)
        {
            //std::cerr << "ready state set to false (counterValueMax: " << counterValueMax << ")" << std::endl;
            ready = false;
        }

        //std::cerr << "counter decremented (counterValueMax: " << counterValueMax << ")" << std::endl;

        while(counterValue.load(memory_order_relaxed) > 0)
        {
            //int val = counterValue.load(memory_order_seq_cst );
            //std::cerr << "waiting because counter value is " << val << " (counterValueMax: " << counterValueMax << ")" << std::endl;
            //sleep(1);
        }

        //std::cerr << "leaving wait function (counterValueMax: " << counterValueMax << ")" << std::endl;

        if(counterValueRelease.fetch_add(1,memory_order_release) == counterValueMax-1)
        {
            counterValue.store(counterValueMax, memory_order_release);
            counterValueRelease.store(0, memory_order_release);
            ready = true;

            //std::cerr << "set ready to true (counterValueMax: " << counterValueMax << ")" << std::endl;
        }

        //while(counterValueRelease.load(memory_order_acquire ) > 0) {}
        while(counterValueRelease.load(memory_order_relaxed ) > 0) {}
    }

  private:
    atomic<int> counterValue;
    atomic<int> counterValueRelease;
    volatile bool ready;
    int counterValueMax;
};

class semaphore {
  private:
    mutex mtx;
    condition_variable cv;
    int count;

  public:
    semaphore (int count = 0)
        : count(count) {}

    inline void post()
    {
        unique_lock<mutex> lock(mtx);
        count++;
        cv.notify_one();
    }

    inline void wait()
    {
        unique_lock<mutex> lock(mtx);

        while(count == 0){
            cv.wait(lock);
        }
        count--;
    }
};

#endif //USE_THREAD

#endif /* BUSYWAITINGBARRIER_HPP_ */
