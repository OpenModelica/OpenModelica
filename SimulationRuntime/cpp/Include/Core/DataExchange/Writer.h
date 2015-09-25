#pragma once
/** @addtogroup dataexchange
*
*  @{
*/
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
#include <boost/lockfree/queue.hpp>
#include <boost/tuple/tuple.hpp>
#include <boost/interprocess/sync/interprocess_semaphore.hpp>
#include <boost/thread.hpp>
#endif

#define CONTAINER_COUNT 2



typedef boost::container::vector<string> var_names_t;
template<typename T>
struct SimulationOutput
{
	typedef boost::container::vector<const T*> values_t;

	var_names_t  parameterNames;
	var_names_t  parameterDescription;
	var_names_t  ourputVarNames;
	var_names_t  ourputVarDescription;
	values_t outputVars;
	values_t outputParams;

	void addParameter(string& name,string& description,const T* var)
	{
		parameterNames.push_back(name);
		parameterDescription.push_back(description);
		outputParams.push_back(var);
	}
	void addOutputVar(string& name,string& description,const T* var)
	{
		ourputVarNames.push_back(name);
		ourputVarDescription.push_back(description);
		outputVars.push_back(var);
	}
};

typedef SimulationOutput<int> output_int_vars_t;
typedef SimulationOutput<bool> output_bool_vars_t;
typedef SimulationOutput<double> output_real_vars_t;

typedef  output_int_vars_t::values_t   int_vars_t;
typedef  output_bool_vars_t::values_t  bool_vars_t;
typedef  output_real_vars_t::values_t  real_vars_t;
typedef  boost::tuple<real_vars_t,int_vars_t,bool_vars_t> all_vars_t;
typedef  boost::tuple<var_names_t,var_names_t,var_names_t> all_names_t;
typedef  boost::tuple<var_names_t,var_names_t,var_names_t> all_description_t;



class Writer
{
public:

	typedef boost::tuple<real_vars_t,
                         int_vars_t,
                         bool_vars_t,
                         double> values_type;
	Writer()
		: _writeContainers()
		,_freeContainers()
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		,_freeContainerMutex(1)
		,_writeContainerMutex(1)
		,_nempty(CONTAINER_COUNT)
		,_writerThread(&Writer::writeThread, this)
		,_threadWorkDone(false)
#endif
	{
		for (int i = 0; i < CONTAINER_COUNT; ++i)
		{
			 values_type vars = boost::make_tuple(real_vars_t(),int_vars_t(),bool_vars_t(),0.0);
			_freeContainers.push_back(vars);
		}
	}

	virtual ~Writer()
	{
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		//wait until the writer-thread has written all results
		_threadWorkDone = true;
		_writerThread.join();
#endif
	}

	virtual void write(const all_vars_t& v_list, double time) = 0;

	values_type& getFreeContainer()
	{

#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_nempty.wait();
		_freeContainerMutex.wait();
#endif
		 values_type& container = _freeContainers.front();
		_freeContainers.pop_front();
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_freeContainerMutex.post();
#endif
		return container;
	};

	void addContainerToWriteQueue(const values_type& container)
	{
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_writeContainerMutex.wait();
#endif
		_writeContainers.push_back(container);
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_writeContainerMutex.post();
#else
		writeContainer();
#endif
	};

protected:
	void writeContainer()
	{
		const values_type* container;

#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_writeContainerMutex.wait();
#endif
		if (!_writeContainers.empty())
        {
			const values_type& c = _writeContainers.front();
            container = &c;
        }
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_writeContainerMutex.post();
#endif

		if (!container)
		{
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
			usleep(1);
#endif
			return;
		}

		const real_vars_t& v_list = get<0>(*container);
		const int_vars_t& v2_list = get<1>(*container);
        const bool_vars_t& v3_list = get<2>(*container);
		double time = get<3>(*container);

		write(boost::make_tuple(v_list, v2_list, v3_list),time);

#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_writeContainerMutex.wait();
#endif
		_writeContainers.pop_front();
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_writeContainerMutex.post();
#endif

#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_freeContainerMutex.wait();
#endif
		_freeContainers.push_back(*container);
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		_freeContainerMutex.post();
		_nempty.post();
#endif
	}

	void writeThread()
	{
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
		std::cerr << "Parallel writer thread used" << std::endl;
		while(!_threadWorkDone)
		{
			writeContainer();
		}

		while(!_writeContainers.empty())
			writeContainer();
#endif
	}

	std::deque<values_type > _writeContainers;
	std::deque<values_type > _freeContainers;
#if defined USE_PARALLEL_OUTPUT && defined USE_BOOST_THREAD
	boost::interprocess::interprocess_semaphore _freeContainerMutex;
	boost::interprocess::interprocess_semaphore _writeContainerMutex;
	boost::interprocess::interprocess_semaphore _nempty;
	boost::thread _writerThread;
	bool _threadWorkDone;
#endif

};
/** @} */ // end of dataexchange