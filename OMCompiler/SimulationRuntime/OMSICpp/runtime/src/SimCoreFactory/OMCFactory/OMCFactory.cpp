/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/** @addtogroup simcorefactoryOMCFactory
 *
 *  @{
 */

#ifdef _WIN32
  #include <winsock2.h>
  typedef SOCKET socket_t;
  #define OMC_INVALID_SOCKET INVALID_SOCKET
  #define omc_closesocket closesocket
#else
  #include <arpa/inet.h>
  #include <netinet/in.h>
  #include <sys/socket.h>
  #include <unistd.h>
  typedef int socket_t;
  #define OMC_INVALID_SOCKET (-1)
  #define omc_closesocket close
#endif
#ifndef MSG_NOSIGNAL
  #define MSG_NOSIGNAL 0
#endif

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/SimController/ISimController.h>
#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>

#include <cerrno>
#include <climits>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <functional>
#include <optional>

namespace fs = std::filesystem;

static std::string socketError()
{
#ifdef _WIN32
    return "error " + std::to_string(WSAGetLastError());
#else
    return strerror(errno);
#endif
}

/**
  * Logger for XML messages through TCP port
  */
class LoggerXMLTCP: public LoggerXML
{
  public:
    virtual ~LoggerXMLTCP()
    {
        omc_closesocket(_socket);
#ifdef _WIN32
        WSACleanup();
#endif
    }

    static void initialize(int port, LogSettings &logSettings)
    {
        _instance = new LoggerXMLTCP(port, logSettings);
    }

  protected:
    LoggerXMLTCP(int port, LogSettings &logSettings)
        : LoggerXML(logSettings, true, _sstream)
        , _socket(OMC_INVALID_SOCKET)
    {
        if (logSettings.format != LF_XML && logSettings.format != LF_XMLTCP) {
            throw ModelicaSimulationError(MODEL_FACTORY,
                "xmltcp logger requires log-format xml");
        }
#ifdef _WIN32
        WSADATA wsaData;
        if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0)
            throw std::runtime_error("WSAStartup failed");
#endif
        _socket = socket(AF_INET, SOCK_STREAM, 0);
        if (_socket == OMC_INVALID_SOCKET) {
            std::string err = socketError();
#ifdef _WIN32
            WSACleanup();
#endif
            throw std::runtime_error("socket: " + err);
        }
#ifdef SO_NOSIGPIPE
        int on = 1;
        setsockopt(_socket, SOL_SOCKET, SO_NOSIGPIPE, &on, sizeof(on));
#endif
        sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons((unsigned short)port);
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        if (connect(_socket, (sockaddr*)&addr, sizeof(addr)) != 0) {
            std::string err = socketError();
            omc_closesocket(_socket);
#ifdef _WIN32
            WSACleanup();
#endif
            throw std::runtime_error("connect: " + err);
        }
    }

    void sendString(const std::string& str)
    {
        const char* p = str.data();
        size_t left = str.size();
        while (left > 0) {
            int n = send(_socket, p, (int)left, MSG_NOSIGNAL);
            if (n <= 0)
                throw std::runtime_error("send: " + socketError());
            p += n;
            left -= n;
        }
    }

    virtual void writeInternal(string msg, LogCategory cat, LogLevel lvl,
                                                          LogStructure ls)
    {
        _sstream.str("");
        LoggerXML::writeInternal(msg, cat, lvl, ls);
        if (_logSettings.format == LF_XMLTCP)
            sendString(_sstream.str());
        else
            std::cout << _sstream.str();
    }

    virtual void statusInternal(const char *phase, double currentTime, double currentStepSize)
    {
        int completion = _endTime <= _startTime? 0:
            (int)((currentTime - _startTime) / (_endTime - _startTime) * 10000);
        if (_logSettings.format == LF_XMLTCP) {
            _sstream.str("");
            _sstream << "<status phase=\"" << phase
                              << "\" time=\"" << currentTime
                              << "\" currentStepSize=\"" << currentStepSize
                              << "\" progress=\"" << completion
                              << "\" />" << std::endl;
            sendString(_sstream.str());
        }
        else {
            // send status in old format for backwards compatibility
            _sstream.str("");
            _sstream << completion << " " << phase << std::endl;
            sendString(_sstream.str());
        }
    }

    socket_t _socket;
    std::stringstream _sstream;
};


namespace {

/**
  * Command line parser: --name[=value] and -name[=value] for long names,
  * -X[value] for short ones; a missing value is taken from the next argument.
  */
class CommandLine
{
  public:
    enum Kind { FLAG, VALUE, VALUES };
    enum Type { STRING, REAL, INT, UINT, BOOL };

    void add(const string& name, char shortName, Kind kind, Type type,
                      const string& help, std::optional<string> defaultValue = std::nullopt,
                      bool hidden = false)
    {
        Option o = {name, shortName, kind, type, help, defaultValue, hidden, {}};
        if (kind == FLAG)
            o.defaultValue = "false";
        _options.push_back(o);
    }

    /** Returns the arguments that are not registered options. */
    vector<string> parse(int argc, const char* argv[],
                                              const std::function<pair<string, string>(const string&)>& extraParser)
    {
        vector<string> unrecognized;
        vector<string> args(argv + 1, argv + argc);
        for (size_t i = 0; i < args.size(); i++) {
            const string& tok = args[i];
            Option* opt = nullptr;
            std::optional<string> value;
            pair<string, string> replaced = extraParser(tok);
            if (!replaced.first.empty()) {
                opt = findLong(replaced.first);
                if (!replaced.second.empty())
                    value = replaced.second;
            }
            else if (tok.size() >= 3 && tok[0] == '-' && tok[1] == '-') {
                opt = findLong(tok.substr(2, tok.find('=') - 2));
                value = adjacentValue(tok);
            }
            else if (tok.size() >= 2 && tok[0] == '-') {
                if ((opt = findLong(tok.substr(1, tok.find('=') - 1))))
                    value = adjacentValue(tok);
                else if ((opt = findShort(tok[1])) && tok.size() > 2)
                    value = tok.substr(tok[2] == '=' ? 3 : 2);
            }
            if (!opt) {
                unrecognized.push_back(tok);
                continue;
            }
            if (opt->kind == FLAG) {
                if (value)
                    throw std::invalid_argument("option '--" + opt->name + "' does not take any arguments");
                value = "true";
            }
            else if (!value) {
                if (i + 1 == args.size() || isOption(args[i + 1]))
                    throw std::invalid_argument("the required argument for option '--" + opt->name + "' is missing");
                value = args[++i];
            }
            store(*opt, *value);
        }
        return unrecognized;
    }

    size_t count(const string& name) const
    {
        const Option& o = get(name);
        return !o.values.empty() || o.defaultValue ? 1 : 0;
    }

    const string& str(const string& name) const
    {
        const Option& o = get(name);
        return o.values.empty() ? *o.defaultValue : o.values.front();
    }

    const vector<string>& values(const string& name) const { return get(name).values; }
    double real(const string& name) const { return std::strtod(str(name).c_str(), nullptr); }
    int integer(const string& name) const { return (int)std::strtol(str(name).c_str(), nullptr, 10); }
    unsigned int uinteger(const string& name) const { return (unsigned int)std::strtoul(str(name).c_str(), nullptr, 10); }
    bool flag(const string& name) const { return str(name) == "true"; }
    bool boolean(const string& name) const { return *parseBool(str(name)); }

    void printHelp(std::ostream& os) const
    {
        vector<string> left;
        size_t width = 0;
        for (const Option& o : _options) {
            string l = o.shortName ? string("-") + o.shortName + " [ --" + o.name + " ]" : "--" + o.name;
            if (o.kind != FLAG)
                l += o.defaultValue ? " arg (=" + *o.defaultValue + ")" : " arg";
            width = (std::max)(width, l.size());
            left.push_back(l);
        }
        os << "Allowed options:" << std::endl;
        for (size_t i = 0; i < _options.size(); i++)
            if (!_options[i].hidden)
                os << "  " << left[i] << string(width - left[i].size() + 2, ' ') << _options[i].help << std::endl;
    }

  private:
    struct Option
    {
        string name;
        char shortName;
        Kind kind;
        Type type;
        string help;
        std::optional<string> defaultValue;
        bool hidden;
        vector<string> values;
    };

    Option* findLong(const string& name)
    {
        for (Option& o : _options)
            if (o.name == name)
                return &o;
        return nullptr;
    }

    Option* findShort(char c)
    {
        for (Option& o : _options)
            if (o.shortName == c)
                return &o;
        return nullptr;
    }

    const Option& get(const string& name) const
    {
        for (const Option& o : _options)
            if (o.name == name)
                return o;
        throw std::logic_error("unknown option " + name);
    }

    bool isOption(const string& tok)
    {
        if (tok.size() == 2 && tok[0] == '-')
            return findShort(tok[1]) != nullptr;
        return tok.size() > 2 && tok[0] == '-' && tok[1] == '-' && findLong(tok.substr(2, tok.find('=') - 2));
    }

    std::optional<string> adjacentValue(const string& tok)
    {
        size_t eq = tok.find('=');
        if (eq == string::npos)
            return std::nullopt;
        if (eq + 1 == tok.size())
            throw std::invalid_argument("the argument for option '" + tok + "' should follow immediately after the equal sign");
        return tok.substr(eq + 1);
    }

    static std::optional<bool> parseBool(string s)
    {
        std::transform(s.begin(), s.end(), s.begin(), ::tolower);
        if (s == "true" || s == "yes" || s == "on" || s == "1")
            return true;
        if (s == "false" || s == "no" || s == "off" || s == "0")
            return false;
        return std::nullopt;
    }

    void store(Option& o, const string& value)
    {
        if (o.kind != VALUES && !o.values.empty())
            throw std::invalid_argument("option '--" + o.name + "' cannot be specified more than once");
        const char* begin = value.c_str();
        char* end = nullptr;
        errno = 0;
        switch (o.type) {
            case REAL: std::strtod(begin, &end); break;
            case INT: {
                long l = std::strtol(begin, &end, 10);
                if (l < INT_MIN || l > INT_MAX)
                    errno = ERANGE;
                break;
            }
            case UINT: std::strtoul(begin, &end, 10); break;
            case BOOL:
            case STRING: break;
        }
        if ((o.type == BOOL && !parseBool(value)) ||
            (o.type != STRING && o.type != BOOL && (value.empty() || *end != '\0' || errno == ERANGE)))
            throw std::invalid_argument("the argument ('" + value + "') for option '--" + o.name + "' is invalid");
        o.values.push_back(value);
    }

    vector<Option> _options;
};

vector<string> split(const string& str, const char* seps)
{
    vector<string> parts;
    size_t start = 0, pos;
    while ((pos = str.find_first_of(seps, start)) != string::npos) {
        parts.push_back(str.substr(start, pos - start));
        start = pos + 1;
    }
    parts.push_back(str.substr(start));
    return parts;
}

}

inline void normalizePath(std::string& path)
{
    if (path.length() > 0 && path[path.length() - 1] != '/')
        path += "/";
}

/**
 * Implementation of OMCFactory
 */
OMCFactory::OMCFactory(PATH library_path, PATH modelicasystem_path)
    : _library_path(library_path)

    , _modelicasystem_path(modelicasystem_path)
    #if defined(RUNTIME_STATIC_LINKING)
	, _defaultLinSolver("dgesvSolver")
	#else
	, _defaultLinSolver("linearSolver")
    #endif
	, _defaultNonLinSolver("kinsol")
    , _use_zeroMQ(false)

{
    fillArgumentsToIgnore();
    fillArgumentsToReplace();
}

OMCFactory::OMCFactory()
    : _library_path("")

    , _modelicasystem_path("")
    #if defined(RUNTIME_STATIC_LINKING)
	, _defaultLinSolver("dgesvSolver")
	#else
	, _defaultLinSolver("linearSolver")
    #endif
    , _defaultNonLinSolver("kinsol")
    , _use_zeroMQ(false)

{
    fillArgumentsToIgnore();
    fillArgumentsToReplace();
}

OMCFactory::~OMCFactory()
{
}

void OMCFactory::UnloadAllLibs(void)
{
    map<string, shared_library>::iterator iter;
    for (iter = _modules.begin(); iter != _modules.end(); ++iter)
    {
        UnloadLibrary(iter->second);
    }
}

pair<string, string> OMCFactory::parseIngoredAndWrongFormatOption(const string& s)
{
    int sep = s.find("=");
    string key = s;
    if (sep > 0)
        key = s.substr(0, sep);

    if (_argumentsToIgnore.find(key) != _argumentsToIgnore.end())
        return make_pair(string("ignored"), s);

    if (sep > 2 && s[0] == '-' && s[1] != '-')
        return make_pair(string("unrecognized"), s);
    else
        return make_pair(string(), string());
}

static LogSettings initializeLogger(const CommandLine& vm)
{
    map<string, LogCategory> logCatMap = MAP_LIST_OF
    "init", LC_INIT
    MAP_LIST_SEP
    "nls", LC_NLS
    MAP_LIST_SEP
    "ls", LC_LS
    MAP_LIST_SEP
    "solver", LC_SOLVER
    MAP_LIST_SEP
    "output", LC_OUTPUT
    MAP_LIST_SEP
    "events", LC_EVENTS
    MAP_LIST_SEP
    "model", LC_MODEL
    MAP_LIST_SEP
    "other", LC_OTHER
    MAP_LIST_END;
    map<string, LogLevel> logLvlMap = MAP_LIST_OF
    "error", LL_ERROR
    MAP_LIST_SEP
    "warning", LL_WARNING
    MAP_LIST_SEP
    "info", LL_INFO
    MAP_LIST_SEP
    "debug", LL_DEBUG
    MAP_LIST_END;
    map<string, LogFormat> logFormatMap = MAP_LIST_OF
    "txt", LF_TXT
    MAP_LIST_SEP
    "xml", LF_XML
    MAP_LIST_SEP
    "xmltcp", LF_XMLTCP
    MAP_LIST_END;
    map<string, LogOMEdit> logOMEditMap = MAP_LIST_OF
    "LOG_EVENTS", LOG_EVENTS
    MAP_LIST_SEP
    "LOG_INIT", LOG_INIT
    MAP_LIST_SEP
    "LOG_LS", LOG_LS
    MAP_LIST_SEP
    "LOG_NLS", LOG_NLS
    MAP_LIST_SEP
    "LOG_SOLVER", LOG_SOLVER
    MAP_LIST_SEP
    "LOG_STATS", LOG_STATS
    MAP_LIST_END;

    LogSettings logSettings;
    std::string logOMEditWarning;
    if (vm.count("log-settings"))
    {
        const vector<string>& log_vec = vm.values("log-settings");
        for (int i = 0; i < log_vec.size(); i++)
        {
            // translate XML stream options to native options
            if (log_vec[i].compare(0, 4, "LOG_") == 0)
            {
                LogOMEdit logOMEdit;
                vector<string> tmpvec = split(log_vec[i], ",");
                for (int j = 0; j < tmpvec.size(); j++)
                {
                    if (logOMEditMap.find(tmpvec[j]) != logOMEditMap.end())
                        logOMEdit = logOMEditMap[tmpvec[j]];
                    else
                    {
                        if (logOMEditWarning.size() > 0)
                            logOMEditWarning += ",";
                        logOMEditWarning += tmpvec[j];
                        continue;
                    }
                    switch (logOMEdit)
                    {
                    case LOG_EVENTS:
                        logSettings.modes[LC_EVENTS] = LL_DEBUG;
                        break;
                    case LOG_INIT:
                        logSettings.modes[LC_INIT] = LL_DEBUG;
                        break;
                    case LOG_LS:
                        logSettings.modes[LC_LS] = LL_DEBUG;
                        break;
                    case LOG_NLS:
                        logSettings.modes[LC_NLS] = LL_DEBUG;
                        break;
                    case LOG_SOLVER:
                        logSettings.modes[LC_SOLVER] = LL_DEBUG;
                        //case LOG_STATS:
                    default:
                        if (logSettings.modes[LC_SOLVER] < LL_INFO)
                            logSettings.modes[LC_SOLVER] = LL_INFO;
                    }
                }
            }
                // treat native option
            else
            {
                vector<string> tmpvec = split(log_vec[i], "=");

                if (tmpvec.size() > 1 && logLvlMap.find(tmpvec[1]) != logLvlMap.end()
                    && (tmpvec[0] == "all" || logCatMap.find(tmpvec[0]) != logCatMap.end()))
                {
                    if (tmpvec[0] == "all")
                    {
                        logSettings.setAll(logLvlMap[tmpvec[1]]);
                        break;
                    }
                    else
                        logSettings.modes[logCatMap[tmpvec[0]]] = logLvlMap[tmpvec[1]];
                }
                else
                    throw ModelicaSimulationError(MODEL_FACTORY,
                                                  "log-settings flags not supported: " + log_vec[i] + "\n");
            }
        }
    }

    if (vm.flag("warn-all"))
    {
        for (int i = 0; i < logSettings.modes.size(); i++)
            if (logSettings.modes[i] < LL_WARNING)
                logSettings.modes[i] = LL_WARNING;
    }

    if (vm.count("log-format"))
    {
        string logFormat_str = vm.str("log-format");
        if (logFormatMap.find(logFormat_str) != logFormatMap.end())
            logSettings.format = logFormatMap[logFormat_str];
        else
            throw ModelicaSimulationError(MODEL_FACTORY,
                                          "Unknown log-format " + logFormat_str);
    }

    // make sure other infos get issued and initialize logger
    if (logSettings.modes[LC_OTHER] < LL_INFO)
        logSettings.modes[LC_OTHER] = LL_INFO;

    // initialize logger if it has been enabled
    if (Logger::isEnabled())
    {
        int port = vm.integer("log-port");
        if (port > 0)
        {
            try
            {
                LoggerXMLTCP::initialize(port, logSettings);
            }
            catch (std::exception& ex)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,
                                              "Failed to start logger with port " + to_string(port) + ": "
                                              + ex.what() + '\n');
            }
        }
        else
            Logger::initialize(logSettings);
    }

    if (logOMEditWarning.size() > 0)
    {
        LOGGER_WRITE("Warning: unrecognized logging " + logOMEditWarning,
                     LC_OTHER, LL_WARNING);
        ostringstream os;
        os << "Supported are: ";
        map<std::string, LogOMEdit>::const_iterator it;
        for (it = logOMEditMap.begin(); it != logOMEditMap.end(); ++it)
        {
            if (it != logOMEditMap.begin())
                os << ",";
            os << it->first;
        }
        LOGGER_WRITE(os.str(), LC_OTHER, LL_INFO);
    }

    return logSettings;
}



SimSettings OMCFactory::readSimulationParameter(int argc, const char* argv[])
{
     int opt;
     int portnum;
     map<string, OutputPointType> outputPointTypeMap = MAP_LIST_OF
       "all", OPT_ALL MAP_LIST_SEP "step", OPT_STEP MAP_LIST_SEP
       "none", OPT_NONE MAP_LIST_END;
     map<string, OutputFormat> outputFormatMap = MAP_LIST_OF
       "csv", CSV MAP_LIST_SEP "mat", MAT MAP_LIST_SEP
       "buffer", BUFFER MAP_LIST_SEP "empty", EMPTY MAP_LIST_END;
     map<string, EmitResults> emitResultsMap = MAP_LIST_OF
       "all", EMIT_ALL MAP_LIST_SEP "public", EMIT_PUBLIC MAP_LIST_SEP
       "none", EMIT_NONE MAP_LIST_END;
     CommandLine vm;

     //program options that can be overwritten by OMEdit must be declared as VALUES
     //so that the same value can be set multiple times
     //(e.g. 'executable -F arg1 -r=arg2' -> 'executable -F arg1 -F=arg2')
     //the variables of OMEdit are always the first elements of the result vectors, if they are set
     vm.add("help", 0, CommandLine::FLAG, CommandLine::STRING, "produce help message");
     vm.add("nls-continue", 0, CommandLine::FLAG, CommandLine::STRING, "non linear solver will continue if it can not reach the given precision");
     vm.add("runtime-library", 'R', CommandLine::VALUE, CommandLine::STRING, "path to cpp runtime libraries");
     vm.add("modelica-system-library", 'M', CommandLine::VALUE, CommandLine::STRING, "path to Modelica library");
     vm.add("input-path", 0, CommandLine::VALUE, CommandLine::STRING, "directory with input files, like init xml (defaults to modelica-system-library)");
     vm.add("output-path", 0, CommandLine::VALUE, CommandLine::STRING, "directory for output files, like results (defaults to modelica-system-library)");
     vm.add("results-file", 'F', CommandLine::VALUES, CommandLine::STRING, "name of results file");
     vm.add("start-time", 'S', CommandLine::VALUE, CommandLine::REAL, "simulation start time", "0");
     vm.add("stop-time", 'E', CommandLine::VALUE, CommandLine::REAL, "simulation stop time", "1");
     vm.add("step-size", 'H', CommandLine::VALUE, CommandLine::REAL, "simulation step size", "0");
     vm.add("solver", 'I', CommandLine::VALUE, CommandLine::STRING, "solver method", "euler");
     vm.add("lin-solver", 'L', CommandLine::VALUE, CommandLine::STRING, "linear solver method", _defaultLinSolver);
     vm.add("non-lin-solver", 'N', CommandLine::VALUE, CommandLine::STRING, "non linear solver method", _defaultNonLinSolver);
     vm.add("number-of-intervals", 'G', CommandLine::VALUE, CommandLine::INT, "number of intervals in equidistant grid", "500");
     vm.add("tolerance", 'T', CommandLine::VALUE, CommandLine::REAL, "solver tolerance", "1e-06");
     vm.add("warn-all", 'W', CommandLine::FLAG, CommandLine::STRING, "issue all warning messages");
     vm.add("log-settings", 'V', CommandLine::VALUES, CommandLine::STRING, "log information: init, nls, ls, solver, output, events, model, other");
     vm.add("log-format", 'X', CommandLine::VALUE, CommandLine::STRING, "log format: txt, xml, xmltcp", "txt");
     vm.add("log-port", 0, CommandLine::VALUE, CommandLine::INT, "tcp port for log messages (default 0 meaning stdout/stderr)", "0");
     vm.add("alarm", 'A', CommandLine::VALUE, CommandLine::UINT, "sets timeout in seconds for simulation", "360");
     vm.add("output-type", 'O', CommandLine::VALUE, CommandLine::STRING, "the points in time written to result file: all (output steps + events), step (just output points), none", "all");
     vm.add("output-format", 'P', CommandLine::VALUE, CommandLine::STRING, "simulation results output format: csv, mat, buffer, empty", "mat");
     vm.add("emit-results", 'U', CommandLine::VALUE, CommandLine::STRING, "emit results: all, public, none", "public");
     vm.add("use-zeromq", 'u', CommandLine::VALUE, CommandLine::BOOL, "use zeromq for communication during simulation with other applications", "false");
     vm.add("port-publish", 'p', CommandLine::VALUE, CommandLine::INT, "zeromq publishing port", "3203");
     vm.add("port-subscribe", 's', CommandLine::VALUE, CommandLine::INT, "zeromq subscribing port", "3204");
     vm.add("zeromq-job-id", 'g', CommandLine::VALUE, CommandLine::STRING, "ID that identifies the translation and simulation for one model", "empty");
     vm.add("zeromq-server-id", 'v', CommandLine::VALUE, CommandLine::STRING, "ID that identifies the omc zeromq application that receives omc api commands via zeromq", "empty");
     vm.add("zeromq-client-id", 'c', CommandLine::VALUE, CommandLine::STRING, "ID that identifies the client application that uses the omc zeromq application", "empty");
     vm.add("omsu-name", 'o', CommandLine::VALUE, CommandLine::STRING, "name of omsu or fmu 2.0 ME", "");
     vm.add("omsu-path", 'a', CommandLine::VALUE, CommandLine::STRING, "path for omsu or fmu 2.0 ME", "");
     vm.add("init-file", 'i', CommandLine::VALUE, CommandLine::STRING, "path for omsu or fmu 2.0 ME initialisation xml-file", "");
     vm.add("ignored", 0, CommandLine::VALUES, CommandLine::STRING, "ignored options", std::nullopt, true);
     vm.add("unrecognized", 0, CommandLine::VALUES, CommandLine::STRING, "unsupported options", std::nullopt, true);
     vm.add("solver-threads", 0, CommandLine::VALUE, CommandLine::INT, "number of threads that can be used by the solver", "1", true);

     vector<string> unrecognized;
     try {
       unrecognized = vm.parse(argc, argv, [this](const string& arg) { return parseIngoredAndWrongFormatOption(arg); });
     }
     catch (std::exception& ex) {
         throw ModelicaSimulationError(MODEL_FACTORY, ex.what());
     }

     if (vm.flag("help")) {
         vm.printHelp(cout);
         throw ModelicaSimulationError(MODEL_FACTORY, "Cannot parse command line arguments correctly, because the help message was requested.", "",true);
     }

     LogSettings logSettings = initializeLogger(vm);

     // warn about unrecognized command line options
     const vector<string>& opts = vm.values("unrecognized");
     unrecognized.insert(unrecognized.begin(), opts.begin(), opts.end());
     if (unrecognized.size() > 0) {
         ostringstream os;
         os << "Warning: unrecognized command line options ";
         copy(unrecognized.begin(), unrecognized.end(), ostream_iterator<string>(os, " "));
         LOGGER_WRITE(os.str(), LC_OTHER, LL_WARNING);
     }

     string runtime_lib_path;
     string modelica_lib_path;
     string init_file_path;
     string omsu_path;
     string omsu_name;
     double starttime =  vm.real("start-time");
     double stoptime = vm.real("stop-time");
     double stepsize =vm.real("step-size");
     bool nlsContinueOnError = vm.flag("nls-continue");
     int solverThreads = vm.integer("solver-threads");

     if (!(stepsize > 0.0))
         stepsize = (stoptime - starttime) / vm.integer("number-of-intervals");

     double tolerance = vm.real("tolerance");
     string solver = vm.str("solver");
     string nonLinSolver = vm.str("non-lin-solver");
     string linSolver = vm.str("lin-solver");
     unsigned int timeOut = vm.uinteger("alarm");
     if (vm.count("runtime-library"))
     {
         runtime_lib_path = vm.str("runtime-library");
         normalizePath(runtime_lib_path);
     }
     else
         throw ModelicaSimulationError(MODEL_FACTORY,"runtime libraries path is not set");
     if (vm.count("omsu-name"))
     {
         omsu_name = vm.str("omsu-name");
     }
     if (vm.count("omsu-path"))
     {
         omsu_path = vm.str("omsu-path");
     }
     if (vm.count("init-file"))
     {
         init_file_path = vm.str("init-file");
     }

     if (vm.count("modelica-system-library"))
     {
         modelica_lib_path = vm.str("modelica-system-library");
         normalizePath(modelica_lib_path);
     }
     else
         throw ModelicaSimulationError(MODEL_FACTORY,"Modelica library path is not set");

     string inputPath, outputPath;
     if (vm.count("input-path")) {
         inputPath = vm.str("input-path");
         normalizePath(inputPath);
     }
     else
         inputPath = modelica_lib_path;
     if (vm.count("output-path")) {
         outputPath = vm.str("output-path");
         normalizePath(outputPath);
     }
     else
         outputPath = modelica_lib_path;

     string resultsfilename;
     if (vm.count("results-file"))
     {
         resultsfilename = vm.values("results-file").front();
     }
     else
         throw ModelicaSimulationError(MODEL_FACTORY,"results-filename is not set");

     OutputPointType outputPointType;
     if (vm.count("output-type"))
     {
       string outputType_str = vm.str("output-type");
       if (outputPointTypeMap.find(outputType_str) != outputPointTypeMap.end())
         outputPointType = outputPointTypeMap[outputType_str];
       else
         throw ModelicaSimulationError(MODEL_FACTORY,
           "Unknown output-type " + outputType_str);
     }
     else
       throw ModelicaSimulationError(MODEL_FACTORY, "output-type is not set");

     OutputFormat outputFormat;
     if (vm.count("output-format"))
     {
       string outputFormat_str = vm.str("output-format");
       if (outputFormatMap.find(outputFormat_str) != outputFormatMap.end())
         outputFormat = outputFormatMap[outputFormat_str];
       else
         throw ModelicaSimulationError(MODEL_FACTORY,
           "Unknown output-format " + outputFormat_str);
     }
     else
       throw ModelicaSimulationError(MODEL_FACTORY, "output-format is not set");

     EmitResults emitResults = EMIT_PUBLIC; // emit public per default for OMC use
     if (vm.count("emit-results"))
     {
       string emitResults_str = vm.str("emit-results");
       if (emitResultsMap.find(emitResults_str) != emitResultsMap.end())
         emitResults = emitResultsMap[emitResults_str];
       else
         throw ModelicaSimulationError(MODEL_FACTORY,
           "Unknown emit-results " + emitResults_str);
     }

     int port_pub =3203;
     int port_sub = 3204;
     string zeromq_job_id = "empty";
     string zeromq_server_id = "empty";
     string zeromq_client_id = "empty";
     
     if (vm.count("port-publish"))
     {
         port_pub = vm.integer("port-publish");
     }
    
     if (vm.count("port-subscribe"))
     {
         port_sub = vm.integer("port-subscribe");
     }
     
    if (vm.count("zeromq-job-id"))
     {
         zeromq_job_id = vm.str("zeromq-job-id");
     }
    if (vm.count("zeromq-server-id"))
    {
        zeromq_server_id = vm.str("zeromq-server-id");
    }
    if (vm.count("zeromq-client-id"))
    {
        zeromq_client_id = vm.str("zeromq-client-id");
    }
     if (vm.count("use-zeromq"))
     {
         _use_zeroMQ = vm.boolean("use-zeromq");
     }
     fs::path libraries_path = fs::path( runtime_lib_path) ;
     fs::path modelica_path = fs::path( modelica_lib_path) ;

     libraries_path.make_preferred();
     modelica_path.make_preferred();

     SimSettings settings = {solver, linSolver, nonLinSolver, starttime, stoptime, stepsize, 1e-24, 0.01, tolerance, resultsfilename, timeOut, outputPointType, logSettings, nlsContinueOnError, solverThreads, outputFormat, emitResults,omsu_name, omsu_path, init_file_path, inputPath, outputPath,_use_zeroMQ ,port_pub ,port_sub,zeromq_job_id,zeromq_server_id,zeromq_client_id };

     _library_path = libraries_path.string();
     _modelicasystem_path = modelica_path.string();

     return settings;

}

vector<const char *> OMCFactory::handleArgumentsToReplace(int argc, const char* argv[], map<string, string>& opts)
{
    vector<const char *> optv;
    optv.push_back(strdup(argv[0]));
    for (int i = 1; i < argc; i++)
    {
        string arg = argv[i];

        int sep = arg.find("=");
        string key = arg;
        string value = "";
        if (sep > 0)
        {
            key = arg.substr(0, sep);
            value = arg.substr(sep + 1);
        }

        map<string, string>::iterator oldValue = opts.find(key);

        map<string, string>::iterator iter = _argumentsToReplace.find(key);
        if (iter != _argumentsToReplace.end())
        {
            //if(opts.find(iter->second) != opts.end()) //if the new key is already part of the argument list, prevent double insertion
            //  continue;

            if (oldValue != opts.end())
            {
                opts.insert(pair<string, string>(iter->second, oldValue->second));
                opts.erase(arg);
            }
            key = iter->second;


            optv.push_back(strdup(key.c_str()));
            if(sep > 0)
                optv.push_back(strdup(value.c_str()));
        }
        else
        {
          if(sep > 0)
              arg = key + "=" + value;
          else
              arg = key;
          optv.push_back(strdup(arg.c_str()));
        }

    }

    return optv;
}

vector<const char *> OMCFactory::handleComplexCRuntimeArguments(int argc, const char* argv[], map<string, string>& opts)
{
    map<string, string>::const_iterator oit;
    vector<const char *> optv;

    optv.push_back(strdup(argv[0]));
    _overrideOMEdit = "-override="; // unrecognized OMEdit overrides
    for (int i = 1; i < argc; i++)
    {
        string arg = argv[i];
        int j;
        if (arg[0] == '-' && arg[1] != '-' && (j = arg.find('=')) > 0
            && (oit = opts.find(arg.substr(0, j))) != opts.end())
            opts[oit->first] = arg.substr(j + 1); // split at = and override
        else if ((oit = opts.find(arg)) != opts.end() && i < argc - 1)
            opts[oit->first] = argv[++i]; // regular override
        else if (strncmp(argv[i], "-override=", 10) == 0)
        {
            map<string, string> supported = MAP_LIST_OF
            "startTime", "-S"
            MAP_LIST_SEP
            "stopTime", "-E"
            MAP_LIST_SEP
            "stepSize", "-H"
            MAP_LIST_SEP
            "numberOfIntervals", "-G"
            MAP_LIST_SEP
            "solver", "-I"
            MAP_LIST_SEP
            "tolerance", "-T"
            MAP_LIST_SEP
            "outputFormat", "-P"
            MAP_LIST_END;
            vector<string> strs = split(argv[i], ",=");
            for (int j = 1; j < strs.size(); j++)
            {
                if ((oit = supported.find(strs[j])) != supported.end()
                    && j < strs.size() - 1)
                {
                    opts[oit->second] = strs[++j];
                }
                else
                {
                    // ignore filter for all variables
                    if (strs[j] == "variableFilter"
                        && j < strs.size() - 1 && strs[j + 1] == ".*")
                    {
                        ++j;
                        continue;
                    }
                    // leave unrecognized overrides
                    if (_overrideOMEdit.size() > 10)
                        _overrideOMEdit += ",";
                    _overrideOMEdit += strs[j];
                    if (j < strs.size() - 1)
                        _overrideOMEdit += "=" + strs[++j];
                }
            }
            if (_overrideOMEdit.size() > 10)
                optv.push_back(strdup(_overrideOMEdit.c_str()));
        }
        else
            optv.push_back(strdup(argv[i])); // pass through
    }
    for (oit = opts.begin(); oit != opts.end(); oit++)
    {
        optv.push_back(strdup(oit->first.c_str()));
        optv.push_back(strdup(oit->second.c_str()));
    }

    return optv;
}

void OMCFactory::fillArgumentsToIgnore()
{
    _argumentsToIgnore = unordered_set<string>();
    _argumentsToIgnore.insert("-abortSlowSimulation"); // used by nightly tests
}

void OMCFactory::fillArgumentsToReplace()
{
    _argumentsToReplace = map<string, string>();
    _argumentsToReplace.insert(pair<string, string>("-r", "-F"));
    _argumentsToReplace.insert(pair<string, string>("-ls", "-L"));
    _argumentsToReplace.insert(pair<string, string>("-nls", "-N"));
    _argumentsToReplace.insert(pair<string, string>("-lv", "--log-settings"));
    _argumentsToReplace.insert(pair<string, string>("-w", "--warn-all"));
    _argumentsToReplace.insert(pair<string, string>("-logFormat", "--log-format"));
    _argumentsToReplace.insert(pair<string, string>("-port", "--log-port"));
    _argumentsToReplace.insert(pair<string, string>("-alarm", "--alarm"));
    _argumentsToReplace.insert(pair<string, string>("-emit_protected", "--emit-results all"));
    _argumentsToReplace.insert(pair<string, string>("-inputPath", "--input-path"));
    _argumentsToReplace.insert(pair<string, string>("-outputPath", "--output-path"));
}

pair<shared_ptr<ISimController>, SimSettings>
OMCFactory::createSimulation(int argc, const char* argv[],
                             map<string, string>& opts)
{
    vector<const char *> optv = handleComplexCRuntimeArguments(argc, argv, opts);
    vector<const char *> optv2 = handleArgumentsToReplace(optv.size(), &optv[0], opts);

    SimSettings settings = readSimulationParameter(optv2.size(), &optv2[0]);

    shared_ptr<ISimController> simcontroller = createSimController();

    for (int i = 0; i < optv.size(); i++)
        free((char*)optv[i]);

    optv.clear();

    for (int i = 0; i < optv2.size(); i++)
        free((char*)optv2[i]);

    optv2.clear();

    return make_pair(simcontroller, settings);
}

shared_ptr<ISimController> OMCFactory::createSimController()
{
    type_map simcontroller_type_map;
    fs::path simcontroller_path = _library_path;
    fs::path simcontroller_name(SIMCONTROLLER_LIB);
    simcontroller_path /= simcontroller_name;

    shared_ptr<ISimController> simcontroller =
        loadSimControllerLib(simcontroller_path.string(), simcontroller_type_map);
    return simcontroller;
}

LOADERRESULT OMCFactory::LoadLibrary(string libName, type_map& current_map)
{
    shared_library lib;
    if (!load_single_library(current_map, libName, lib))
        return LOADER_ERROR;
    _modules.insert(make_pair(libName, lib));
    return LOADER_SUCCESS;
}

LOADERRESULT OMCFactory::UnloadLibrary(shared_library lib)
{
    if (lib.is_open())
    {
        if (!lib.close())
            return LOADER_ERROR;
        else
            return LOADER_SUCCESS;
    }
    return LOADER_SUCCESS;
}

shared_ptr<ISimController> OMCFactory::loadSimControllerLib(PATH simcontroller_path, type_map simcontroller_type_map)
{
    LOADERRESULT result = LoadLibrary(simcontroller_path, simcontroller_type_map);


  if (result != LOADER_SUCCESS)
    throw ModelicaSimulationError(MODEL_FACTORY,string("Failed loading SimController library from path ") + simcontroller_path);

  map<string, factory<ISimController,PATH,PATH,bool> >::iterator iter;
  map<string, factory<ISimController,PATH,PATH,bool> >& factories(simcontroller_type_map.get());
  iter = factories.find("SimController");


  if (iter == factories.end())
      throw ModelicaSimulationError(MODEL_FACTORY, "No such SimController library");


  return shared_ptr<ISimController>(iter->second.create(_library_path, _modelicasystem_path, _use_zeroMQ));

}

/** @} */ // end of simcorefactoryOMCFactory
