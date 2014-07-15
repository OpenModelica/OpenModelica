#pragma once

#ifdef ANALYZATION_MODE
#include <sstream>
#include <vector>
#endif

#ifdef USE_BOOST_THREAD
#include <boost/lockfree/queue.hpp>
#include <boost/tuple/tuple.hpp>
#include <boost/interprocess/sync/interprocess_semaphore.hpp>
#include <boost/thread.hpp>
#endif

// Output
#include <fstream>
using std::ios;
#define SEPERATOR ","
#define EXTENSION ","
/**
Policy class to write simulation results in a text file
*/
template <unsigned long dim_1,unsigned long dim_2,unsigned long dim_3,unsigned long dim_4>
struct TextFileWriter
{
 public:
   typedef ublas::vector<double, ublas::bounded_array<double,dim_1> > value_type_v;
   typedef ublas::vector<double, ublas::bounded_array<double,dim_2> > value_type_dv;
   typedef ublas::vector<double, ublas::bounded_array<double,dim_4> > value_type_p;

  TextFileWriter(unsigned long size,string output_path,string file_name)
    :_curser_position(0)
    ,_output_path(output_path)
    ,_file_name(file_name)
    #ifdef USE_BOOST_THREAD
      ,_queue(0)
      ,_mutex(1)
      ,_nempty(10)
      ,_nstored(0)
      ,_writerThread()
      ,_threadWorkDone(false)
      ,_threadRunning(false)
    #endif
  {
  }
  ~TextFileWriter()
  {
    #ifdef USE_BOOST_THREAD
      //wait until the writer-thread has written all results
      while(true)
      {
        _mutex.wait();
        if(_queue.size() == 0)
        {
          _mutex.post();
          break;
        }
        _mutex.post();
        sleep(1);
      }
      _threadWorkDone = true;
      _nempty.wait();
      _mutex.wait();
      _queue.push_back(new boost::tuple<value_type_v*,value_type_dv*,double>(0,0,0));
      _mutex.post();
      _nstored.post();

      _writerThread.join();
    #endif

    if(_output_stream.is_open())
     _output_stream.close();

  }
  void  init(std::string output_path,std::string file_name)
  {
      _file_name = file_name;
      _output_path = output_path;
      if(_output_stream.is_open())
          _output_stream.close();
      std::stringstream res_output_path;
      res_output_path <<   output_path  <<file_name;
      _output_stream.open(res_output_path.str().c_str(), ios::out);

  }
    void read(ublas::matrix<double>& R,ublas::matrix<double>& dR)
    {
        //not supported for file output

    }

    void read(ublas::matrix<double>& R,ublas::matrix<double>& dR,ublas::matrix<double>& Re)
    {
        //not supported for file output

    }

    void read(const double& time,ublas::vector<double>& dv,ublas::vector<double>& v)
    {
        //not supported for file output

    }
    void read(ublas::matrix<double>& R,std::vector<unsigned int>& indices)
    {
        //not supported for file output

    }


  /*writes pramater values to results file
    @v_list values of parameter
  @start_time
  @end_time
  */
   void write(const value_type_p& v_list,double start_time,double end_time)
   {

      //not supported for file output
   }


  /*
    writes header of results file with the variable names
  @s_list name of variables
  @s_desc_list description of variables
  @s_parameter_list name of parameter
  @s_desc_parameter_list description of parameter
  */
  void write(const std::vector<std::string>& s_list,const std::vector<std::string>& s_desc_list,const std::vector<std::string>& s_parameter_list,const std::vector<std::string>& s_desc_parameter_list)
  {

    std::string s;
    _output_stream<<"\"time\""<<SEPERATOR;

    for(std::vector<std::string>::const_iterator it = s_list.begin(); it != s_list.end(); ++it)
      _output_stream<<"\""<<(*it)<<"\""<<SEPERATOR;

    _output_stream<<std::endl;

  }

  void write(const char c)
  {
    _output_stream<<c;
  }
  /*
  writes simulation results for a time step
  @v_list variables and state vars
  @v2_list derivatives vars
  @time
  */
  void write(const value_type_v& v_list,const value_type_dv& v2_list,double time)
  {
    _output_stream<<time<<SEPERATOR;

    for(typename value_type_v::const_iterator it = v_list.begin(); it != v_list.end(); ++it)
      _output_stream<<(*it)<<SEPERATOR;

    for(typename value_type_dv::const_iterator it = v2_list.begin(); it != v2_list.end(); ++it)
      _output_stream<<(*it)<<SEPERATOR;

    _output_stream<<std::endl;
  }

  void write(value_type_v *v_list, value_type_dv *v2_list,double time)
  {
    #ifdef USE_BOOST_THREAD
      if(!_threadRunning)
      {
        _queue = std::deque<boost::tuple<value_type_v*, value_type_dv*, double>* >();
        _writerThread = boost::thread(&TextFileWriter::writeThread, this);
        _threadRunning = true;
      }

      _nempty.wait();
      _mutex.wait();
      _queue.push_back(new boost::tuple<value_type_v*, value_type_dv*,double>(v_list,v2_list,time));
      _mutex.post();
      _nstored.post();
    #else
      _output_stream<<time<<SEPERATOR;

      for(typename value_type_v::const_iterator it = v_list->begin(); it != v_list->end(); ++it)
        _output_stream<<(*it)<<SEPERATOR;

      for(typename value_type_dv::const_iterator it = v2_list->begin(); it != v2_list->end(); ++it)
        _output_stream<<(*it)<<SEPERATOR;

      _output_stream<<std::endl;

      delete v_list;
      delete v2_list;
    #endif
  }

  void getTime(std::vector<double>& time)
  {

    //not supported for file output

  }
  unsigned long size()
  {
    //not supported for file output
    return 0;
  }
  void eraseAll()
  {
      _curser_position=0;
    _output_stream.seekp(_curser_position);
  };

protected:
  void writeThread()
  {
    #ifdef USE_BOOST_THREAD
      boost::tuple<value_type_v*,value_type_dv*,double> *elem;
      value_type_v *v_list;
      value_type_dv *v2_list;
      double time;
      while(!_threadWorkDone)
      {
        _nstored.wait();

        if(_threadWorkDone)
        {
          _nempty.post();
          break;
        }
        elem = _queue.front();

        v_list = (value_type_v*)get<0>(*elem);
        v2_list = (value_type_dv*)get<1>(*elem);
        time = get<2>(*elem);

        _output_stream<<time<<SEPERATOR;

        for(typename value_type_v::const_iterator it = v_list->begin(); it != v_list->end(); ++it)
          _output_stream<<(*it)<<SEPERATOR;

        for(typename value_type_dv::const_iterator it = v2_list->begin(); it != v2_list->end(); ++it)
          _output_stream<<(*it)<<SEPERATOR;

        _output_stream<<std::endl;

        delete v_list;
        delete v2_list;

        _mutex.wait();
        _queue.pop_front();
        _mutex.post();
        _nempty.post();

        delete elem;
      }
    #endif
  }

  std::fstream _output_stream;
  unsigned int _curser_position;       ///< Controls current Curser-Position
  std::string _output_path;
  std::string _file_name;
  #ifdef USE_BOOST_THREAD
    std::deque<boost::tuple<value_type_v*, value_type_dv*, double>* > _queue;
    boost::interprocess::interprocess_semaphore _mutex;
    boost::interprocess::interprocess_semaphore _nempty;
    boost::interprocess::interprocess_semaphore _nstored;
    boost::thread _writerThread;
    bool _threadWorkDone;
    bool _threadRunning;
  #endif
};
