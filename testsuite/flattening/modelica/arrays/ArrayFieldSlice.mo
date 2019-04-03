// name:     ArrayFieldSlice
// keywords: array
// status:   correct
//
// Drmodelica: 7.4  Array Indexing operator (p. 216)
//

record Person
  String       name;
  Integer       age;
  String[2]      children;
end Person;

function mkperson
  input String     name;
  input Integer   age;
  input String[2]  children;
  output Person p;
algorithm
  p.name       := name;
  p.age       := age;
  p.children     := children;
end mkperson;

class PersonList
  Person[3] persons = {mkperson("John", 35, {"Carl", "Eva"} ),
              mkperson("Karin", 40, {"Anders", "Dan"} ),
               mkperson("Lisa", 37, {"John", "Daniel"} )
        };
end PersonList;


class getPerson
  PersonList pList;
  String name[3];
  Integer age[3];
  String[3, 2] children;
equation
  name     = pList.persons.name;   // Returns: {"John", "Karin", "Lisa"}
  age     = pList.persons.age;  // Returns: {35, 40, 37}
  children   = pList.persons.children;  // Returns: {{"Carl", "Eva"},
                //     {"Anders", "Dan"},
                //     {"John", "Daniel"}}
end getPerson;

// Result:
// function Person "Automatically generated record constructor for Person"
//   input String name;
//   input Integer age;
//   input String[2] children;
//   output Person res;
// end Person;
//
// function mkperson
//   input String name;
//   input Integer age;
//   input String[2] children;
//   output Person p;
// algorithm
//   p.name := name;
//   p.age := age;
//   p.children := {children[1], children[2]};
// end mkperson;
//
// class getPerson
//   String pList.persons[1].name = "John";
//   Integer pList.persons[1].age = 35;
//   String pList.persons[1].children[1] = "Carl";
//   String pList.persons[1].children[2] = "Eva";
//   String pList.persons[2].name = "Karin";
//   Integer pList.persons[2].age = 40;
//   String pList.persons[2].children[1] = "Anders";
//   String pList.persons[2].children[2] = "Dan";
//   String pList.persons[3].name = "Lisa";
//   Integer pList.persons[3].age = 37;
//   String pList.persons[3].children[1] = "John";
//   String pList.persons[3].children[2] = "Daniel";
//   String name[1];
//   String name[2];
//   String name[3];
//   Integer age[1];
//   Integer age[2];
//   Integer age[3];
//   String children[1,1];
//   String children[1,2];
//   String children[2,1];
//   String children[2,2];
//   String children[3,1];
//   String children[3,2];
// equation
//   name[1] = pList.persons[1].name;
//   name[2] = pList.persons[2].name;
//   name[3] = pList.persons[3].name;
//   age[1] = pList.persons[1].age;
//   age[2] = pList.persons[2].age;
//   age[3] = pList.persons[3].age;
//   children[1,1] = pList.persons[1].children[1];
//   children[1,2] = pList.persons[1].children[2];
//   children[2,1] = pList.persons[2].children[1];
//   children[2,2] = pList.persons[2].children[2];
//   children[3,1] = pList.persons[3].children[1];
//   children[3,2] = pList.persons[3].children[2];
// end getPerson;
// endResult
