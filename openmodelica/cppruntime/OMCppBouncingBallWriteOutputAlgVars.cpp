    void BouncingBallWriteOutput::writeAlgVarsResultNames(vector<string>& names)
    {

    }
    void BouncingBallWriteOutput::writeDiscreteAlgVarsResultNames(vector<string>& names)
    {
     names += "v_new";

    }
    void  BouncingBallWriteOutput::writeIntAlgVarsResultNames(vector<string>& names)
     {
      names += "n_bounce";
     }
     void BouncingBallWriteOutput::writeBoolAlgVarsResultNames(vector<string>& names)
     {
     names +="$whenCondition1","$whenCondition2","$whenCondition3","flying","impact";
     }
    void BouncingBallWriteOutput::writeAlgVarsResultDescription(vector<string>& description)
    {

    }
    void BouncingBallWriteOutput::writeDiscreteAlgVarsResultDescription(vector<string>& description)
    {
     description += "";

    }
    void  BouncingBallWriteOutput::writeIntAlgVarsResultDescription(vector<string>& description)
     {
      description += "";
     }
     void BouncingBallWriteOutput::writeBoolAlgVarsResultDescription(vector<string>& description)
     {
     description +="","","","true, if ball is flying","";
     }
     
     void BouncingBallWriteOutput::writeAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 0
     }
     void BouncingBallWriteOutput::writeDiscreteAlgVarsValues_0(HistoryImplType::value_type_v *v)
     {
        (*v)(1)=_v_new;
     }
     
     void BouncingBallWriteOutput::writeDiscreteAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 1
       BouncingBallWriteOutput::writeDiscreteAlgVarsValues_0(v);
     }
     void BouncingBallWriteOutput::writeIntAlgVarsValues_0(HistoryImplType::value_type_v *v)
     {
        (*v)(2)=_n_bounce;
     }
     
     void BouncingBallWriteOutput::writeIntAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 1
       BouncingBallWriteOutput::writeIntAlgVarsValues_0(v);
     }
     void BouncingBallWriteOutput::writeBoolAlgVarsValues_0(HistoryImplType::value_type_v *v)
     {
        (*v)(3)=_$whenCondition1;
        (*v)(4)=_$whenCondition2;
        (*v)(5)=_$whenCondition3;
        (*v)(6)=_flying;
        (*v)(7)=_impact;
     }
     
     void BouncingBallWriteOutput::writeBoolAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 5
       BouncingBallWriteOutput::writeBoolAlgVarsValues_0(v);
     }

