void euler ( double *x, double *xd, double *y, double *p, double *res,
	     int numpoints,
	     int nx, int ny, int np,
	     double start,
	     double stop,
	     double step, void (*f)(double*,// x
			       double*,// xd
			       double*,// y
			       double*,// p
			       int,int,int, //nx,ny,np
			       double)); // time
void read_input(int argc, char **argv,
		double* x,double*xd,double*y,
		double *p, int nx,int ny, int np,
		double *start, double *stop,
		double *step);

void write_result_txt(char * filename, int nx, int ny, int numpts,double *data);
