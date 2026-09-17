#include <iostream>
#include <vector>
#include "heap.cpp"

int main() {
    MinHeap heap;

    const std::vector<int> input = {
        7, 3, 9, 1, 5, 2, 8, 4, 6
    };

    for (int value : input) {
        heap.push(value);
    }

    std::cout << "size=" << heap.size() << '\n';

    std::cout << "pop_sequence=";

    while (!heap.empty()) {
        std::cout << heap.top();

        heap.pop();

        if (!heap.empty())
            std::cout << ' ';
    }

    std::cout << '\n';

    return 0;
}
