#pragma once

#include "textfilewriter.h"


template <unsigned long dim_1,unsigned long dim_2,unsigned long dim_3>
struct BufferReaderWriter
{
    //typedef TextFileWriter<dim_1,dim_2> TextwriterType;
public:
    BufferReaderWriter(unsigned long size,string output_folder)
  :_buffer_pos(0)
    {
  try
  {
      _variables_buffer.set_capacity(size+size/10);
      _derivatives_buffer.set_capacity(size+size/10);
      _residues_buffer.set_capacity(size+size/10);
      //textwriter = new TextwriterType(size,output_folder);
  }
  catch(std::exception& ex)
  {
      cout<<"allocating   buffers faild" << std::endl;
      throw ex;
  }
    }
    /**
    Reads all Simulation results (algebraic and state variables in R, derivatives in dR)
    Rij i variable index
    j number of time index
    */
    void read(ublas::matrix<double>& R,ublas::matrix<double>& dR)
    {
  try
  {
      ublas::matrix<double>::size_type  m = size();
      R.resize(dim_1,m);
      for(int i=0;i<m;++i)
          ublas::column(R,i)=_variables_buffer[i];
      dR.resize(dim_2,m);
      for(int i=0;i<m;++i)
          ublas::column(dR,i)=_derivatives_buffer[i];
  }
  catch(std::exception& ex)
  {
      cout<<"read  from  buffer faild" << std::endl;
      throw ex;
  }


    }

    void read(ublas::matrix<double>& R,ublas::matrix<double>& dR,ublas::matrix<double>& Re)
    {
  try
  {
      ublas::matrix<double>::size_type  m = size();
      R.resize(dim_1,m);
      for(int i=0;i<m;++i)
          ublas::column(R,i)=_variables_buffer[i];
      dR.resize(dim_2,m);
      for(int i=0;i<m;++i)
          ublas::column(dR,i)=_derivatives_buffer[i];
      Re.resize(dim_3,m);
      for(int i=0;i<m;++i)
          ublas::column(Re,i)=_residues_buffer[i];
  }
  catch(std::exception& ex)
  {
      cout<<"read  from  buffer faild" << std::endl;
      throw ex;
  }


    }

    void read(ublas::matrix<double>& R,vector<unsigned int>& indices)
    {
  ublas::matrix<double>::size_type m = size();
  ublas::matrix<double>::size_type n = indices.size();
  ublas::matrix<double>::size_type i,i2=0,j;
  try
  {


      R.resize(n,m);
  }
  catch(std::exception& ex)
  {
      cout<<"read  from variables buffer faild alloc R with sizes "<<m <<"," << n << std::endl;
      throw ex;
  }
   try
  {
      BOOST_FOREACH(i,indices)
      {
          for(j=0;j<m;++j)
              R(i2,j)=_variables_buffer[j][i];
          i2++;
      }
  }
  catch(std::exception& ex)
  {
      cout<<"read  from variables buffer faild" << std::endl;
      throw ex;
  }


    }

    void read(const double& time,ublas::vector<double>& dv,ublas::vector<double>& v)
    {

  std::map<double,unsigned long>::iterator iter;
  iter = find_if( _time_entries.begin(), _time_entries.end(), floatCompare<double>(time, 1e-10) );
  if(iter==_time_entries.end())
      throw std::runtime_error("getVariables: time parameters");
  v=_variables_buffer[iter->second];
  dv = _derivatives_buffer[iter->second];
    }

  void read(const double& time,ublas::vector<double>& r,ublas::vector<double>& dv,ublas::vector<double>& v)
    {

  std::map<double,unsigned long>::iterator iter;
  iter = find_if( _time_entries.begin(), _time_entries.end(), floatCompare<double>(time, 1e-10) );
  if(iter==_time_entries.end())
      throw std::runtime_error("getVariables: time parameters");
  v=_variables_buffer[iter->second];
  dv = _derivatives_buffer[iter->second];
  r = _residues_buffer[iter->second];
    }

    void write(const vector<string>& s)
    {

    }

    void write(const char c)
    {

    }

    void write(const ublas::vector<double>& v,const ublas::vector<double>& v2,double time)
    {
  try
  {
      std::pair<std::map<double, unsigned long>::iterator,bool> p;
      p = _time_entries.insert(make_pair(time,_buffer_pos));
      if(!p.second)//if variable and derivatives for time are already inserted, erease old values
      {
          _variables_buffer.pop_back();
          _derivatives_buffer.pop_back();
      }
      else
      {
          _buffer_pos++;
      }
      _variables_buffer.push_back(v);
      _derivatives_buffer.push_back(v2);
  }
  catch(std::exception& ex)
  {
      cout<<"write to buffer faild" << std::endl;
      throw ex;
  }

  // textwriter->write(v,v2, time);
    }

    void write(const ublas::vector<double>& v,const ublas::vector<double>& v2,const ublas::vector<double>& v3,double time)
    {
  try
  {
      std::pair<std::map<double, unsigned long>::iterator,bool> p;
      p = _time_entries.insert(make_pair(time,_buffer_pos));
      if(!p.second)//if variable and derivatives for time are already inserted, erease old values
      {
          _variables_buffer.pop_back();
          _derivatives_buffer.pop_back();
          _residues_buffer.pop_back();
      }
      else
      {
          _buffer_pos++;
      }
      _variables_buffer.push_back(v);
      _derivatives_buffer.push_back(v2);
      _residues_buffer.push_back(v3);
  }
  catch(std::exception& ex)
  {
      cout<<"write to buffer faild" << std::endl;
      throw ex;
  }

  // textwriter->write(v,v2, time);
    }

    void getTime(vector<double>& time)
    {
  try
  {
      std::pair<double,unsigned long> i;
      BOOST_FOREACH(i, _time_entries)
      {
          time.push_back(i.first);

      }
  }
  catch(std::exception& ex)
  {
      cout<<"read from time buffer faild" << std::endl;
      throw ex;
  }
    }
    unsigned long size()
    {
  try
  {
  return _time_entries.size();
  }
  catch(std::exception& ex)
  {
      cout<<"time entries size faild" << std::endl;
      throw ex;
  }
    }
    void eraseAll()
    {

  _variables_buffer.clear();
  _derivatives_buffer.clear();
  _residues_buffer.clear();
  _time_entries.clear();
  _buffer_pos=0;
  //textwriter->eraseAll();
    }

    typedef ublas::vector<double, ublas::bounded_array<double,dim_1> > value_type_v;
    typedef ublas::vector<double, ublas::bounded_array<double,dim_2> > value_type_dv;
    typedef ublas::vector<double, ublas::bounded_array<double,dim_3> > value_type_r;
protected:
    typedef boost::circular_buffer<  value_type_v   > buffer_type_v;
    typedef boost::circular_buffer<  value_type_dv   > buffer_type_d;
    typedef boost::circular_buffer<  value_type_r   > buffer_type_r;
    typedef std::map<double,unsigned long> _time_entries_type;
    buffer_type_v _variables_buffer;
    buffer_type_d _derivatives_buffer;
    buffer_type_r _residues_buffer;
    _time_entries_type _time_entries;
    unsigned long  _buffer_pos;

    //private:
    //TextwriterType* textwriter;

};
