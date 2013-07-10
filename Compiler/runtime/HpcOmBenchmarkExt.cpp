//#include <iostream>
//#include <omp.h>
//
//#ifdef WIN32
//#include <windows.h>
//#endif
//
//#define THREAD_NUM 2
//#define REPLICATIONS 10000
//#define WARMUP 10000
//
//#define PACKAGE_SIZE_BIG 128
//#define PACKAGE_SIZE_SMALL 1
//
//int itemCount = 0;
//double items[PACKAGE_SIZE_BIG];
//unsigned long long comTimes[REPLICATIONS];
//
//inline volatile long long RDTSC() {
//   register long long TSC asm("eax");
//   asm volatile (".byte 15, 49" : : : "eax", "edx");
//   return TSC;
//}

/**
 * Approximate the required time for operations (mult,add).
 * result: 2-parameters (m,n) y=mx+n
 */
void* HpcOmBenchmarkExtImpl__requiredTimeForOp()
{
//	unsigned long long calcTimesMul[REPLICATIONS];
//	unsigned long long calcTimesAdd[REPLICATIONS];
//	unsigned int sumCalc = 0;
//	void *res = mk_nil();
//
//	//warmup
//	for (int i = 0; i < REPLICATIONS; i++)
//	{
//		double last = 1234.123 + i;
//		last = last * 3.6424;
//	}
//
//	//bench mul
//	for (int i = 0; i < REPLICATIONS; i++)
//	{
//		double last = 1234.123 + i;
//		unsigned long long t1 = RDTSC();
//		double res = last * 3.6424;
//		unsigned long long t2 = RDTSC();
//		calcTimesMul[i] = (t2-t1);
//	}
//
//	//bench add
//	for (int i = 0; i < REPLICATIONS; i++)
//	{
//		double last = 1234.123 + i;
//		unsigned long long t1 = RDTSC();
//		double res = last + 3.6424;
//		unsigned long long t2 = RDTSC();
//		calcTimesAdd[i] = (t2-t1);
//	}
//
//	for (int i = 0; i < REPLICATIONS; i++)
//	{
//		sumCalc += calcTimesAdd[i];
//		sumCalc += calcTimesMul[i];
//	}
//
//	int m = 1;
//	res = mk_cons(mk_icon((sumCalc/(REPLICATIONS*2))),res); //push n
//	res = mk_cons(mk_icon(m),res); //push m
	void *res = mk_nil();
	res = mk_cons(mk_icon(24),res); //push n
	res = mk_cons(mk_icon(1),res); //push m
	return res;
}

//void sendMessage (int warmUp, int replications, int packageSize)
//{
//	for (int i = 0; i < warmUp; i++)
//	{
//		for(int j=0; j < packageSize; j++)
//		{
//			items[j] = 672364.8897+i+j;
//		}
//		itemCount++;
//		while(itemCount > 0);
//	}
//
//	for (int i = 0; i < replications; i++)
//	{
//		for(int j=0; j < packageSize; j++)
//		{
//			items[j] = 672364.8897+i+j;
//		}
//		itemCount++;
//		unsigned long long t1 = RDTSC();
//		while(itemCount > 0);
//		unsigned long long t2 = RDTSC();
//		comTimes[i] = (t2-t1);
//	}
//}
//
//void waitForMessage(int warmUp, int replications, int packageSize)
//{
//	double last[packageSize];
//
//	for (int i = 0; i < warmUp; i++)
//	{
//		while(itemCount == 0);
//		for(int j=0; j < packageSize; j++)
//		{
//			last[j] = items[j];
//		}
//		itemCount--;
//	}
//
//	for (int i = 0; i < replications; i++)
//	{
//		while(itemCount == 0);
//		for(int j=0; j < packageSize; j++)
//		{
//			last[j] = items[j];
//		}
//		itemCount--;
//	}
//}

/**
 * Approximate the required time to send doubles to another cpu.
 * result: 2-parameters (m,n) y=mx+n
 */
void* HpcOmBenchmarkExtImpl__requiredTimeForComm()
{
//	void *res = mk_nil();
//	unsigned int sumComSmall = 0;
//	unsigned int sumComBig = 0;
//
//	omp_set_num_threads(THREAD_NUM);
//	omp_set_dynamic(0);
//
//	//Benchmark for small package
//	#pragma omp parallel for shared(items) shared(itemCount)
//	for (int i=0; i < THREAD_NUM; i++)
//	{
//		if((i % 2) == 0)
//		{
//#ifdef WIN32
//			DWORD_PTR mask = (1 << omp_get_thread_num());
//			SetThreadAffinityMask( GetCurrentThread(), mask );
//			SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
//#endif
//			sendMessage(WARMUP,REPLICATIONS, PACKAGE_SIZE_SMALL);
//		}
//		else
//		{
//#ifdef WIN32
//			DWORD_PTR mask = (1 << omp_get_thread_num());
//			SetThreadAffinityMask( GetCurrentThread(), mask );
//			SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
//#endif
//			waitForMessage(WARMUP,REPLICATIONS, PACKAGE_SIZE_SMALL);
//		}
//	}
//
//	for (int i = 0; i < REPLICATIONS; i++)
//		sumComSmall += comTimes[i];
//
//	//Benchmark for big package
//	#pragma omp parallel for shared(items) shared(itemCount)
//	for (int i=0; i < THREAD_NUM; i++)
//	{
//		if((i % 2) == 0)
//		{
//#ifdef WIN32
//			DWORD_PTR mask = (1 << omp_get_thread_num());
//			SetThreadAffinityMask( GetCurrentThread(), mask );
//			SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
//#endif
//			sendMessage(WARMUP,REPLICATIONS, PACKAGE_SIZE_BIG);
//		}
//		else
//		{
//#ifdef WIN32
//			DWORD_PTR mask = (1 << omp_get_thread_num());
//			SetThreadAffinityMask( GetCurrentThread(), mask );
//			SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
//#endif
//			waitForMessage(WARMUP,REPLICATIONS, PACKAGE_SIZE_BIG);
//		}
//	}
//
//	for (int i = 0; i < REPLICATIONS; i++)
//		sumComBig += comTimes[i];
//
//	res = mk_cons(mk_icon(sumComSmall/(REPLICATIONS*2)),res); //push n
//	res = mk_cons(mk_icon((sumComBig-sumComSmall)/((PACKAGE_SIZE_BIG-PACKAGE_SIZE_SMALL)*(REPLICATIONS*2))),res); //push m
	void *res = mk_nil();
	res = mk_cons(mk_icon(70),res); //push n
	res = mk_cons(mk_icon(4),res); //push m
	return res;
}
