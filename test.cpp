#include <iostream>
#include <unistd.h>

int main(void)
{
    std::cout << "Hello world!\n";
    std::cerr << "Hello error stream!\n";
    std::cout << "My pid is: " << getpid() << '\n';
    return 0;
}
