// name: ForIterator3
// status: correct
class ForIterator3
  constant String s1[4,3] = {i+j for i in {"a","b","c"}, j in {"d","e","f","g"}};
  constant String s2 = sum(i+j for i in {"a","b","c"}, j in {"d","e","f","g"});
  constant String s3[:,:,:,:] = {i+j+k+l for i in {"a","b","c"}, j in {"d","e","f","g"}, k in {"h"}, l in {"1","2","3","4"}};
end ForIterator3;

// Result:
// class ForIterator3
//   constant String s1[1,1] = "ad";
//   constant String s1[1,2] = "bd";
//   constant String s1[1,3] = "cd";
//   constant String s1[2,1] = "ae";
//   constant String s1[2,2] = "be";
//   constant String s1[2,3] = "ce";
//   constant String s1[3,1] = "af";
//   constant String s1[3,2] = "bf";
//   constant String s1[3,3] = "cf";
//   constant String s1[4,1] = "ag";
//   constant String s1[4,2] = "bg";
//   constant String s1[4,3] = "cg";
//   constant String s2 = "adbdcdaebeceafbfcfagbgcg";
//   constant String s3[1,1,1,1] = "adh1";
//   constant String s3[1,1,1,2] = "bdh1";
//   constant String s3[1,1,1,3] = "cdh1";
//   constant String s3[1,1,2,1] = "aeh1";
//   constant String s3[1,1,2,2] = "beh1";
//   constant String s3[1,1,2,3] = "ceh1";
//   constant String s3[1,1,3,1] = "afh1";
//   constant String s3[1,1,3,2] = "bfh1";
//   constant String s3[1,1,3,3] = "cfh1";
//   constant String s3[1,1,4,1] = "agh1";
//   constant String s3[1,1,4,2] = "bgh1";
//   constant String s3[1,1,4,3] = "cgh1";
//   constant String s3[2,1,1,1] = "adh2";
//   constant String s3[2,1,1,2] = "bdh2";
//   constant String s3[2,1,1,3] = "cdh2";
//   constant String s3[2,1,2,1] = "aeh2";
//   constant String s3[2,1,2,2] = "beh2";
//   constant String s3[2,1,2,3] = "ceh2";
//   constant String s3[2,1,3,1] = "afh2";
//   constant String s3[2,1,3,2] = "bfh2";
//   constant String s3[2,1,3,3] = "cfh2";
//   constant String s3[2,1,4,1] = "agh2";
//   constant String s3[2,1,4,2] = "bgh2";
//   constant String s3[2,1,4,3] = "cgh2";
//   constant String s3[3,1,1,1] = "adh3";
//   constant String s3[3,1,1,2] = "bdh3";
//   constant String s3[3,1,1,3] = "cdh3";
//   constant String s3[3,1,2,1] = "aeh3";
//   constant String s3[3,1,2,2] = "beh3";
//   constant String s3[3,1,2,3] = "ceh3";
//   constant String s3[3,1,3,1] = "afh3";
//   constant String s3[3,1,3,2] = "bfh3";
//   constant String s3[3,1,3,3] = "cfh3";
//   constant String s3[3,1,4,1] = "agh3";
//   constant String s3[3,1,4,2] = "bgh3";
//   constant String s3[3,1,4,3] = "cgh3";
//   constant String s3[4,1,1,1] = "adh4";
//   constant String s3[4,1,1,2] = "bdh4";
//   constant String s3[4,1,1,3] = "cdh4";
//   constant String s3[4,1,2,1] = "aeh4";
//   constant String s3[4,1,2,2] = "beh4";
//   constant String s3[4,1,2,3] = "ceh4";
//   constant String s3[4,1,3,1] = "afh4";
//   constant String s3[4,1,3,2] = "bfh4";
//   constant String s3[4,1,3,3] = "cfh4";
//   constant String s3[4,1,4,1] = "agh4";
//   constant String s3[4,1,4,2] = "bgh4";
//   constant String s3[4,1,4,3] = "cgh4";
// end ForIterator3;
// endResult
