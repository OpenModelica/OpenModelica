// Do not modify this file: It was automatically generated from https://github.com/sjoelund/msgpack-modelica/
encapsulated package MessagePack "MessagePack is an efficient binary serialization format for multiple languages."
  encapsulated package Pack
    package SimpleBuffer
      class SimpleBuffer
        extends ExternalObject;

        function constructor
          output SimpleBuffer buf;

          external "C" buf = msgpack_modelica_sbuffer_new() annotation(Include = "#include <msgpack-modelica.h>", Library = "msgpackc");
        end constructor;

        function destructor
          input SimpleBuffer buf;

          external "C" msgpack_modelica_sbuffer_free(buf) annotation(Include = "#include <msgpack-modelica.h>", Library = "msgpackc");
        end destructor;
      end SimpleBuffer;

      function writeFile
        input SimpleBuffer sbuffer;
        input String file;

        external "C" msgpack_modelica_sbuffer_to_file(sbuffer, file) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
      end writeFile;

      function position
        input SimpleBuffer sbuffer;
        output Integer position;

        external "C" position = msgpack_modelica_sbuffer_position(sbuffer) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
      end position;
    end SimpleBuffer;

    class Packer
      extends ExternalObject;

      function constructor
        input SimpleBuffer.SimpleBuffer buf;
        output Packer packer;

        external "C" packer = msgpack_modelica_packer_new_sbuffer(buf) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
      end constructor;

      function destructor
        input Packer packer;

        external "C" msgpack_modelica_packer_free(packer) annotation(Include = "#include <msgpack-modelica.h>", Library = "msgpackc");
      end destructor;
    end Packer;

    function double
      input Packer packer;
      input Real dbl;
      output Boolean result;

      external "C" result = msgpack_modelica_pack_double(packer, dbl) annotation(Include = "#include <msgpack-modelica.h>", Library = "msgpackc");
    end double;

    function integer
      input Packer packer;
      input Integer i;
      output Boolean result;

      external "C" result = msgpack_modelica_pack_int(packer, i) annotation(Include = "#include <msgpack-modelica.h>", Library = "msgpackc");
    end integer;

    function bool
      input Packer packer;
      input Boolean bool;
      output Boolean result;
    protected
      function msgpack_pack_true
        input Packer packer;
        output Boolean result;

        external "C" result = msgpack_modelica_pack_true(packer) annotation(Include = "#include <msgpack-modelica.h>", Library = "msgpackc");
      end msgpack_pack_true;

      function msgpack_pack_false
        input Packer packer;
        output Boolean result;

        external "C" result = msgpack_modelica_pack_false(packer) annotation(Include = "#include <msgpack-modelica.h>", Library = "msgpackc");
      end msgpack_pack_false;
    algorithm
      result := if bool then msgpack_pack_true(packer) else msgpack_pack_false(packer);
    end bool;

    function sequence
      input Packer packer;
      input Integer len;
      output Boolean result;

      external "C" result = msgpack_modelica_pack_array(packer, len) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
    end sequence;

    function map
      input Packer packer;
      input Integer len;
      output Boolean result;

      external "C" result = msgpack_modelica_pack_map(packer, len) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
    end map;

    function string
      input Packer packer;
      input String str;
      output Boolean result;

      external "C" result = msgpack_modelica_pack_string(packer, str) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
    end string;

    function nil
      input Packer packer;
      output Boolean result;

      external "C" result = msgpack_modelica_pack_nil(packer) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
    end nil;
  end Pack;

  package Unpack
    class Deserializer
      extends ExternalObject;

      function constructor
        input String file;
        output Deserializer deserializer;

        external "C" deserializer = msgpack_modelica_new_deserialiser(file) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
      end constructor;

      function destructor
        input Deserializer deserializer;

        external "C" msgpack_modelica_free_deserialiser(deserializer) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
      end destructor;
    end Deserializer;

    function next
      input Deserializer deserializer;
      input Integer offset;
      output Boolean success;
      output Integer newoffset;

      external "C" success = msgpack_modelica_unpack_next(deserializer, offset, newoffset) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
    end next;

    function toStream
      input Deserializer deserializer;
      input Utilities.Stream.Stream ss;
      input Integer offset;
      output Integer newoffset;
      output Boolean success;

      external "C" success = msgpack_modelica_unpack_next_to_stream(deserializer, ss, offset, newoffset) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
    end toStream;

    function integer
      input Deserializer deserializer;
      input Integer offset;
      output Integer res;
      output Integer newoffset;
      output Boolean success;

      external "C" res = msgpack_modelica_unpack_int(deserializer, offset, newoffset, success) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
    end integer;

    function string
      input Deserializer deserializer;
      input Integer offset;
      output String res;
      output Integer newoffset;
      output Boolean success;

      external "C" res = msgpack_modelica_unpack_string(deserializer, offset, newoffset, success) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
    end string;

    function get_integer
      // TODO: Create package MessagePack.Object and move this there
      input Deserializer deserializer;
      output Integer res;

      external "C" res = msgpack_modelica_get_unpacked_int(deserializer) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
    end get_integer;
  end Unpack;

  package Utilities
    package Stream
      class Stream
        extends ExternalObject;

        function constructor
          input String file = "" "Output file or \"\" for an in-memory string accessible using get()";
          output Stream ss;

          external "C" ss = msgpack_modelica_new_stream(file) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
        end constructor;

        function destructor
          input Stream ss;

          external "C" msgpack_modelica_free_stream(ss) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
        end destructor;
      end Stream;

      function get "Only works for in-memory streams"
        // Make this a part of the Stream class once the Modelica Spec allows it...
        input Stream ss;
        output String str;

        external "C" str = msgpack_modelica_stream_get(ss) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
      end get;

      function append
        // Make this a part of the Stream class once the Modelica Spec allows it...
        input Stream ss;
        input String str;

        external "C" msgpack_modelica_stream_append(ss, str) annotation(Include = "#include <msgpack-modelica.h>", Library = {"msgpackc"});
      end append;
    end Stream;

    function deserializeFileToFile
      input String inBinaryFile;
      input String outTextFile;
      input String separator = "\n";
    protected
      Unpack.Deserializer deserializer = Unpack.Deserializer(inBinaryFile);
      Stream.Stream ss = Stream.Stream(outTextFile);
      Boolean success = true;
      Integer offset = 0;
    algorithm
      while success loop
        (offset, success) := Unpack.toStream(deserializer, ss, offset);
        if success then
          Stream.append(ss, separator);
        end if;
      end while;
    end deserializeFileToFile;
  end Utilities;

  package UsersGuide
    package License
      annotation(Documentation(info = "<html>
 <p>Copyright (c) 2014, Martin Sj&ouml;lund<br />
 All rights reserved.</p>

 <p>Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:</p>

 <ul>
 <li>Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.</li>
 <li>Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.</li>
 </ul>

 <p>THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.</p>

 </html>"));
    end License;
    annotation(Documentation(info = "<html>
 <p>This implementation uses <a href=\"https://github.com/msgpack/msgpack-c\">msgpack-c</a> together with external objects and external \"C\" functions (Modelica cannot represent binary objects, so everything has to be hidden inside external functions).</p>
 <p>You will need to install msgpack-c in order to use this Modelica package (msgpack.h and libmsgpack-c.*).</p>
 <p>The external C code of this package is inserted using Include annotations, so there should be no need to compile any libraries prior to using the package.</p>
 </html>"));
  end UsersGuide;
  annotation(version = "0.1", __OpenModelica_Interface="util", Documentation(info = "<html>
 <p>MessagePack is an efficient binary serialization format for multiple languages. Details on the binary format can be found on <a href=\"http://msgpack.org\">msgpack.org</a>.</p>
 </html>"));
end MessagePack;
