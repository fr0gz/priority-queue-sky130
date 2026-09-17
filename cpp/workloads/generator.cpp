#include <iostream>
#include <random>
#include <string>

int main(int argc, char* argv[]) {
    const int count = (argc > 1) ? std::stoi(argv[1]) : 16;
    const unsigned seed = (argc > 2) ? std::stoul(argv[2]) : 12345;

    std::mt19937 rng(seed);
    std::uniform_int_distribution<int> priority_dist(0, 255);

    std::cout << "# seed " << seed << '\n';
    std::cout << "# operations " << count << '\n';

    for (int i = 0; i < count; ++i) {
        const int priority = priority_dist(rng);

        std::cout << "PUSH "
                  << priority << ' '
                  << i << '\n';
    }

    return 0;
}
