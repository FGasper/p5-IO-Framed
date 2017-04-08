#include <sys/ioctl.h>
#include <stdio.h>

int main() {
    fprintf( stdout, "FIONREAD: %d\n", (int)FIONREAD);

    return 0;
}
