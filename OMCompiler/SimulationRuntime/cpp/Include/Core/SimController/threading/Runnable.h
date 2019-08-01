#pragma once




/**
Basis-Klasse für alle Threads
*/
class Runnable
{
public:
    Runnable() : running(true) {}

    virtual void Stop() = 0;
    
protected:
   

  
    bool running;
};





