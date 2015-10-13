"""
Synopsis:
    This script classifies the simulation results according to their status (see Groups) and updates
    the statistics file, which holds the latest status and the change date (of the status) for all simulations in the set.

Assumptions:
    1) This script will be executed in the folder containing the simulations:
        - Search for result files (MODEL.omc.txt) will be performed in the working directory.
        - Statistics file will be created and updated in the working directory.


Authors: martin.flehmig@tu-dresden.de, Christian Schubert
"""

import logging
import sys
import os.path
import datetime
import json

NOGROUP = '_NoGroup'

# GroupName, Words that must occur, Words that must not occur
Groups = [('_Translation', 'g++', None), \
          ('_Translation', 'Error building simulator', None), \
          ('_Update', 'Please update the test', None), \
          ('_Failed', 'failed', None), \
          ('_NotEqual', 'Files not Equal!', None), \
          ('_OK', 'Frontend succeeded', 'failed'), \
          ('_OK', 'Translation succeeded', 'failed'), \
          ('_OK', 'Compilation succeeded', 'failed'), \
          ('_OK', 'Files Equal!', 'failed'), \
          ('_OK', 'SimpleSimulation', ['failed', 'did not'])]


class SimulationStatistics(object):
    """
    Holds the information and statistics for a particular simulation model.
    """

    def __init__(self, name="", resfile="", status="", change_date=""):
        """
        :param name: Name of the simulation model.
        :param status: Status of the simulation.
        :param change_date: Date of status change.
        """
        self.sim_name = name
        self.resfile = resfile
        self.status = status
        self.change_date = change_date  # Last change of the simulation result.

    def set_status(self, status):
        """
        Set member 'status' of object.
        :param status: New status of the object.
        """
        self.status = status

    def set_date(self, date):
        """
        Set member 'date' of object.
        :param date: New date of the object.
        """
        self.change_date = date

    def get_status(self, groups):
        # Return immediately if resfile is not set.
        if self.resfile is None:
            return NOGROUP

        # Check File Size first (ignore > 128Kb)
        if os.path.getsize(self.resfile) > 128 * 1024:
            print "Skipping %s. Because file is too large!" % self.resfile
            return NOGROUP

        # Open, Read and Close file
        f = open(self.resfile, 'r')
        content = f.read()
        f.close()

        # run through all groups
        for g in groups:
            group_name = g[0]
            include = g[1]
            exclude = g[2]
            if include is None: include = list()
            if not isinstance(include, (list, tuple)): include = [include]
            if exclude is None: exclude = list()
            if not isinstance(exclude, (list, tuple)): exclude = [exclude]

            # test for include
            found = True
            for i in include:
                if content.find(i) < 0:
                    found = False
                    break
            if found is False:
                continue

            # test for exclude
            found = False
            for e in exclude:
                if content.find(e) >= 0:
                    found = True
                    break
            if found is True:
                continue

            # we found the group
            return group_name

        # we did not find a matching group
        return None

    def get_date(self):
        """
        :return  date2: Date and time of last modification of the result file.
        :rtype string
        """
        date1 = datetime.datetime.fromtimestamp(os.path.getmtime(self.resfile))
        date2 = date1.strftime("%d/%m/%Y (%H:%M)")  # 29 09 2015 (10:26)
        return date2


def obj_dict(obj):
    """
    Returns the object converted into a dictionary.
    This method is used for json.dump.
    :param obj:
    """
    return obj.__dict__


class HandleSimulationStatistics(object):
    """
    Class that holds statistics about simulations, e.g., MSL32_cpp.
    Name of simulations are read from current directory.
    """

    def __init__(self):
        """
        Initializes object of this class.
        :return: Nuescht.
        """
        # Working directory.
        self.wdir = os.getcwd()
        # Statistics file.
        self.stat_file = self.wdir + os.path.sep + "statistics.json"
        # Create list of simulation statistics objects.
        self.sim_stats = []

    def get_sims(self):
        """
        Reads names of simulation models from current directory.
        """
        for mosfile in os.listdir(self.wdir):
            if mosfile.endswith(".mos"):
                # Check, if there is a output/result file for this simulation (, i.e., if Model.mos.txt is present).
                # If so, create SimulationStatistics object. Else, skipp.
                resfile = mosfile + ".txt"
                if os.path.isfile(resfile):
                    self.sim_stats.append(SimulationStatistics(mosfile, resfile))
                else:
                    logging.info('No result file for model %s found.', mosfile)

                    # print "Number of simulations is ", len(self.sim_stats)
                    # print self.sim_stats

    def create_statistics(self):
        """
        Creates statistics for all models.
        """
        # Get simulations.
        self.get_sims()

        for sim in self.sim_stats:
            group = sim.get_status(Groups)
            sim.set_status(group)

            date = sim.get_date()
            sim.set_date(date)

    def create_statistics_file(self):
        """
        Creates statistics file and writes statistics. If a statistics file is already present, return without any changes.
        """
        if os.path.isfile(self.stat_file):
            logging.info('Statistics file %s exists already. Skip method create_statistics_file(self).', self.stat_file)
            return
        else:
            logging.info('No statistics file found. Statistics file %s is created.', self.stat_file)
            with open(self.stat_file, 'w') as file:
                json.dump(self.sim_stats, file, sort_keys=True, indent=4, ensure_ascii=False, default=obj_dict)

    def update_statistics_file(self):
        """
        Updates the statistics file.
        """
        # Loaded data are of type dict! I.e., stats_in_file is a list of dict.
        with open(self.stat_file, 'r') as file:
            stats_in_file = json.load(file)
        if not file.closed:
            logging.error('Statistics file could not be closed. Exit.')
            sys.exit(1)

        # print "Number of simulations in statistics file is ", len(stats_in_file['sim_name'])
        num_of_ups = 0
        # Iterate over all created statistics.
        for stat in self.sim_stats:
            # Find simulation in loaded data. If found, compare attributes and update statistics if possible.
            try:
                it = next(stat_f for stat_f in stats_in_file if stat_f['sim_name'] == stat.sim_name)

                # Compare old status with new status of a simulation.
                if it['status'] != unicode(stat.status):
                    num_of_ups += 1
                    logging.debug('Statistics for simulation %s needs to be updated', stat.sim_name)
                    logging.debug('Old: change date: %s \t status: %s', it['change_date'], it['status'])
                    logging.debug('New: change date: %s \t status: %s', stat.change_date, stat.status)

                    # Update status and change_date.
                    it['status'] = stat.status
                    it['change_date'] = stat.change_date
            except StopIteration:
                # Statistics for simulation 'stat' could not be found in statistics file. Maybe because this is a
                # new model or for some other reason. Therefore, statistics will be added to the statistics file.
                stats_in_file.append(stat)
                num_of_ups += 1
                logging.debug('New statistics for simulation %s added to statistics file.', stat.sim_name)

        # Write updated statistics to file (The file will be completely overridden. Can you manipulate json files
        # 'in place'?)
        print "  %d changes/updates were found." % num_of_ups
        if num_of_ups > 0:
            print "  Update statistics file..."
            with open(self.stat_file, 'w+') as file:
                json.dump(stats_in_file, file, sort_keys=True, indent=4, ensure_ascii=False, default=obj_dict)
            if not file.closed:
                logging.error('Statistics file could not be closed. Exit.')
                sys.exit(1)
            print "  Done."
        else:
            print "  No updates necessary."

    def run(self):
        """
        Run preprocessing.
        """
        # Create statistics from simulation results.
        self.create_statistics()

        # If statistics file does not exist, create and write it.
        if not os.path.isfile(self.stat_file):
            self.create_statistics_file()
        else:
            # Else, update statistics to file.
            self.update_statistics_file()


def main():
    # Logging level is set to error. Possible values are: debug, info, warning, error and critical.
    logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)

    # Parse command line arguments
    # parser = create_argument_parser()
    # args = parser.parse_args()  # will raise an error if the arguments are invalid and terminate the program immediately

    handle_sim_stats = HandleSimulationStatistics()
    handle_sim_stats.run()


if __name__ == '__main__':
    main()
