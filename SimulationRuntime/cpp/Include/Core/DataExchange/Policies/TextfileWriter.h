#pragma once

#ifdef ANALYZATION_MODE
#include <sstream>
#include <vector>
#endif

// Output
#include <fstream>
using std::ios;
#define SEPERATOR ","
#define EXTENSION ","
/**
Policy class to write simulation results in a text file
*/
template <unsigned long dim_1,unsigned long dim_2,unsigned long dim_3>
struct TextFileWriter
{
public:
typedef ublas::vector<double, ublas::bounded_array<double,dim_1> > value_type_v;
typedef ublas::vector<double, ublas::bounded_array<double,dim_2> > value_type_dv;
  TextFileWriter(unsigned long size,string output_path,string file_name)
    :_curser_position(0)
    ,_file_name(file_name)
    ,_output_path(output_path)
  {
   
   
   
    
  }
  ~TextFileWriter()
  {
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


  void write(const std::vector<std::string>& s_list)
  {
    std::string s;
    _output_stream<<"\"time\""<<SEPERATOR;

    for(std::vector<std::string>::const_iterator it = s_list.begin(); it != s_list.end(); ++it)
      _output_stream<<"\""<<(*it)<<"\""<<SEPERATOR;

//    BOOST_FOREACH(s, s_list)
//    {
//      _output_stream<<"\""<<s<<"\""<<SEPERATOR;
//
//    }

    _output_stream<<std::endl;

  }

  void write(const char c)
  {
    _output_stream<<c;
  }

  void write(const value_type_v& v_list,const value_type_dv& v2_list,double time)
  {
    _output_stream<<time<<SEPERATOR;
    double v,v2;

    for(typename value_type_v::const_iterator it = v_list.begin(); it != v_list.end(); ++it)
      _output_stream<<(*it)<<SEPERATOR;

    for(typename value_type_dv::const_iterator it = v2_list.begin(); it != v2_list.end(); ++it)
      _output_stream<<(*it)<<SEPERATOR;

//    BOOST_FOREACH(v, v_list)
//    {
//      _output_stream<<v<<SEPERATOR;
//    }
//    BOOST_FOREACH(v2, v2_list)
//    {
//      _output_stream<<v2<<SEPERATOR;
//    }

    _output_stream<<std::endl;
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
  std::fstream _output_stream;
  unsigned int    _curser_position;       ///< Controls current Curser-Position
  std::string _output_path;
  std::string _file_name;

};
