#pragma once
/** @defgroup dataexchangePolicies Core.DataExchange.Policy
 *  Module for storing different file output formats ( csv- ,mat- files  and buffer storage)
 *  @{
 */
#include "TextfileWriter.h"

#include <boost/circular_buffer.hpp>
typedef boost::container::vector<double> real_values_t;
typedef boost::container::vector<int> int_values_t;
typedef boost::container::vector<bool> bool_values_t;
typedef boost::container::vector<double> der_values_t;
typedef boost::container::vector<double> res_values_t;
struct CopyVar {
  template<class T>
   T operator()(T* var) const {
    return *var;
  }
};
class BufferReaderWriter : public ContainerManager
{
    //typedef TextFileWriter<dim_1,dim_2> TextwriterType;
public:
    BufferReaderWriter(unsigned long size, string output_path, string file_name)
        : ContainerManager(),
            _buffer_pos(0)
    {
        try
        {

            _real_variables_buffer.set_capacity(size+size/5);
            _bool_variables_buffer.set_capacity(size+size/5);
            _int_variables_buffer.set_capacity(size+size/5);
            _der_variables_buffer.set_capacity(size+size/5);
             _res_variables_buffer.set_capacity(size+size/5);

            // cout<<"size+size/5 "<< size+size/5 << std::endl;


            /*ToDo: use correct size for corresponding type*/
        }
        catch(std::exception& ex)
        {
           throw ModelicaSimulationError(DATASTORAGE,string("allocating   buffers failed")+ex.what());
        }
    }

    void init(/*string output_path,string file_name*/std::string output_path, std::string file_name, size_t dim)
    {
    }
    /**
    Reads all Simulation results (algebraic and state variables in R, derivatives in dR)
    Rij i variable index
    j number of time index
    */
    void read(ublas::matrix<double>& R,ublas::matrix<double>& dR)
    {
        /*
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
        */

    }

    void read(ublas::matrix<double>& R,ublas::matrix<double>& dR,ublas::matrix<double>& Re)
    {
        /*
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
        */

         ublas::matrix<double>::size_type m = size();
         cout<<"time in buffer "<< m << std::endl;
        ublas::matrix<double>::size_type n =_dim_der;/*get<0>(_var_outputs).size() + get<1>(_var_outputs).size() + get<2>(_var_outputs).size()*/;
       // cout<<"_dim_der "<< n << std::endl;

        ublas::matrix<double>::size_type i,i2=0,j;
        try
        {
            dR.resize(n,m);
        }
        catch(std::exception& ex)
        {
            cout<<"read  from derivative buffer faild alloc R with sizes "<<m <<"," << n << std::endl;
            throw ModelicaSimulationError(DATASTORAGE,string("read  from derivatives buffer failed alloc dR matrix")+ex.what());

        }
         try
        {
            /*FOREACH(i,indices)*/
            for(i=0;i<n;i++)
            {
                //cout<<"Var "<<i;
                for(j=0;j<m;++j)
                {
                   // cout<<" t "<<j;
                     dR(i2,j)= (_der_variables_buffer[j][i]);
                   // cout<<" val "<<(_der_variables_buffer[j][i]) << std::endl;
                }

                i2++;
            }

              /*  ublas::vector<double> o_j;
            for(i=0;i<n;i++)
            {
		    o_j = ublas::row(dR,i);
            cout << "derivatives on read buffer " << o_j << std::endl;
            }  */
        }
        catch(std::exception& ex)
        {

          throw ModelicaSimulationError(DATASTORAGE,string("read  from derivative buffer failed")+ex.what());

        }

         n =_dim_real;
         i2=0;
        // cout<<"_dim_real "<< n << std::endl;
         try
        {


            R.resize(n,m);
        }
        catch(std::exception& ex)
        {

            throw ModelicaSimulationError(DATASTORAGE,string("read  from real Variables buffer failed alloc R matrix")+ex.what());

        }
         try
        {

            //FOREACH(i,indices)
            for(i=0;i<n;i++)
            {
                for(j=0;j<m;++j)

                    R(i2,j)= (_real_variables_buffer[j][i]);

                    //ToDo: add int and bool variables
                i2++;
            }


        }
        catch(std::exception& ex)
        {

          throw ModelicaSimulationError(DATASTORAGE,string("read  from real buffer failed")+ex.what());

        }
        n =_dim_res;

         i2=0;
        // cout<<"_dim_res "<< n << std::endl;
         try
        {


            Re.resize(n,m);
        }
        catch(std::exception& ex)
        {

            throw ModelicaSimulationError(DATASTORAGE,string("read  from residues Variables buffer failed alloc R matrix")+ex.what());

        }
         try
        {


            for(i=0;i<n;i++)
            {
                for(j=0;j<m;++j)

                    Re(i2,j)= (_res_variables_buffer[j][i]);


                i2++;
            }
        }
        catch(std::exception& ex)
        {

          throw ModelicaSimulationError(DATASTORAGE,string("read  from residues Variables buffer failed")+ex.what());

        }


    }

    void read(ublas::matrix<double>& R)
    {

        ublas::matrix<double>::size_type m = size();

        ublas::matrix<double>::size_type n ;

        if(_var_outputs.size()!=0)

            n= _var_outputs.size();/*get<0>(_var_outputs).size() + get<1>(_var_outputs).size() + get<2>(_var_outputs).size()*/

        else
            n=_dim_real;

       // cout<<"_dim_outputR "<< n << std::endl;
        try
        {


            R.resize(n,m);
        }
        catch(std::exception& ex)
        {
           // cout<<"read  from variables buffer faild alloc R with sizes "<<m <<"," << n << std::endl;
            throw ModelicaSimulationError(DATASTORAGE,string("read  from variables buffer failed alloc R matrix")+ex.what());

        }
         ublas::matrix<double>::size_type i,i2=0,j;
         try
        {
            /*FOREACH(i,indices)*/
            for(i=0;i<n;i++)
            {
                for(j=0;j<m;++j)
                {
                    R(i2,j)= (_real_variables_buffer[j][i]);

                }

                i2++;
            }
        }
        catch(std::exception& ex)
        {

          throw ModelicaSimulationError(DATASTORAGE,string("read  from variables buffer failed")+ex.what());

        }


    }

    void read(const double& time,ublas::vector<double>& dv,ublas::vector<double>& v)
    {
        /*
        std::map<double,unsigned long>::iterator iter;
        iter = find_if( _time_entries.begin(), _time_entries.end(), floatCompare<double>(time, 1e-10) );
        if(iter==_time_entries.end())
            throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,string("getVariables: time parameters");
        v=_variables_buffer[iter->second];
        dv = _derivatives_buffer[iter->second];
        */
    }

    void read(const double& time,ublas::vector<double>& r,ublas::vector<double>& dv,ublas::vector<double>& v)
    {
        /*
        std::map<double,unsigned long>::iterator iter;
        iter = find_if( _time_entries.begin(), _time_entries.end(), floatCompare<double>(time, 1e-10) );
        if(iter==_time_entries.end())
            throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,string("getVariables: time parameters");
        v=_variables_buffer[iter->second];
        dv = _derivatives_buffer[iter->second];
       // r = _residues_buffer[iter->second];
       */
    }

    void write(const vector<string>& s)
    {

    }

    void write(const char c)
    {

    }
    /*writes pramater values to results file
     @v_list values of real,int,bool parameter
     @start_time
     @end_time
     */
    virtual void write(const all_vars_t& v_list, double start_time, double end_time)
    {
      //not supported for buffer
    }
     /*
     writes header of results file with the variable names
     @s_list name of real,int,bool variables
     @s_desc_list description of real,int,bool variables
     @s_parameter_list name ofreal,int,bool parameter
     @s_desc_parameter_list description of real,int,bool parameter
     */
    virtual void write(const all_names_t& s_list,const all_description_t& s_desc_list,const all_names_t& s_parameter_list,const all_description_t& s_desc_parameter_list)
    {

          _dim_real = get<0>(s_list).size();
          _dim_int = get<1>(s_list).size();
          _dim_bool = get<2>(s_list).size();
          _dim_der = get<3>(s_list).size();

          _real_values = real_values_t(_dim_real);
          _int_values =  int_values_t(_dim_int);
          _bool_values =  bool_values_t(_dim_bool);
          _der_values =  der_values_t(_dim_der);

        //_var_outputs = s_list;
		_var_outputs.clear();
        for (var_names_t::const_iterator it = get<0>(s_list).begin(); it != get<0>(s_list).end(); ++it)
        {
            _var_outputs.push_back(*it);
        }
    }

     /*
     writes simulation results for a time step
     @v_list variables and state vars
     @v2_list derivatives vars
     @time
     */
    virtual void write(const all_vars_time_t& v_list,const neg_all_vars_t& neg_v_list)
    {


        try
        {

            std::pair<std::map<double, unsigned long>::iterator,bool> p;
            p = _time_entries.insert(make_pair(get<3>(v_list),_buffer_pos));

            if(!p.second)//if variable and derivatives for time are already inserted, erase old values
            {
                //cout<< "size real "<< _real_variables_buffer.size() <<std::endl;
                _real_variables_buffer.pop_back();
                //cout << "size int " << _int_variables_buffer.size()<<std::endl;
                _int_variables_buffer.pop_back();
                //cout << "size bool " << _bool_variables_buffer.size()<<std::endl;
                _bool_variables_buffer.pop_back();
                _der_variables_buffer.pop_back();
                _res_variables_buffer.pop_back();

            }
            else
            {
                _buffer_pos++;

            }

            _dim_res = get<5>(v_list).size();
            _res_values =  res_values_t(_dim_res);

       /*   for (real_vars_t::const_iterator it = get<0>(v_list).begin(); it != get<0>(v_list).end(); ++it)
        {

             std::cout << *(*it)<<",";
        }
            std::cout<<"\n";  */

             std::transform(get<0>(v_list).begin(),get<0>(v_list).end(),_real_values.begin(),CopyVar());
             std::transform(get<1>(v_list).begin(),get<1>(v_list).end(),_int_values.begin(),CopyVar());
             std::transform(get<2>(v_list).begin(),get<2>(v_list).end(),_bool_values.begin(),CopyVar());
             std::transform(get<4>(v_list).begin(),get<4>(v_list).end(),_der_values.begin(),CopyVar());
             std::transform(get<5>(v_list).begin(),get<5>(v_list).end(),_res_values.begin(),CopyVar());


              _real_variables_buffer.push_back(_real_values);
              _int_variables_buffer.push_back(_int_values);
              _bool_variables_buffer.push_back(_bool_values);
              _der_variables_buffer.push_back(_der_values);
              _res_variables_buffer.push_back(_res_values);

         // cout<<"output values on write buffer "<< std::endl;

      /*      for (real_values_t::const_iterator it = _real_values.begin(); it != _real_values.end(); ++it)
        {

             std::cout << *it<<",";
        }
            std::cout<<"\n"; */

           //_all_var_size=get<0>(v_list).size();// now just  real variables are supported

        }
        catch(std::exception& ex)
        {

            throw ModelicaSimulationError(DATASTORAGE,string("write to buffer failed")+ex.what());

        }

        // textwriter->write(v,v2, time);
    }


    void getTime(vector<double>& time)
    {
        try
        {
            typedef std::pair<double, unsigned long> pair_double_ulong;
            FOREACH(pair_double_ulong i, _time_entries)
            {
                time.push_back(i.first);
            }
        }
        catch(std::exception& ex)
        {

            throw ModelicaSimulationError(DATASTORAGE,string("read from time buffer failed")+ex.what());

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

            throw ModelicaSimulationError(DATASTORAGE,string("time entries size failed")+ex.what());

        }
    }
    void eraseAll()
    {
        try{
        _real_variables_buffer.clear();
        _int_variables_buffer.clear();
         _bool_variables_buffer.clear();
        _der_variables_buffer.clear();
        _res_variables_buffer.clear();
        //_residues_buffer.clear();
        _time_entries.clear();
        _buffer_pos=0;
        //textwriter->eraseAll();
        }

        catch(std::exception& ex)
        {

            throw ModelicaSimulationError(DATASTORAGE,string("can not erase buffer of variables")+ex.what());

        }

    }


protected:

    typedef boost::circular_buffer<  real_values_t > real_buffer_type;
     typedef boost::circular_buffer<  int_values_t   > int_buffer_type;
    typedef boost::circular_buffer<  bool_values_t   > bool_buffer_type;
    typedef boost::circular_buffer<  der_values_t> der_buffer_type;
    typedef boost::circular_buffer<  res_values_t> res_buffer_type;
     //typedef boost::circular_buffer< boost::container::vector<double>> buffer_type;

    typedef std::map<double,unsigned long> _time_entries_type;

    real_buffer_type _real_variables_buffer;
    int_buffer_type _int_variables_buffer;
    bool_buffer_type _bool_variables_buffer;
     der_buffer_type _der_variables_buffer;
     res_buffer_type _res_variables_buffer;
     //buffer_type buffer_var;

    //buffer_type_r _residues_buffer;
    _time_entries_type _time_entries;
    unsigned long _buffer_pos;
    vector<string> _var_outputs;

    size_t _dim_real;
    size_t _dim_int;
    size_t _dim_bool;
    size_t _dim_der;
    size_t _dim_res;

    real_values_t  _real_values;
    int_values_t   _int_values;
    bool_values_t  _bool_values;
    der_values_t  _der_values;
    res_values_t  _res_values;
};
/** @} */ // end of dataexchangePolicies
