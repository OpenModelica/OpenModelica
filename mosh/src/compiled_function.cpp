#include "compiled_function.hpp"
#include <stdio.h>
#include <fstream>
#include <stdlib.h>

#include "function_argument.hpp"
#include "value.hpp"
#include <unistd.h>

//extern "C" {
// #include "../c_runtime/read_write.h"
//}


compiled_function::compiled_function()
{
  
}

compiled_function::compiled_function(std::string filename)
{
  m_filename = filename;
}

compiled_function::~compiled_function()
{

}

value compiled_function::do_apply(value args)
{
  // Generate input file
  write_input_file(args);

  // Check if a valid executable exist
  // Execute
  
  // Build executable


  std::string build_command = "sh -c \"make -f Makefile.single TARGET="+m_filename+ " all 1> cmdoutput.tmp 2>&1\"";
  if (system(build_command.c_str()) == -1)
    {
      system("cat cmdoutput.tmp");
      cout << "Failed to build file" << endl;
    }

  std::string execute_command = "rm -f result.dat;" + m_filename+" mosh_in.dat"+" result.dat";
  
  if (system(execute_command.c_str())==-1)
    {
      cout << "Failed to execute file" << endl;
    }
  
  // Read output file
  value ret_val;
  read_result_file(&ret_val);
  // Return value
  return ret_val;
}

bool compiled_function::match_formal_parameters(value val)
{
  return true;
}

void compiled_function::write_input_file(value args)
{
  FILE* fp = fopen("mosh_in.dat","w");
  
  if(fp == NULL)
    {
      cout << "Failed to open mosh_in.dat" << endl;
    }

   function_argument* params = args.get_function_argument();
   function_argument::parameter_iterator it = params->begin();  
   for (; it != params->end();++it)
     {
       if (it->first.is_real())
 	{
	  fprintf(fp,"# r!\n");
 	  fprintf(fp,"%e\n",it->first.get_real());
 	}
       else if (it->first.is_integer())
 	{
	  fprintf(fp,"# i!\n");
 	  fprintf(fp,"%d\n",it->first.get_integer());
 	}
       else if (it->first.is_real_array())
	 {
	   real_array arr = it->first.get_real_array();
	   std::vector<int> dims = arr.size();
	   fprintf(fp,"# r[%d ",dims.size());
	   for (int i = 0; i < (int)dims.size(); ++i)
	     {
	       fprintf(fp,"%d ",dims[i]);
	     }
	   fprintf(fp,"\n");
	   real_array::const_data_iterator it;
	   for (it = arr.data_begin(); it != arr.data_end(); ++it)
	     {
	       fprintf(fp,"%e\n",*it);
	     }
	 }
       else if (it->first.is_integer_array())
	 {
	   integer_array arr = it->first.get_integer_array();
	   std::vector<int> dims = arr.size();
	   fprintf(fp,"# i[%d ",dims.size());
	   for (int i = 0; i < (int)dims.size(); ++i)
	     {
	       fprintf(fp,"%d ",dims[i]);
	     }
	   fprintf(fp,"\n");
	   integer_array::const_data_iterator it;
	   for (it = arr.data_begin(); it != arr.data_end(); ++it)
	     {
	       fprintf(fp,"%d\n",*it);
	     }
	 }
       else
 	{
 	  cout << "tried to print an unknown type" << endl;
 	}
     }
  
  fclose(fp);
}


struct type_desc_s {
  char type;
  int ndims;
  int *dim_size;
};

typedef struct type_desc_s type_description;

void cleanup_description(type_description* desc)
{
  if (desc->ndims > 0)
    {
      free(desc->dim_size);
    }
}

void read_to_eol(FILE* file)
{
  int c;
  while (((c = fgetc(file)) != '\n') && (c != EOF));
}

int read_type_description(FILE* file, type_description* desc)
{
  int c;
  int i;
  do 
    {
      if ((c = fgetc(file)) == EOF) return 1;
      if (c != '#') return 1;
      if ((c = fgetc(file)) == EOF) return 1;
      if (c != ' ') return 1;
      if ((c = fgetc(file)) == EOF) return 1;
      switch (c)
	{
	case 'i': /* integer */
	case 'r': /* real */
	case 'b': /* boolean */
	case 's': /* string */
	  desc->type = c;
	  break;
	default:
	  return 1;	  
	}
      if ((c = fgetc(file)) == EOF) return 1;
      if (c == '!') /* scalar */
	{
	  desc->ndims = 0;
	  desc->dim_size = 0;
	  break;
	}
      if (c != '[') return 1;
      /* now is an array dim description */
      if (fscanf(file,"%d",&desc->ndims) != 1) return 1;
      if (desc->ndims < 0) return 1;
      if (desc->ndims > 0)
	{
	  desc->dim_size = (int*)malloc(desc->ndims*sizeof(int));
	  if (!desc->dim_size) return 1;
	}
      else
	{
	  desc->dim_size = 0;
	}
      for (i = 0; i < desc->ndims; ++i)
	{
	  if (fscanf(file,"%d",&desc->dim_size[i]) != 1)
	    {
	      free(desc->dim_size);
	      return 1;
	    }	  
	}
      break;
      
    } while (0);

  read_to_eol(file);

  return 0;
}

void compiled_function::read_result_file(value* v)
{
  FILE* fp = fopen("result.dat","r");

  if (fp == NULL)
    {
      cout << "Failed to open data.out" << endl;
      return;
    }

  std::vector<value> vals;
  while (true)
    {
      type_description desc;
      if (read_type_description(fp,&desc))
	{
	  break;
	}
      if (desc.ndims == 0)
	{
	  if (desc.type == 'r')
	    {
	      float f;
	      if (fscanf(fp,"%e",&f) != 1) 
		{ 
		  cleanup_description(&desc);
		  break; 
		}
	      read_to_eol(fp);
	      vals.push_back(value((double)f));
	    }
	  else if (desc.type == 'i')
	    {
	      int i;
	      if (fscanf(fp,"%d",&i) != 1) 
		{ 
		  cleanup_description(&desc);
		  break; 
		}
	      read_to_eol(fp);
	      vals.push_back(value(i));
	    }
	  else 
	    {
	      cout << "Unknow result type\n";
	      break;
	    }
	}
      else 
	{
	  std::vector<int> dims(desc.dim_size,desc.dim_size+desc.ndims);
	  if (desc.type == 'r')
	    {
	      real_array arr(dims);
	      real_array::data_iterator it;
	      bool error = false;
	      for (it = arr.data_begin(); it != arr.data_end(); ++it)
		{
		  float f;
		  if (fscanf(fp,"%e",&f) != 1) 
		    { 
		      cleanup_description(&desc);
		      error = true;
		      break; 
		    }
		  *it = f;
		}
	      if (error) break;
	      read_to_eol(fp);
	      vals.push_back(value(arr));
	    }
	  else if (desc.type == 'i')
	    {
	      integer_array arr(dims);
	      integer_array::data_iterator it;
	      bool error = false;
	      for (it = arr.data_begin(); it != arr.data_end(); ++it)
		{
		  int i;
		  if (fscanf(fp,"%d",&i) != 1) 
		    { 
		      cleanup_description(&desc);
		      error = true;
		      break; 
		    }
		  *it = i;
		}
	      if (error) break;
	      read_to_eol(fp);
	      vals.push_back(value(arr));
	    }
	  else 
	    {
	      cout << "Unknow result type\n";
	      break;
	    }
	}

      cleanup_description(&desc);
    }


  if (vals.size() == 1)
    {
      *v = vals[0];
    }
  else
    {      
      v->set_value(vals);
    }

  

  fclose(fp);
}

