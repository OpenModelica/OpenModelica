
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/SimController/threading/Communicator.h>
#include <Core/SimController/threading/ToZeroMQEvent.h>
#include <Core/SimController/threading/SimulationThread.h>
#include <Core/SimController/threading/ProgressThread.h>

Communicator::Communicator()
    :_pause_delay(0.0)
    , _paused(false)
    , _end_time(1.0)
    , _simstopped(true)
   ,_guistopped(true)
    , _stop(false)
    ,_isInitialized(false)
{
    
}


/**
Destruktor
*/
Communicator::~Communicator()
{
    



}

 void Communicator::initialize(int pubPort, int subPort, string zeroMQJobiID, string zeroMQServerID, string zeroMQClientID)
{
     try
     {


         _notify = shared_ptr<INotify>(new ToZeroMQEvent( pubPort,  subPort, zeroMQJobiID, zeroMQServerID, zeroMQClientID));


     }
     catch (std::exception & ex)
     {

         std::string error(ex.what());

     }
     _isInitialized = true;
}
/**
Waits for all threads to end.
\param timeout in seconds in which a deadlock is assumed and the simulation will be terminated
\ret returns whether the simulation has ended.
*/
bool Communicator::waitForAllThreads(int timeout)
{
    waitForAllThreadsStarted(timeout);
    bool finish = true;
    std::unique_lock<std::mutex> lock(_stopsim_monitor);
    while (!(finish = isStoped()))
    {
        if (finish = (_simulation_finish.wait_for(lock, std::chrono::seconds(timeout)) == std::cv_status::timeout))
        {
            cout << "time out in waitForAllThreads " << std::endl;
            break;
        }
    }
    return finish;

}

bool Communicator::waitForSimulationStarting(int timeout)
{
    std::lock_guard<std::mutex> lockGuard(_mutex);
    try
    {
        _notify->NotifyWaitForStarting();
        return true;
    }
    catch (std::exception& ex)
    {
        return false;
    }
}

/**
Waits for all threads to start.
\param timeout  Time in seconds in which a deadlock is assumed and the waiting is to be ended.
\ret Indicates whether the simulation has ended.
*/
bool Communicator::waitForAllThreadsStarted(int timeout)
{
    bool started=false;
    //std::scoped_lock<mutex> lock(_startsim_monitor);
    std::unique_lock<std::mutex> lock(_startsim_monitor);
    while (started = !(isStarted()))
    {
        if ((_simulation_finish.wait_for(lock, std::chrono::seconds(timeout))==std::cv_status::timeout))
        {
            cout << "time out in waitForAllThreadsStarted " << std::endl;
            break;
        }
    }
   return started;

}

/**
* Starts the threads if not already done
* \ret returns whether the threads could be started.
*/
bool Communicator::startThreads(shared_ptr<SimManager> simManager, shared_ptr<IGlobalSettings> global_settings, shared_ptr<IMixedSystem> system, shared_ptr<ISimObjects> sim_objects, string modelKey)
{
  
  
    //If the simulation is not running
    if (isStoped())
    {
        _end_time = global_settings->getEndTime();
        shared_ptr<IWriteOutput> writeoutput_system = dynamic_pointer_cast<IWriteOutput>(system);
       
       
        _history = writeoutput_system->getHistory();

        shared_ptr < SimulationThread> sim_thread = shared_ptr < SimulationThread>(new SimulationThread(this));
        _sim_thread = sim_thread;
        _simulation = std::thread(&SimulationThread::Run, sim_thread, simManager, global_settings, system, sim_objects, modelKey);
        _simulation.detach();
       shared_ptr < ProgressThread> progress_thread = shared_ptr < ProgressThread>(new ProgressThread(this));
        _progress = std::thread(&ProgressThread::Run, progress_thread);
        _progress.detach();
        return true;

    }   
    else
    {

        return false;
    }
}
/**
Indicates the threads to s themselves
*/
void Communicator::stopThreads()
{

    std::lock_guard<std::mutex> lockGuard(_mutex);
    _sim_thread->Stop();


}
bool Communicator::waitForResults(double& time)
{
 
    if (_history)
    {
       
        time = _history->waitForResults();
    }
    std::lock_guard<std::mutex> lockGuard(_mutex);
    return _stop;

}
bool Communicator::shouldStop()
{
    std::lock_guard<std::mutex> lockGuard(_mutex);
    bool user_stop = _notify->AskForStop();
    return user_stop;

}
/**
signals new results are available
*/
void Communicator::notifyResults(double time)
{
    std::lock_guard<std::mutex> lockGuard(_mutex);
    //cout << "end time: " << _end_time << " time: " << time << std::endl;
    _notify->NotifyResults((time/_end_time)*100);
}


/**
Indicates   simulation thread is finished
*/
void Communicator::setSimStoped(bool success, string erro_message)
{
    std::lock_guard<std::mutex> lockGuard(_mutex);
    //cout << "sim stoped" << std::endl;
    _paused = false;
    _simstopped = true;
    _stop = true;
    _notify->NotifyFinish(success,erro_message);
    _simulation_finish.notify_all();
}
/**
Indicates  simulation thread is to be started
*/
void Communicator::setSimStarted()
{
    std::lock_guard<std::mutex> lockGuard(_mutex);
    //cout << "sim started" << std::endl;
    _simstopped = false;
    _notify->NotifyStarted();
    _simulation_finish.notify_all();
}
/**
Pauses the simulation
*/
void Communicator::startPause()
{
    if (!isStoped())
    {
   //not yet implemented
    }

}
/**
Stop the simulation pause
*/
void Communicator::stopPause()
{

    if (_paused)
    {


    }

}

/**
Indicates  simulation thread is finished
*/
void Communicator::setSimStopedByException(std::exception& except)
{


    std::lock_guard<std::mutex> lockGuard(_mutex);
    //cout << "sim stoped" << std::endl;
    _paused = false;
    _simstopped = true;
    _stop = true;

    if (_notify)
        _notify->NotifyException(except.what());

    _simulation_finish.notify_all();

}
/**
Indicates when progress thread is started
*/
void Communicator::setGuiStarted()
{
    std::lock_guard<std::mutex> lockGuard(_mutex);
   // cout << "gui started" << std::endl;
    _guistopped = false;
    _simulation_finish.notify_all();
}
/**
Indicates when progress thread is finished
*/
void Communicator::setGuiStoped()
{
    std::lock_guard<std::mutex> lockGuard(_mutex);
    //cout << "gui stoped" << std::endl;
    _guistopped = true;
   
    _simulation_finish.notify_all();

}

/**
Shows if simulation is finished
*/
bool Communicator::isStoped()
{
    std::lock_guard<std::mutex> lockGuard(_mutex);
    bool stopped;
    stopped = (_guistopped && _simstopped);
    //cout << "IsStoped " << std::endl;
    return stopped;

}
/**
Shows if simulation is started
*/
bool Communicator::isStarted()
{
    std::lock_guard<std::mutex> lockGuard(_mutex);
    //cout << "Is started: gui " << !_guistopped << " sim " << !_simstopped << std::endl;
    bool started;
    started = (!_guistopped && !_simstopped);
    return started;

}
