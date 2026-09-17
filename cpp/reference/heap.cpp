#include <cstddef>
#include <stdexcept>
#include <utility>
#include <vector>

struct Entry {
    int priority;
    int value;
};

class MinHeap {
public:
    void push(int priority, int value) {
        data_.push_back({priority, value});
        sift_up(data_.size() - 1);
    }

    Entry top() const {
        if (data_.empty())
            throw std::runtime_error("heap is empty");

        return data_.front();
    }

    void pop() {
        if (data_.empty())
            throw std::runtime_error("heap is empty");

        data_.front() = data_.back();
        data_.pop_back();

        if (!data_.empty())
            sift_down(0);
    }

    bool empty() const {
        return data_.empty();
    }

    std::size_t size() const {
        return data_.size();
    }

private:
    std::vector<Entry> data_;

    static bool less(const Entry& a, const Entry& b) {
        if (a.priority != b.priority)
            return a.priority < b.priority;

        return a.value < b.value;
    }

    void sift_up(std::size_t i) {
        while (i > 0) {
            const std::size_t parent = (i - 1) / 2;

            if (!less(data_[i], data_[parent]))
                break;

            std::swap(data_[parent], data_[i]);
            i = parent;
        }
    }

    void sift_down(std::size_t i) {
        while (true) {
            const std::size_t left = 2 * i + 1;
            const std::size_t right = 2 * i + 2;

            std::size_t smallest = i;

            if (left < data_.size() &&
                less(data_[left], data_[smallest])) {
                smallest = left;
            }

            if (right < data_.size() &&
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
