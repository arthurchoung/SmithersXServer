#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>

void main(int argc, char **argv)
{
    char *path = "/dev/input/mice";

    int fd = open(path, O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "unable to open '%s'\n", path);
        exit(1);
    }

    unsigned char magic[6];
    magic[0] = 0xf3;
    magic[1] = 0xc8;
    magic[2] = 0xf3;
    magic[3] = 0x64;
    magic[4] = 0xf3;
    magic[5] = 0x50;
    write(fd, magic, 6);

    char buf[4];
    for(;;) {
        int n = read(fd, buf, 4);
        if (n == 4) {
            int left = buf[0] & 0x01;
            int right = buf[0] & 0x02;
            int middle = buf[0] & 0x04;
            int dx = buf[1];
            int dy = buf[2];
            int scroll = buf[3];
            printf("dx:%d dy:%d left:%d middle:%d right:%d scroll:%d\n", dx, dy, left, middle, right, scroll);
        } else {
            printf("n:%d\n", n);
        }
    }
    exit(0);
}

