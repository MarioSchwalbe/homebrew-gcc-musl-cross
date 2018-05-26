#include <unistd.h>
#include <stdio.h>

int main(void)
{
    puts("Hello world!");
    printf("My pid is: %u\n", getpid());
    return 0;
}
