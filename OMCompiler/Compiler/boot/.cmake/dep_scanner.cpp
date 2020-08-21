#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <set>
#include <unordered_map>


typedef std::unordered_map<std::string, std::set<std::string>> DependsMap;

void scan_mm_file(const std::string& mm_file, const std::string& deps_dir, DependsMap& dep_map) {

    std::string file_path = deps_dir + "/" + mm_file + ".depends";

    std::ifstream ifs(file_path);
    if (!ifs.is_open()) {
        std::cout <<" Failed to open file :" << file_path << std::endl;
        exit(1);
    }

    std::string line;
    std::getline(ifs, line);

    std::string depends;
    std::stringstream linestream(line);

    while(linestream >> depends) {
        dep_map[depends].insert(mm_file);
    }

}


int main(int argc, char** argv) {
    if (argc < 3) {
        std::cout << "Usage: ./mm_dep_scanner <file_list_file> <depends_files_dir>" << std::endl;
        exit(1);
    }

    const std::string file_list_file = argv[1];
    std::cout << "Reading MM source files list from " << file_list_file << std::endl;

    const std::string depends_files_dir = argv[2];
    std::cout << "Reading depends files from " << depends_files_dir << std::endl;

    std::ifstream pac_list_s(file_list_file);
    if (!pac_list_s.is_open()) {
        std::cout <<" Failed to open " << depends_files_dir << std::endl;
        return 1;
    }

    std::string mm_file;
    std::vector<std::string> mm_files_list;
    DependsMap dep_map;
    while(std::getline(pac_list_s, mm_file)) {
        mm_files_list.push_back(mm_file);
        scan_mm_file(mm_file, depends_files_dir, dep_map);
    }

    for(const auto& file : mm_files_list) {
        auto search = dep_map.find(file);
        if (search == dep_map.end()) {
            std::cout << "Source file " << file << " is not used by any package." << std::endl;
            dep_map[file].insert("");
        }
    }



    for(auto& pac : dep_map) {
        std::string file_path = depends_files_dir + "/" + pac.first + ".rev_depends";
        std::ofstream rev_dep_file(file_path);
        if (!rev_dep_file.is_open()) {
            std::cout <<" Failed to write " << file_path << std::endl;
            return 1;
        }

        rev_dep_file << pac.first << ": ";
        for (const auto& depee : pac.second) {
            rev_dep_file << depee << " ";
        }
        rev_dep_file << std::endl;

        // if(pac.second.size() > largest) {
        //     largest = pac.second.size();
        //     largest_file = pac.first;
        //     std::cout << largest_file << " " << largest << std::endl;
        // }
    }

    // std::cout << largest_file << " " << largest << std::endl;
    // return 0;
}