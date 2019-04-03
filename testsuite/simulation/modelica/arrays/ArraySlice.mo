// name:     ArraySlice
// keywords: array slicing
// status:   correct
//
// Drmodelica: 7.7 Built-in Functions (p. 225)
//

model ArraySlice
    Real T[30](start=ones(30)*200);
    Real Tin=100;
    Real temp[30](start=zeros(30));
equation
    temp[1]=100.0;
    temp[2:30]=T[2:30];
    der(T)=temp;
end ArraySlice;

// Result:
// class ArraySlice
//   Real T[1](start = 200.0);
//   Real T[2](start = 200.0);
//   Real T[3](start = 200.0);
//   Real T[4](start = 200.0);
//   Real T[5](start = 200.0);
//   Real T[6](start = 200.0);
//   Real T[7](start = 200.0);
//   Real T[8](start = 200.0);
//   Real T[9](start = 200.0);
//   Real T[10](start = 200.0);
//   Real T[11](start = 200.0);
//   Real T[12](start = 200.0);
//   Real T[13](start = 200.0);
//   Real T[14](start = 200.0);
//   Real T[15](start = 200.0);
//   Real T[16](start = 200.0);
//   Real T[17](start = 200.0);
//   Real T[18](start = 200.0);
//   Real T[19](start = 200.0);
//   Real T[20](start = 200.0);
//   Real T[21](start = 200.0);
//   Real T[22](start = 200.0);
//   Real T[23](start = 200.0);
//   Real T[24](start = 200.0);
//   Real T[25](start = 200.0);
//   Real T[26](start = 200.0);
//   Real T[27](start = 200.0);
//   Real T[28](start = 200.0);
//   Real T[29](start = 200.0);
//   Real T[30](start = 200.0);
//   Real Tin = 100.0;
//   Real temp[1](start = 0.0);
//   Real temp[2](start = 0.0);
//   Real temp[3](start = 0.0);
//   Real temp[4](start = 0.0);
//   Real temp[5](start = 0.0);
//   Real temp[6](start = 0.0);
//   Real temp[7](start = 0.0);
//   Real temp[8](start = 0.0);
//   Real temp[9](start = 0.0);
//   Real temp[10](start = 0.0);
//   Real temp[11](start = 0.0);
//   Real temp[12](start = 0.0);
//   Real temp[13](start = 0.0);
//   Real temp[14](start = 0.0);
//   Real temp[15](start = 0.0);
//   Real temp[16](start = 0.0);
//   Real temp[17](start = 0.0);
//   Real temp[18](start = 0.0);
//   Real temp[19](start = 0.0);
//   Real temp[20](start = 0.0);
//   Real temp[21](start = 0.0);
//   Real temp[22](start = 0.0);
//   Real temp[23](start = 0.0);
//   Real temp[24](start = 0.0);
//   Real temp[25](start = 0.0);
//   Real temp[26](start = 0.0);
//   Real temp[27](start = 0.0);
//   Real temp[28](start = 0.0);
//   Real temp[29](start = 0.0);
//   Real temp[30](start = 0.0);
// equation
//   temp[1] = 100.0;
//   temp[2] = T[2];
//   temp[3] = T[3];
//   temp[4] = T[4];
//   temp[5] = T[5];
//   temp[6] = T[6];
//   temp[7] = T[7];
//   temp[8] = T[8];
//   temp[9] = T[9];
//   temp[10] = T[10];
//   temp[11] = T[11];
//   temp[12] = T[12];
//   temp[13] = T[13];
//   temp[14] = T[14];
//   temp[15] = T[15];
//   temp[16] = T[16];
//   temp[17] = T[17];
//   temp[18] = T[18];
//   temp[19] = T[19];
//   temp[20] = T[20];
//   temp[21] = T[21];
//   temp[22] = T[22];
//   temp[23] = T[23];
//   temp[24] = T[24];
//   temp[25] = T[25];
//   temp[26] = T[26];
//   temp[27] = T[27];
//   temp[28] = T[28];
//   temp[29] = T[29];
//   temp[30] = T[30];
//   der(T[1]) = temp[1];
//   der(T[2]) = temp[2];
//   der(T[3]) = temp[3];
//   der(T[4]) = temp[4];
//   der(T[5]) = temp[5];
//   der(T[6]) = temp[6];
//   der(T[7]) = temp[7];
//   der(T[8]) = temp[8];
//   der(T[9]) = temp[9];
//   der(T[10]) = temp[10];
//   der(T[11]) = temp[11];
//   der(T[12]) = temp[12];
//   der(T[13]) = temp[13];
//   der(T[14]) = temp[14];
//   der(T[15]) = temp[15];
//   der(T[16]) = temp[16];
//   der(T[17]) = temp[17];
//   der(T[18]) = temp[18];
//   der(T[19]) = temp[19];
//   der(T[20]) = temp[20];
//   der(T[21]) = temp[21];
//   der(T[22]) = temp[22];
//   der(T[23]) = temp[23];
//   der(T[24]) = temp[24];
//   der(T[25]) = temp[25];
//   der(T[26]) = temp[26];
//   der(T[27]) = temp[27];
//   der(T[28]) = temp[28];
//   der(T[29]) = temp[29];
//   der(T[30]) = temp[30];
// end ArraySlice;
// endResult
