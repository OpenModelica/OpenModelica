#ifndef THREAD_H
#define THREAD_H 

#if defined(__MINGW32__) || defined(_MSC_VER)
	#include <windows.h>

	#define THREAD_RET_TYPE DWORD WINAPI
	typedef LPVOID THREAD_PARAM_TYPE;

	typedef HANDLE MUTEX_HANDLE;
	typedef HANDLE THREAD_HANDLE;
	typedef HANDLE SEMAPHORE_HANDLE;

#else
	#include <pthread.h>
	#include <semaphore.h>

	typedef void* THREAD_RET_TYPE;
	typedef void* THREAD_PARAM_TYPE;

	typedef pthread_mutex_t MUTEX_HANDLE;
	typedef pthread_t THREAD_HANDLE;
	typedef sem_t SEMAPHORE_HANDLE;
#endif

/**
 * Puts the current thread to sleep for the specified amount of milliseconds.
 */ 
void delay(unsigned milliseconds);

class Thread
{
	public:
		Thread();
		~Thread();
		bool Create(THREAD_RET_TYPE (*func)(THREAD_PARAM_TYPE));

		bool Join();

	private: // Not copyable
		Thread(const Thread&);
		Thread& operator= (const Thread&);

	private:
		THREAD_HANDLE thread_handle;
};

class Mutex
{
	public:
		Mutex();
		~Mutex();

		bool Lock();
		bool Unlock();

	private: // Not copyable
		Mutex(const Mutex&);
		Mutex& operator= (const Mutex&);

	private:
		MUTEX_HANDLE mutex_handle;
};

class Semaphore
{
	struct Impl;

	public:
		Semaphore(unsigned initial_count, unsigned max_count);
		~Semaphore();

		bool Wait();
		bool TryWait();
		bool Post();
		bool Post(unsigned count);
		
	private:
		Semaphore(const Semaphore&);
		Semaphore& operator= (const Semaphore&);

	private:
		SEMAPHORE_HANDLE semaphore_handle;
		Impl *impl;
};

#endif /* THREAD_H */
