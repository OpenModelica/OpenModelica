function area = traparea(a,b,h)
	%  traparea(a,b,h)   Computes the area of a trapezoid given
	%                    the dimensions a, b and h, where a and b
	%                    are the lengths of the parallel sides and
	%                    h is the distance between these sides
	
	%  Compute the area, but suppress printing of the result
	area = 0.5*(a+b)*h;