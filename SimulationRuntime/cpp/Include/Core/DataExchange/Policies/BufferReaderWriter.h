#pragma once
/** @defgroup dataexchangePolicies Core.DataExchange.Policy
 *  Module for storing different file output formats ( csv- ,mat- files  and buffer storage)
 *  @{
 */
#include "TextfileWriter.h"


template <size_t dim_1,size_t dim_2,size_t dim_3,size_t dim_4>
class BufferReaderWriter : public Writer<dim_1, dim_2, dim_3, dim_4>
{
    //typedef TextFileWriter<dim_1,dim_2> TextwriterType;
public:
    BufferReaderWriter(unsigned long size, string output_path, string file_name)
        : Writer<dim_1, dim_2, dim_3, dim_4>(),
            _buffer_pos(0)
    {
        try
        {
            _variables_buffer.set_capacity(size+size/10);
            _derivatives_buffer.set_capacity(size+size/10);
            //_residues_buffer.set_capacity(size+size/10);
            //textwriter = new TextwriterType(size,output_folder);
        }
        catch(std::exception& ex)
        {
           throw ModelicaSimulationError(DATASTORAGE,string("allocating   buffers failed")+ex.what());
        }
    }
    void  init(string output_path,string file_name)
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

    }

    void read(ublas::matrix<double>& R)
    {

        ublas::matrix<double>::size_type m = size();
        ublas::matrix<double>::size_type n = _var_outputs.size();
        ublas::matrix<double>::size_type i,i2=0,j;
        try
        {


            R.resize(n,m);
        }
        catch(std::exception& ex)
        {
           // cout<<"read  from variables buffer faild alloc R with sizes "<<m <<"," << n << std::endl;
            throw ModelicaSimulationError(DATASTORAGE,string("read  from variables buffer failed alloc R matrix")+ex.what());

        }
         try
        {
            /*BOOST_FOREACH(i,indices)*/
            for(i=0;i<n;i++)
            {
                for(j=0;j<m;++j)
                    R(i2,j)=_variables_buffer[j](i);
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
     @v_list values of parameter
     @start_time
     @end_time
     */
    void write(const typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_p& v_list, double start_time, double end_time)
    {
      //not supported for buffer
    }
     /*
     writes header of results file with the variable names
     @s_list name of variables
     @s_desc_list description of variables
     @s_parameter_list name of parameter
     @s_desc_parameter_list description of parameter
     */
    void write(const std::vector<std::string>& s_list, const std::vector<std::string>& s_desc_list, const std::vector<std::string>& s_parameter_list, const std::vector<std::string>& s_desc_parameter_list)
    {
       _var_outputs =s_list;
    }

     /*
     writes simulation results for a time step
     @v_list variables and state vars
     @v2_list derivatives vars
     @time
     */
    void write(typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_v& v_list, typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_dv& v2_list, double time)
    {


        try
        {
            std::pair<std::map<double, unsigned long>::iterator,bool> p;
            p = _time_entries.insert(make_pair(time,_buffer_pos));
            if(!p.second)//if variable and derivatives for time are already inserted, erase old values
            {
                _variables_buffer.pop_back();
                _derivatives_buffer.pop_back();
            }
            else
            {
                _buffer_pos++;
            }


            _variables_buffer.push_back(v_list);
            _derivatives_buffer.push_back(v2_list);
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
            std::pair<double,unsigned long> i;
            BOOST_FOREACH(i, _time_entries)
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

        _variables_buffer.clear();
        _derivatives_buffer.clear();
        //_residues_buffer.clear();
        _time_entries.clear();
        _buffer_pos=0;
        //textwriter->eraseAll();
    }


protected:
    typedef boost::circular_buffer<  typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_v   > buffer_type_v;
    typedef boost::circular_buffer<  typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_dv   > buffer_type_d;

    typedef std::map<double,unsigned long> _time_entries_type;
    buffer_type_v _variables_buffer;
    buffer_type_d _derivatives_buffer;
    //buffer_type_r _residues_buffer;
    _time_entries_type _time_entries;
    unsigned long  _buffer_pos;
    vector<string> _var_outputs;

};
/** @} */ // end of dataexchangePolicies