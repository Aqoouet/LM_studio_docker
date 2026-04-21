#include <sys/mman.h>
#include <stdio.h>

__attribute__((constructor))
static void preload_mlockall(void) {
    if (mlockall(MCL_CURRENT | MCL_FUTURE) != 0) {
        perror("[mlockall_preload] WARNING: mlockall failed");
    }
}
