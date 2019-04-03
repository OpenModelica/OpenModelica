package Ticket4157

	  model when_init_complex
	    Real a_re;
	    Real a_im;
	    Complex Eo;
	  equation
	    a_re = 10;
	    a_im = 0;
	    when initial() then
	      Eo = Complex(a_re, a_im) + Complex(10, 0);
	    end when;
	  end when_init_complex;
	
	  model if_complex_if_expression
	    parameter Complex E = Complex(1, 0);
	    parameter Complex Z = Complex(0.1, 0.1);
	    Complex V;
	    parameter Boolean model_type = true;
	  equation
	    Complex(E.re - V.re, E.im - V.im) = if model_type then Complex(0, 0) else Complex(Z.re, Z.im);
	  end if_complex_if_expression;

end Ticket4157;
