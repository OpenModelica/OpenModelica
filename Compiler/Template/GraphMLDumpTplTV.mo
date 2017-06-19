interface package GraphMLDumpTplTV

  package builtin
    function arrayGet
      replaceable type TypeVar subtypeof Any;
      input array<TypeVar> arr;
      input Integer index;
      output TypeVar value;
    end arrayGet;

    function arrayLength
      replaceable type TypeVar subtypeof Any;
      input array<TypeVar> arr;
      output Integer length;
    end arrayLength;

    function listReverse
      replaceable type TypeVar subtypeof Any;
      input list<TypeVar> lst;
      output list<TypeVar> result;
    end listReverse;

    function listLength "Return the length of the list"
      replaceable type TypeVar subtypeof Any;
      input list<TypeVar> lst;
      output Integer result;
    end listLength;

    function intAdd
      input Integer a;
      input Integer b;
      output Integer c;
    end intAdd;

    function boolAnd
      input Boolean b1;
      input Boolean b2;
      output Boolean b;
    end boolAnd;

    function boolOr
      input Boolean a;
      input Boolean b;
      output Boolean c;
    end boolOr;

    function boolNot
      input Boolean b;
      output Boolean nb;
    end boolNot;

    function intSub
      input Integer a;
      input Integer b;
      output Integer c;
    end intSub;

    function intMul
      input Integer a;
      input Integer b;
      output Integer c;
    end intMul;

    function intDiv
      input Integer a;
      input Integer b;
      output Integer c;
    end intDiv;

    function intEq
      input Integer a;
      input Integer b;
      output Boolean c;
    end intEq;

    function intGt
      input Integer i1;
      input Integer i2;
      output Boolean b;
    end intGt;

    function realInt
      input Real r;
      output Integer i;
    end realInt;

    function realString
      input Real r;
      output String s;
    end realString;

    function arrayList
      replaceable type TypeVar subtypeof Any;
      input array<TypeVar> arr;
      output list<TypeVar> lst;
    end arrayList;

    function stringEq
      input String s1;
      input String s2;
      output Boolean b;
    end stringEq;

    function listAppend
      replaceable type TypeVar subtypeof Any;
      input list<TypeVar> lst;
      input list<TypeVar> lst1;
      output list<TypeVar> result;
    end listAppend;

    function realDiv
      input Real x;
      input Real y;
      output Real z;
    end realDiv;
  end builtin;

  package Tpl
    function textFile
      input Text inText;
      input String inFileName;
    end textFile;
  end Tpl;

  package Util
    function tuple21
      replaceable type TypeA subtypeof Any;
      input tuple<TypeA, TypeB> inTplTypeATypeB;
      output TypeA outTypeA;
      replaceable type TypeB subtypeof Any;
    end tuple21;
    function tuple22
      replaceable type TypeA subtypeof Any;
      input tuple<TypeA, TypeB> inTplTypeATypeB;
      output TypeA outTypeA;
      replaceable type TypeB subtypeof Any;
    end tuple22;
  end Util;

  package GraphML
    uniontype GraphInfo
      record GRAPHINFOARR
        array<Graph> graphs;
        array<Node> nodes;
        list<Edge> edges;
        array<Attribute> attributes;
        String graphNodeKey;
        String graphEdgeKey;
      end GRAPHINFOARR;
    end GraphInfo;

    uniontype Graph
      record GRAPH
        String id;
        Boolean directed;
        list<Integer> nodeIdc;
        list<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPHINFO definition). <attributeIndex,attributeValue>
      end GRAPH;
    end Graph;

    uniontype Node
      record NODE
        String id;
        String color;
        Real border;
        list<NodeLabel> nodeLabels;
        ShapeType shapeType;
        Option<String> optDesc;
        list<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPH definition). <attributeIndex,attributeValue>
      end NODE;
      record GROUPNODE
        String id;
        Integer internalGraphIdx;
        Boolean isFolded;
        String header;
      end GROUPNODE;
    end Node;

    uniontype Edge
      record EDGE
        String id;
        String target;
        String source;
        String color;
        LineType lineType;
        Real lineWidth;
        Boolean smooth;
        list<EdgeLabel> edgeLabels;
        tuple<ArrowType,ArrowType> arrows;
        list<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPH definition). <attributeIndex,attributeValue>
      end EDGE;
    end Edge;

    uniontype NodeLabel
      record NODELABEL_INTERNAL
        String text;
        Option<String> backgroundColor;
        FontStyle fontStyle;
      end NODELABEL_INTERNAL;
      record NODELABEL_CORNER
        String text;
        Option<String> backgroundColor;
        FontStyle fontStyle;
        String position; //for example "se" for south east
      end NODELABEL_CORNER;
    end NodeLabel;

    uniontype EdgeLabel
      record EDGELABEL
        String text;
        Option<String> backgroundColor;
        Integer fontSize;
      end EDGELABEL;
    end EdgeLabel;

    uniontype FontStyle
      record FONTPLAIN end FONTPLAIN;
      record FONTBOLD end FONTBOLD;
      record FONTITALIC end FONTITALIC;
      record FONTBOLDITALIC end FONTBOLDITALIC;
    end FontStyle;

    uniontype ShapeType
      record RECTANGLE end RECTANGLE;
      record ROUNDRECTANGLE end ROUNDRECTANGLE;
      record ELLIPSE end ELLIPSE;
      record PARALLELOGRAM end PARALLELOGRAM;
      record HEXAGON end HEXAGON;
      record TRIANGLE end TRIANGLE;
      record OCTAGON end OCTAGON;
      record DIAMOND end DIAMOND;
      record TRAPEZOID end TRAPEZOID;
      record TRAPEZOID2 end TRAPEZOID2;
    end ShapeType;

    uniontype LineType
      record LINE end LINE;
      record DASHED end DASHED;
      record DASHEDDOTTED end DASHEDDOTTED;
    end LineType;

    uniontype ArrowType
      record ARROWSTANDART end ARROWSTANDART;
      record ARROWNONE end ARROWNONE;
      record ARROWCONCAVE end ARROWCONCAVE;
    end ArrowType;

    uniontype Attribute
      record ATTRIBUTE
        Integer attIdx;
        String defaultValue;
        String name;
        AttributeType attType;
        AttributeTarget attTarget;
      end ATTRIBUTE;
    end Attribute;

    uniontype AttributeType
      record TYPE_STRING end TYPE_STRING;
      record TYPE_BOOLEAN end TYPE_BOOLEAN;
      record TYPE_INTEGER end TYPE_INTEGER;
      record TYPE_DOUBLE end TYPE_DOUBLE;
    end AttributeType;

    uniontype AttributeTarget
      record TARGET_NODE end TARGET_NODE;
      record TARGET_EDGE end TARGET_EDGE;
      record TARGET_GRAPH end TARGET_GRAPH;
    end AttributeTarget;

  end GraphML;

end GraphMLDumpTplTV;
