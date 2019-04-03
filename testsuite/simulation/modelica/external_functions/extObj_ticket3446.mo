package TestMyExternalObj
  class MyExternalObj
    extends ExternalObject;
    function constructor
      input Integer size=3;
      output MyExternalObj outMyExternalObj;

      external "C" outMyExternalObj=initMyExternalObj(size);
      annotation(Include="
        #include <stdio.h>
        #include <stdlib.h> /* for Linux malloc and exit */
        #include <string.h>

        void* initMyExternalObj(int size)
        {
          int i=0;

          double *extObj = (double*)malloc(size*sizeof(double));
          if(extObj == NULL)
            printf(\"Not enough memory\");

          for(i=0; i<size; i++)
            if(i < 2)
              extObj[i] = 1.0;
            else
              extObj[i] = extObj[i-1]+extObj[i-2];

          return (void*)extObj;
        }");
    end constructor;

    function destructor
      input MyExternalObj inMyExternalObj;

      external "C" closeMyExternalObj(inMyExternalObj) ;
      annotation(Include="
        #include <stdio.h>
        #include <stdlib.h> /* for Linux malloc and exit */
        #include <string.h>

        /* Destructor */
        void closeMyExternalObj(void *object)
        {
          /* Release storage */
          double *extObj = (double*)object;
          if (object == NULL)
            return;

          free(extObj);
        }");
    end destructor;
  end MyExternalObj;

  function readFromMyExternalObj
    input MyExternalObj extObj;
    input Integer i;
    output Real y;

    external "C" y=readFromMyExternalObj(extObj, i);
    annotation(Include="
      #include <stdio.h>
      #include <stdlib.h> /* for Linux malloc and exit */
      #include <string.h>

      double readFromMyExternalObj(void* object, int i)
      {
        double *extObj = (double*)object;
        return extObj[i-1];
      }");
  end readFromMyExternalObj;

  model Test
    parameter Integer size = 5;
    final parameter Integer size_ = size;
    parameter MyExternalObj MyExtObj=MyExternalObj(size_);
    parameter Real p1 = readFromMyExternalObj(MyExtObj, 1);
    Real p2 = readFromMyExternalObj(MyExtObj, 2);
    Real p3 = readFromMyExternalObj(MyExtObj, 3);
    Real p4 = readFromMyExternalObj(MyExtObj, 4);
    Real p5 = readFromMyExternalObj(MyExtObj, 5);
  end Test;
end TestMyExternalObj;
