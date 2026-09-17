#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include "heap_instrumented.cpp"

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

    HeapStats stats;
    InstrumentedMinHeap heap(stats);

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

            heap.pop();
        }
        else {
            std::cerr << "error: unknown operation: "
                      << operation << '\n';
            return 1;
        }
    }

    while (!heap.empty())
        heap.pop();

    std::cout << "pushes=" << stats.pushes << '\n';
    std::cout << "pops=" << stats.pops << '\n';
    std::cout << "comparisons=" << stats.comparisons << '\n';
    std::cout << "swaps=" << stats.swaps << '\n';

    return 0;
}
