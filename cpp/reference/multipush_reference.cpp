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

/*
 * Algorithmic reference model for the Multi-Push optimization
 * described in:
 *
 * "A Fast Scalable Hardware Priority Queue and Optimizations
 *  for Multi-Pushes"
 *
 * This is NOT an RTL implementation.
 *
 * The model explicitly separates:
 *
 *   push_location:
 *       First free tail position where an incoming PUSH is stored.
 *
 *   heap_size:
 *       Number of entries that have already been incorporated into
 *       the heap ordering.
 *
 * Therefore:
 *
 *   push_location > heap_size
 *
 * means that there are pending PUSH entries that have been accepted
 * but have not yet gone through HeapifyUp.
 *
 * PUSH:
 *     write at push_location
 *     increment push_location
 *
 * Heap maintenance:
 *     while push_location > heap_size:
 *         HeapifyUp(heap_size)
 *         heap_size++
 *
 * POP:
 *     wait for all pending PUSH maintenance to complete
 *     remove root
 *     HeapifyDown
 *
 * The implementation is intentionally sequential. The purpose is
 * functional equivalence and algorithm characterization before RTL.
 */

class MultiPushReference {
public:
    void push(int priority, int value) {
        /*
         * Multi-Push acceptance path.
         *
         * The incoming element is accepted unconditionally at the
         * current tail location. No HeapifyUp is performed here.
         */
        if (push_location_ == data_.size()) {
            data_.push_back({priority, value});
        } else {
            data_[push_location_] = {priority, value};
        }

        ++push_location_;
    }

    bool empty() const {
        return heap_size_ == 0 && push_location_ == 0;
    }

    std::size_t size() const {
        return push_location_;
    }

    std::size_t heap_size() const {
        return heap_size_;
    }

    std::size_t push_location() const {
        return push_location_;
    }

    bool busy() const {
        return push_location_ > heap_size_;
    }

    /*
     * Execute the pending heap maintenance.
     *
     * This models the IDLE-state behavior:
     *
     *     if push_location > heap_size:
     *         HeapifyUp(heap_size)
     *         heap_size++
     *
     * The loop is used here because a software reference model
     * can complete all pending maintenance before returning.
     */
    void finish_pending_pushes() {
        while (push_location_ > heap_size_) {
            const std::size_t index = heap_size_;

            heap_size_++;

            heapify_up(index);
        }
    }

    Entry top() {
        /*
         * A POP must wait until all accepted PUSH operations have
         * been incorporated into the heap.
         */
        finish_pending_pushes();

        if (heap_size_ == 0)
            throw std::runtime_error("queue is empty");

        return data_[0];
    }

    void pop() {
        /*
         * Synchronization point:
         *
         * POP cannot proceed while there are pending PUSH entries.
         */
        finish_pending_pushes();

        if (heap_size_ == 0)
            throw std::runtime_error("queue is empty");

        data_[0] = data_[heap_size_ - 1];

        --heap_size_;

        if (heap_size_ != 0)
            heapify_down(0);

        /*
         * There are no pending PUSH entries here because the
         * synchronization step above completed all of them.
         *
         * After removing the root, the active heap occupies
         * [0, heap_size_).
         *
         * The next PUSH therefore writes at the first free tail
         * position.
         */
        push_location_ = heap_size_;
    }

    std::size_t push_count() const {
        return push_count_;
    }

    std::size_t pop_count() const {
        return pop_count_;
    }

    std::size_t comparisons() const {
        return comparisons_;
    }

    std::size_t swaps() const {
        return swaps_;
    }

    std::size_t push_comparisons() const {
        return push_comparisons_;
    }

    std::size_t push_swaps() const {
        return push_swaps_;
    }

    std::size_t pop_comparisons() const {
        return pop_comparisons_;
    }

    std::size_t pop_swaps() const {
        return pop_swaps_;
    }

    std::size_t heapify_up_count() const {
        return heapify_up_count_;
    }

private:
    std::vector<Entry> data_;

    /*
     * Number of entries currently incorporated into the heap.
     */
    std::size_t heap_size_ = 0;

    /*
     * Tail position for unconditional PUSH acceptance.
     */
    std::size_t push_location_ = 0;

    std::size_t push_count_ = 0;
    std::size_t pop_count_ = 0;

    std::size_t comparisons_ = 0;
    std::size_t swaps_ = 0;

    std::size_t push_comparisons_ = 0;
    std::size_t push_swaps_ = 0;

    std::size_t pop_comparisons_ = 0;
    std::size_t pop_swaps_ = 0;

    std::size_t heapify_up_count_ = 0;

    static bool less(const Entry& a, const Entry& b) {
        if (a.priority != b.priority)
            return a.priority < b.priority;

        return a.value < b.value;
    }

    bool compare_push(const Entry& a, const Entry& b) {
        ++comparisons_;
        ++push_comparisons_;

        return less(a, b);
    }

    bool compare_pop(const Entry& a, const Entry& b) {
        ++comparisons_;
        ++pop_comparisons_;

        return less(a, b);
    }

    void swap_push(std::size_t a, std::size_t b) {
        std::swap(data_[a], data_[b]);

        ++swaps_;
        ++push_swaps_;
    }

    void swap_pop(std::size_t a, std::size_t b) {
        std::swap(data_[a], data_[b]);

        ++swaps_;
        ++pop_swaps_;
    }

    /*
     * HeapifyUp for the newly incorporated element.
     *
     * The caller guarantees that index == previous heap_size.
     */
    void heapify_up(std::size_t index) {
        ++heapify_up_count_;

        std::size_t i = index;

        while (i > 0) {
            const std::size_t parent = (i - 1) / 2;

            if (!compare_push(data_[i], data_[parent]))
                break;

            swap_push(i, parent);

            i = parent;
        }
    }

    /*
     * Standard HeapifyDown after removing the root.
     */
    void heapify_down(std::size_t index) {
        std::size_t i = index;

        while (true) {
            const std::size_t left = 2 * i + 1;
            const std::size_t right = 2 * i + 2;

            std::size_t smallest = i;

            if (left < heap_size_ &&
                compare_pop(data_[left], data_[smallest])) {
                smallest = left;
            }

            if (right < heap_size_ &&
                compare_pop(data_[right], data_[smallest])) {
                smallest = right;
            }

            if (smallest == i)
                break;

            swap_pop(i, smallest);

            i = smallest;
        }
    }

public:
    /*
     * Counters are incremented by the public operations here rather
     * than inside the parser so the class can also be reused by
     * future directed tests.
     */
    void record_push() {
        ++push_count_;
    }

    void record_pop() {
        ++pop_count_;
    }
};


int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "usage: " << argv[0]
                  << " <workload>\n";
        return 1;
    }

    std::ifstream file(argv[1]);

    if (!file) {
        std::cerr << "error: cannot open workload: "
                  << argv[1] << '\n';
        return 1;
    }

    MultiPushReference queue;

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

            queue.push(priority, value);
            queue.record_push();
        }
        else if (operation == "POP") {
            /*
             * top() performs the required synchronization before
             * returning the root.
             */
            if (queue.empty() && queue.push_location() == 0) {
                std::cerr << "error: POP on empty queue\n";
                return 1;
            }

            const Entry entry = queue.top();

            queue.pop();
            queue.record_pop();

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

    /*
     * Drain remaining entries.
     *
     * This is required for PUSH-only generated workloads.
     */
    while (queue.push_location() != 0) {
        const Entry entry = queue.top();

        queue.pop();
        queue.record_pop();

        std::cout << "POP_RESULT "
                  << entry.priority << ' '
                  << entry.value << '\n';
    }

    /*
     * Statistics are sent to stderr so stdout remains directly
     * comparable with heap_drain output.
     */
    std::cerr << "pushes="
              << queue.push_count()
              << '\n';

    std::cerr << "pops="
              << queue.pop_count()
              << '\n';

    std::cerr << "push_comparisons="
              << queue.push_comparisons()
              << '\n';

    std::cerr << "push_swaps="
              << queue.push_swaps()
              << '\n';

    std::cerr << "pop_comparisons="
              << queue.pop_comparisons()
              << '\n';

    std::cerr << "pop_swaps="
              << queue.pop_swaps()
              << '\n';

    std::cerr << "total_comparisons="
              << queue.comparisons()
              << '\n';

    std::cerr << "total_swaps="
              << queue.swaps()
              << '\n';

    std::cerr << "heapify_up_count="
              << queue.heapify_up_count()
              << '\n';

    return 0;
}
