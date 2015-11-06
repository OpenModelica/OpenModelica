#pragma once
/** @addtogroup dataexchange

 *
 *  @{
 */
#include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>

#define CONTAINER_COUNT 3

/**
 * This container manager is designed to write simulation results in parallel. It has multiple data containers that
 * can be filled with values. The write routine works asynchronously with the help of a consumer-producer-queue.
 */
class ParallelContainerManager : public Writer
{
  private:
    deque<write_data_t > _writeContainers;
    deque<write_data_t > _freeContainers;
    semaphore _freeContainerMutex;
    semaphore _writeContainerMutex;
    semaphore _nempty;
    thread _writerThread;
    bool _threadWorkDone;

  protected:
    void writeThread()
    {
      std::cerr << "Parallel writer thread used" << std::endl;
      while(!_threadWorkDone)
        writeContainer();

      while(!_writeContainers.empty())
        writeContainer();
    }

    void writeContainer()
    {
      const write_data_t* container;

      _writeContainerMutex.wait();
      if (!_writeContainers.empty())
        container = &_writeContainers.front();

      _writeContainerMutex.post();

      if (!container)
      {
        usleep(5);
        return;
      }

      write(get<0>(*container),get<1>(*container));

      _writeContainerMutex.wait();
      _writeContainers.pop_front();
      _writeContainerMutex.post();

      _freeContainerMutex.wait();
      _freeContainers.push_back(*container);
      _freeContainerMutex.post();
      _nempty.post();
    }

  public:
    ParallelContainerManager() : Writer()
      , _writeContainers()
      ,_freeContainers()
      ,_freeContainerMutex(1)
      ,_writeContainerMutex(1)
      ,_nempty(CONTAINER_COUNT)
      ,_writerThread(&ParallelContainerManager::writeThread, this)
      ,_threadWorkDone(false)
    {
    }

    virtual ~ParallelContainerManager()
    {
      _threadWorkDone = true;
      _writerThread.join();
    }

    virtual write_data_t& getFreeContainer()
    {
      _nempty.wait();
      _freeContainerMutex.wait();

       write_data_t& container = _freeContainers.front();
      _freeContainers.pop_front();
      _freeContainerMutex.post();

      return container;
  };

  virtual void addContainerToWriteQueue(const write_data_t& container)
  {
    _writeContainers.push_back(container);
  };
};
/** @} */ // end of dataexchange
