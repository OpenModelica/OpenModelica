#include <windows.h>
#include <process.h>
#include <iostream>

#ifndef __OPC_EVENT_H__
#define __OPC_EVENT_H__

class Event
{
public:
	Event()
	{
		// start in non-signaled state (red light)
		// auto reset after every Wait
		event_handle = CreateEvent(0, FALSE, FALSE, 0);
	}

	~Event()
	{
		CloseHandle(event_handle);
	}

	// put into signaled state
	void Release()
	{
		SetEvent(event_handle);
	}

	void Wait()
	{
		// Wait until event is in signaled (green) state
		WaitForSingleObject(event_handle, INFINITE);
	}

	operator HANDLE ()
	{
		return event_handle;
	}

private:
	HANDLE event_handle;
};

#endif /* __OPC_EVENT_H__ */
