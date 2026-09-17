#include <cstddef>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

struct Entry {
    int priority;
    int value;
};

class MultiPushCharacterize {
public:
    void push(int priority, int value) {
        /*
         * Accept the PUSH at the current tail position.
         *
         * No HeapifyUp is performed here. The element becomes
         * pending until heap maintenance is executed.
         */
        if (push_location_ == data_.size()) {
            data_.push_back({priority, value});
        } else {
            data_[push_location_] = {priority, value};
        }

        ++push_location_;
    }

    void finish_pending_pushes() {
        /*
         * Model the deferred HeapifyUp mechanism.
         *
         * Every pending element is incorporated into the heap
         * one at a time until:
         *
         *     heap_size == push_location
         */
        while (push_location_ > heap_size_) {
            const std::size_t index = heap_size_;

            ++heap_size_;

            heapify_up(index);
        }
    }

    Entry top() {
        finish_pending_pushes();

        if (heap_size_ == 0)
            throw std::runtime_error("queue is empty");

        return data_[0];
    }

    void pop() {
        /*
         * POP is a synchronization point.
         *
         * All accepted PUSH operations must be incorporated
         * before the root can be removed.
         */
        finish_pending_pushes();

        if (heap_size_ == 0)
            throw std::runtime_error("queue is empty");

        data_[0] = data_[heap_size_ - 1];

        --heap_size_;

        if (heap_size_ != 0)
            heapify_down(0);

        /*
         * The active heap occupies [0, heap_size_).
         * The next PUSH is therefore accepted at heap_size_.
         */
        push_location_ = heap_size_;
    }

    std::size_t push_location() const {
        return push_location_;
    }

    std::size_t heap_size() const {
        return heap_size_;
    }

    std::size_t pending() const {
        return push_location_ - heap_size_;
    }

private:
    std::vector<Entry> data_;

    std::size_t heap_size_ = 0;
    std::size_t push_location_ = 0;

    static bool less(const Entry& a, const Entry& b) {
        if (a.priority != b.priority)
            return a.priority < b.priority;

        return a.value < b.value;
    }

    void heapify_up(std::size_t index) {
        std::size_t i = index;

        while (i > 0) {
            const std::size_t parent = (i - 1) / 2;

            if (!less(data_[i], data_[parent]))
                break;

            std::swap(data_[i], data_[parent]);
            i = parent;
        }
    }

    void heapify_down(std::size_t index) {
        std::size_t i = index;

        while (true) {
            const std::size_t left = 2 * i + 1;
            const std::size_t right = 2 * i + 2;

            std::size_t smallest = i;

            if (left < heap_size_ &&
                less(data_[left], data_[smallest])) {
                smallest = left;
            }

            if (right < heap_size_ &&
                less(data_[right], data_[smallest])) {
                smallest = right;
            }

            if (smallest == i)
                break;

            std::swap(data_[i], data_[smallest]);
            i = smallest;
        }
    }
};

static void print_state(
    std::size_t step,
    const std::string& operation,
    const MultiPushCharacterize& queue)
{
    std::cout
        << step << ' '
        << operation << ' '
        << queue.push_location() << ' '
        << queue.heap_size() << ' '
        << queue.pending()
        << '\n';
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr
            << "usage: " << argv[0]
            << " <workload>\n";
        return 1;
    }

    std::ifstream file(argv[1]);

    if (!file) {
        std::cerr
            << "error: cannot open workload: "
            << argv[1] << '\n';
        return 1;
    }

    MultiPushCharacterize queue;

    std::cout
        << "cycle operation push_location heap_size pending\n";

    std::size_t cycle = 0;

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
                std::cerr
                    << "error: malformed PUSH\n";
                return 1;
            }

            /*
             * PUSH acceptance.
             *
             * This is the important observation point:
             * the entry is accepted immediately and pending
             * work increases.
             */
            queue.push(priority, value);

            print_state(cycle, "PUSH", queue);
            ++cycle;
        }
        else if (operation == "POP") {
            /*
             * Record the state before synchronization.
             */
            std::cout
                << cycle << ' '
                << "POP_WAIT "
                << queue.push_location() << ' '
                << queue.heap_size() << ' '
                << queue.pending()
                << '\n';

            ++cycle;

            /*
             * POP waits for all pending PUSH maintenance.
             */
            queue.top();

            /*
             * State after pending PUSHes have been incorporated.
             */
            std::cout
                << cycle << ' '
                << "POP_READY "
                << queue.push_location() << ' '
                << queue.heap_size() << ' '
                << queue.pending()
                << '\n';

            ++cycle;

            queue.pop();

            /*
             * State after HeapifyDown and root removal.
             */
            print_state(cycle, "POP_DONE", queue);
            ++cycle;
        }
        else {
            std::cerr
                << "error: unknown operation: "
                << operation << '\n';
            return 1;
        }
    }

    return 0;
}
