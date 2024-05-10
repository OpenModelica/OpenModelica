#if defined(__APPLE_CC__)
#include <libkern/OSAtomic.h>
#define pthread_spin_init(X,UNUSEDNULL) (*(X) = OS_SPINLOCK_INIT)
#define pthread_spin_lock OSSpinLockLock
#define pthread_spinlock_t OSSpinLock
#define pthread_spin_unlock OSSpinLockUnlock
#else
#include <pthread.h>
#endif