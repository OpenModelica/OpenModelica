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
