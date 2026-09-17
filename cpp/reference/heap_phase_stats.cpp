#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

struct Entry {
    int priority;
    int value;
};

struct Stats {
    std::size_t comparisons = 0;
    std::size_t swaps = 0;
};

class MinHeap {
public:
    void push(int priority, int value, Stats& stats) {
        data_.push_back({priority, value});
        sift_up(data_.size() - 1, stats);
    }

    Entry top() const {
        return data_.front();
    }

    void pop(Stats& stats) {
        data_.front() = data_.back();
        data_.pop_back();

        if (!data_.empty())
            sift_down(0, stats);
    }

    bool empty() const {
        return data_.empty();
    }

private:
    std::vector<Entry> data_;

    static bool less(const Entry& a,
                     const Entry& b,
                     Stats& stats) {
        stats.comparisons++;

        if (a.priority != b.priority)
            return a.priority < b.priority;

        return a.value < b.value;
    }

    static void swap_entries(Entry& a,
                             Entry& b,
                             Stats& stats) {
        std::swap(a, b);
        stats.swaps++;
    }

    void sift_up(std::size_t i, Stats& stats) {
        while (i > 0) {
            const std::size_t parent = (i - 1) / 2;

            if (!less(data_[i], data_[parent], stats))
                break;

            swap_entries(data_[parent], data_[i], stats);
            i = parent;
        }
    }

    void sift_down(std::size_t i, Stats& stats) {
        while (true) {
            const std::size_t left = 2 * i + 1;
            const std::size_t right = 2 * i + 2;

            std::size_t smallest = i;

            if (left < data_.size() &&
                less(data_[left], data_[smallest], stats)) {
                smallest = left;
            }

            if (right < data_.size() &&
                less(data_[right], data_[smallest], stats)) {
                smallest = right;
            }

            if (smallest == i)
                break;

            swap_entries(data_[i], data_[smallest], stats);
            i = smallest;
        }
    }
};

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "usage: "
                  << argv[0]
                  << " <workload>\n";
        return 1;
    }

    std::ifstream file(argv[1]);

    if (!file) {
        std::cerr << "error: cannot open workload: "
                  << argv[1] << '\n';
        return 1;
    }

    MinHeap heap;

    Stats push_stats;
    Stats pop_stats;

    std::size_t pushes = 0;
    std::size_t pops = 0;

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

            heap.push(priority, value, push_stats);
            pushes++;
        }
        else if (operation == "POP") {
            if (heap.empty()) {
                std::cerr << "error: POP on empty heap\n";
                return 1;
            }

            heap.pop(pop_stats);
            pops++;
        }
        else {
            std::cerr << "error: unknown operation: "
                      << operation << '\n';
            return 1;
        }
    }

    /*
     * Drain the remaining entries.
     *
     * These POP operations are included in pop_stats because they
     * represent the complete cost of obtaining the sorted sequence.
     */
    while (!heap.empty()) {
        heap.pop(pop_stats);
        pops++;
    }

    std::cout << "pushes=" << pushes << '\n';
    std::cout << "pops=" << pops << '\n';

    std::cout << "push_comparisons="
              << push_stats.comparisons << '\n';

    std::cout << "push_swaps="
              << push_stats.swaps << '\n';

    std::cout << "pop_comparisons="
              << pop_stats.comparisons << '\n';

    std::cout << "pop_swaps="
              << pop_stats.swaps << '\n';

    std::cout << "total_comparisons="
              << push_stats.comparisons
                 + pop_stats.comparisons << '\n';

    std::cout << "total_swaps="
              << push_stats.swaps
                 + pop_stats.swaps << '\n';

    return 0;
}
