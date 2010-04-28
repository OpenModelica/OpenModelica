#include <iostream>
#include "thread.h"

/* Windows and mingw32 */
#if defined(__MINGW32__) || defined(_MSC_VER)

#include <stdexcept>

void delay(unsigned milliseconds)
{
  Sleep(milliseconds);
}

Thread::Thread()
	: thread_handle(NULL)
{
}

Thread::~Thread()
{
	CloseHandle(thread_handle);
}

bool Thread::Create(THREAD_RET_TYPE (*func)(THREAD_PARAM_TYPE))
{
	thread_handle = CreateThread(NULL, 0, *func, NULL, 0, NULL);
	return thread_handle != NULL;
}

bool Thread::Join()
{
	return WaitForSingleObject(thread_handle, INFINITE) != WAIT_FAILED;
}


Mutex::Mutex()
{
	mutex_handle = CreateMutex(
			NULL, 								// default security attributes
			FALSE, 								// initially not owned
			NULL);								// unnamed mutex

	if(mutex_handle == NULL)
	{
		throw std::runtime_error("CreateMutex error: " + GetLastError());
	}
}

Mutex::~Mutex()
{
	CloseHandle(mutex_handle);
}

bool Mutex::Lock()
{
	return WaitForSingleObject(mutex_handle, INFINITE) != WAIT_FAILED;
}

bool Mutex::Unlock()
{
	return ReleaseMutex(mutex_handle);
}


struct Semaphore::Impl
{
};

Semaphore::Semaphore(unsigned initial_count, unsigned max_count)
{
	semaphore_handle = CreateSemaphore(NULL, initial_count, max_count, NULL);
}

Semaphore::~Semaphore()
{
	CloseHandle(semaphore_handle);
}

bool Semaphore::Wait()
{
	return WaitForSingleObject(semaphore_handle, INFINITE) != WAIT_FAILED;
}

bool Semaphore::TryWait()
{
	return WaitForSingleObject(semaphore_handle, 0) == WAIT_OBJECT_0; 
}

bool Semaphore::Post()
{
	return ReleaseSemaphore(semaphore_handle, 1, NULL);
}

bool Semaphore::Post(unsigned count)
{
	return ReleaseSemaphore(semaphore_handle, count, NULL);
}

/* Linux and other POSIX-compliant platforms */
#else

void delay(unsigned milliseconds)
{
  usleep(milliseconds * 1000);
}

Thread::Thread()
{
}

Thread::~Thread()
{
	pthread_exit(NULL);
}

bool Thread::Create(THREAD_RET_TYPE (*func)(THREAD_PARAM_TYPE))
{
	return pthread_create(&thread_handle, NULL, func, NULL) == 0;
}

bool Thread::Join()
{
	return pthread_join(thread_handle, NULL) == 0;
}


Mutex::Mutex()
{
	pthread_mutex_init(&mutex_handle, NULL);	
}

Mutex::~Mutex()
{
	pthread_mutex_destroy(&mutex_handle);
}

bool Mutex::Lock()
{
	return pthread_mutex_lock(&mutex_handle) == 0;
}

bool Mutex::Unlock()
{
	return pthread_mutex_unlock(&mutex_handle) == 0;
}


struct Semaphore::Impl
{
	Impl(unsigned max_count) : max_count(max_count) {}
	Mutex mutex;
	unsigned max_count;
};

Semaphore::Semaphore(unsigned initial_count, unsigned max_count)
	: impl(new Impl(max_count))
{
	sem_init(&semaphore_handle, 0, initial_count);
}

Semaphore::~Semaphore()
{
	sem_destroy(&semaphore_handle);
	delete impl;
}

bool Semaphore::Wait()
{
	return sem_wait(&semaphore_handle) == 0;
}

bool Semaphore::TryWait()
{
	return sem_trywait(&semaphore_handle) == 0;	
}

bool Semaphore::Post()
{
	impl->mutex.Lock();

	int sem_val;
	bool success = false;

	if(sem_getvalue(&semaphore_handle, &sem_val) == 0 && 
			sem_val < impl->max_count)
	{
		success = (sem_post(&semaphore_handle) == 0);
	}
	
	impl->mutex.Unlock();
	return success;
}

bool Semaphore::Post(unsigned count)
{
	impl->mutex.Lock();

	int sem_val;

	if(sem_getvalue(&semaphore_handle, &sem_val) != 0)
	{
		impl->mutex.Unlock();
		return false;
	}

	bool success = true;
	for(int i = 0; i < count; ++i)
	{
		if(!(sem_val + i < impl->max_count && sem_post(&semaphore_handle) == 0))
		{
			success = false;
			break;
		}
	}

	impl->mutex.Unlock();
	return success;
}

#endif
