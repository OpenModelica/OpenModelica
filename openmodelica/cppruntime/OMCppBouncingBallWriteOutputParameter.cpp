     void   BouncingBallWriteOutput::writeParametertNames(vector<string>& names)
     {
      /*workarround ced*/
     
      names += "e","g";

     }
     
      void   BouncingBallWriteOutput::writeIntParameterNames(vector<string>& names)
     {
     }
      void   BouncingBallWriteOutput::writeBoolParameterNames(vector<string>& names)
     {
     }
     void   BouncingBallWriteOutput::writeParameterDescription(vector<string>& names)
     {
      /*workarround ced*/
      names += "coefficient of restitution","gravity acceleration";

     }
     
      void   BouncingBallWriteOutput::writeIntParameterDescription(vector<string>& names)
     {
     }
     
      void   BouncingBallWriteOutput::writeBoolParameterDescription(vector<string>& names)
     {
     }
     void BouncingBallWriteOutput::writeParams(HistoryImplType::value_type_p& params)
     {
      /*const int paramVarsStart = 1;
      const int intParamVarsStart  = paramVarsStart       + 2;
      const int boolparamVarsStart    = intParamVarsStart  + 0;
      */
      writeParamsReal(params);
      writeParamsInt(params);
      writeParamsBool(params);
     }
     void BouncingBallWriteOutput::writeParamsReal_0( HistoryImplType::value_type_p& params  )
     {
        params(1)=_e;params(2)=_g;
     }
     
     void BouncingBallWriteOutput::writeParamsReal(HistoryImplType::value_type_p& params  )
     {
       //number of vars: 2
       BouncingBallWriteOutput::writeParamsReal_0(params);
     }
     
     void BouncingBallWriteOutput::writeParamsInt(HistoryImplType::value_type_p& params  )
     {
       //number of vars: 0
     }
     
     void BouncingBallWriteOutput::writeParamsBool(HistoryImplType::value_type_p& params  )
     {
       //number of vars: 0
     }