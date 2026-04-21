#include <sys/mman.h>
#include <stdio.h>

#ifndef MCL_ONFAULT
#define MCL_ONFAULT 4
#endif

__attribute__((constructor))
static void preload_mlockall(void) {
    if (mlockall(MCL_CURRENT | MCL_FUTURE | MCL_ONFAULT) != 0) {
        perror("[mlockall_preload] WARNING: mlockall failed");
    }
}
