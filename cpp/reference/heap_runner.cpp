#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include "heap.cpp"

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "usage: " << argv[0] << " <workload>\n";
        return 1;
    }

    std::ifstream file(argv[1]);

    if (!file) {
        std::cerr << "error: cannot open workload: "
                  << argv[1] << '\n';
        return 1;
    }

    MinHeap heap;

    std::string line;

    while (std::getline(file, line)) {
        if (line.empty() || line[0] == '#')
            continue;

        std::istringstream iss(line);

        std::string operation;
        iss >> operation;

        if (operation == "PUSH") {
            int priority;
            int value;

            if (!(iss >> priority >> value)) {
                std::cerr << "error: malformed PUSH\n";
                return 1;
            }

            heap.push(priority, value);
        }
        else if (operation == "POP") {
            if (heap.empty()) {
                std::cerr << "error: POP on empty heap\n";
                return 1;
            }

            const Entry entry = heap.top();
            heap.pop();

            std::cout << "POP_RESULT "
                      << entry.priority << ' '
                      << entry.value << '\n';
        }
        else {
            std::cerr << "error: unknown operation: "
                      << operation << '\n';
            return 1;
        }
    }

    return 0;
}
