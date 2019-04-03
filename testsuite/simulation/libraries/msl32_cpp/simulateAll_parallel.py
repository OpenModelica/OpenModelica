"""
Synopsis:
    Executes Modelica simulations in parallel using the OpenModelica compiler.
    A statistics file is created or updated (if aready present) for all executed simulations. This statistics consists
    of the following information:
        - Model name.
        - Current status (see Groups).
        - Change date (i.e., date, when the status changed).
        - Name of the result file.
    Due to the use of python, it should be platform independent (i.e., runs on Linux, Windows and Mac).

Usage:
    python simulateAll_parallel.py --np 2

Command Line Parameters:
    Optional:
        --np N              Run N simulations in parallel [Default: 2].
        --omc PATH          Use /PATH/TO/omc [Default: Env. variable OPENMODELICAHOME].
        --tests PATH        Run simulations in /PATH/tests [Default: Current directory from that this script is executed].
        --omcflags " ARGS"  Run simulations using the omc flags specified via ARGS. IMPORTANT: Leading whitespace and quotes!


Authors:
    martin.flehmig@tu-dresden, marcus.walther@tu-dresden.de


Todo:
    1) More documentation.
    2) Features to implement:
      - Treat sub directory, i.e., recursively run simulations.
      - Error and exception handling.
      - More classification?
"""

import argparse
import os
import subprocess
import time
import logging
import sys

# Local Import
import postprocessing


class Settings(object):
    """
    Contains all settings, i.e., path variables, j, omc
    Members:
        omc_exe: /PATH/TO/omc
        omc_flags: Flags used for compilation with omc.
        omc_command: omc_exe + omc_flags
        np: Number of concurrently running simulations.
    """

    def __init__(self, parsed_args):
        """
        Initialize settings from commandline arguments.
        """
        if parsed_args.omc is not None:
            self.omc_exe = parsed_args.omc + " "  # Just the omc executable, i.e., /PATH/TO/omc
        else:
            self.omc_exe = os.environ.get('OPENMODELICAHOME', 'Not set.')
            # Todo: Not Set ==> Implement Error Handling!
            # Todo: Fuer windows muss es omc.exe sein!
            self.omc_exe += os.sep + 'bin' + os.sep + "omc "

        # Todo: Check if all path are absolute!
        # Making omc an absolute path.
        # self.omc_exe = os.path.abspath(self.omc_exe)

        self.omc_flags = "+locale=Cpp +running-testsuite=dummy.out "  # parsed_args.omc_flags
        self.omc_userdefined_flags = parsed_args.omcflags
        self.omc_command = self.omc_exe + self.omc_flags + self.omc_userdefined_flags
        self.np = parsed_args.np
        self.wdir = parsed_args.tests

        # Make workingdir an absolute path
        self.wdir = os.path.abspath(parsed_args.tests)
        if not os.path.exists(self.wdir):
            logging.error('TestsDirectory %s does not exists.', self.wdir)
            # Todo: Exit.


class Simulations(object):
    """
    This class represents all simulations within the working directory to execute. It also handles the subprocesses in
    which the simulations run.

    Members:
        - settings: Instance of class Settings which holds information like omc_command.
        - sims: List of strings which holds the simulation model names (e.g., Modelica.Mechanics.Rotational.Examples.SimpleGearShift.mos).
        - sub_processes: List of Popen objects containing the subprocesses (i.e., the simulations).
        - scrs: All simulations currently running in subprocesses (i.e., simulations in sub_processes).
        - num_sims: Number of simulations to execute in the working directory.
    """

    def __init__(self, args):
        """
        Constructor from arguments.
        :param args: Parsed arguments.
        """
        self.settings = Settings(args)
        self.sub_processes = []  # Todo: Can we declare subprocess.Popen objects there? Is it meaningful?
        self.sims = []
        self.scrs = []
        self.sims_num = 0

    def wait_for_all(self):
        """
        Wait to finish all subprocesses, i.e., all currently running simulations.
        """
        for i in range(len(self.sub_processes)):
            self.sub_processes[i].wait()
            print "%20s \t %s  " % ("Finished", self.sims[i])

    def get_simulations(self):
        """
        Fill simulations list with all *.mos files in the working directory.
        """
        for mosfile in os.listdir(self.settings.wdir):
            if mosfile.endswith(".mos"):
                self.sims.append(mosfile)

        self.sims_num = len(self.sims)
        print "Number of simulations in", self.settings.wdir, "is", self.sims_num, "."

    def run_simulation(self, i):
        """
        Start particular simulation in new subprocess.
        :param i: Index of the simulation that will be executed.
        :type i: Integer
        """
        print "[%3d/%3d] %7s \t %s  " % (i, self.sims_num, "Start", self.sims[i])
        sim = self.settings.omc_command + ' ' + self.sims[i]
        # args should be sequence of arguments (https://docs.python.org/2/library/subprocess.html#popen-constructor)
        args = sim.split(" ")  # shlex.split(sim)
        # Remove empty strings in args which will cause errors in subprocess handling.
        args = filter(lambda a: a != '', args)
        # print args

        # Open log and err file in working directory. Existing files with same names will be erased.
        log_file = open(self.settings.wdir + os.path.sep + self.sims[i] + ".txt", "w")
        # Call subprocess and append Popen object to list of objects
        self.sub_processes.append(
           subprocess.Popen(args, cwd=self.settings.wdir, stdout=log_file, stderr=subprocess.STDOUT))
        self.scrs.append(i)

    def execute_first_np_simulations(self):
        """
        The first np simulations will be started in order to fill the pipe.
        """
        for i in range(self.settings.np):
            self.run_simulation(i)

    def execute_remaining_simulations(self):
        """
        Executes all remaining simulations.
        """
        for i in range(self.settings.np, len(self.sims)):
            fi = self.wait_for_a_finished_simulation()
            logging.debug('Number of active subprocess is %d.', len(self.sub_processes))
            logging.debug('Sub process i=%d has finished.', fi)
            print "%20s \t %s  " % ("Finished", self.sims[self.scrs[fi]])
            self.sub_processes.pop(fi)
            self.scrs.pop(fi)
            self.run_simulation(i)
            self.scrs.append(i)

    def run(self):
        """
        Master method that executes the simulations.
        """
        # Check if list of simulations is not empty.
        if len(self.sims) == 0:
            logging.error('There are no simulations to run. Exit.')
            exit(2)

        # Execute first j simulations in parallel.
        self.execute_first_np_simulations()

        # Execute the remaining simulations.
        self.execute_remaining_simulations()

        # Wait to finish all simulations.
        self.wait_for_all()

    def wait_for_a_finished_simulation(self):
        """
        Will return if at least one subprocess (of the given subprocesses) has finished.
        :returns: Index of subprocess that has finished.
        :rtype: Integer
        """
        all_running = True
        while all_running:
            for i in range(len(self.sub_processes)):
                if self.sub_processes[i].poll() is not None:
                    all_running = False
                    return i
            time.sleep(2)


def create_argument_parser():
    """
    Optional arguments:
        -omc Path to omc executable
        -tests Path to the folder containing the simulations (mos files) to execute.
        -np Parallel degree, i.e., how many simulations should be executed simultaneously [Default np=2].
    :return: :class:`argparse:ArgumentParser` -- the created argument parser.
    """
    parser = argparse.ArgumentParser(prog='runOMtest', description='Run the OpenModelica tests XXX in parallel.')
    parser.add_argument('--omc', metavar='PATH', type=str, required=False,
                        help='Use this argument to specify a omc executable different from the one in OPENMODELICAHOME.')
    parser.add_argument('--tests', metavar='PATH', type=str, required=False, default="./",
                        help='The absolute path to the folder containing the tests [default: ./].')
    parser.add_argument('--np', metavar='N', type=int, default=2,
                        help='Number of parallel executed tests [default: 2].')
    # parser.add_argument('-omcflags', metavar='df', type=str, required=False, default="",
    #                     help='Additional debug flags for simulation (e.g., --debug=hpcom,graphml')
    parser.add_argument('--omcflags', type=str, default="",
                        help='Additional omc flags for simulation (e.g., " --debug=hpcom,graphml +n=2"). IMPORTANT: Leadig whitespace and quotes')
    return parser


def main():
    # Logging level is set to error. Possible values are: debug, info, warning, error and critical.
    logging.basicConfig(stream=sys.stderr, level=logging.INFO)

    start_time = time.time()

    # Parse command line arguments
    parser = create_argument_parser()
    args = parser.parse_args()  # will raise an error if the arguments are invalid and terminate the program immediately

    sims = Simulations(args)
    sims.get_simulations()
    logging.info('           OMC: %s', sims.settings.omc_exe)
    logging.info('   OMC command: %s', sims.settings.omc_command)
    logging.info('Test directory: %s', sims.settings.wdir)
    logging.info('           np : %d', sims.settings.np)
    sims.run()

    print "\n\nFinished all simulations in %s seconds." % (time.time() - start_time)

    # Call postprocessing.py
    print "\nStart postprocessing..."
    postprocessing.main()
    print "Finished postprocessing."


if __name__ == '__main__':
    main()
