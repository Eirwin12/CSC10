/*
 * Test programma met poll() voor non-blocking key detection
 * Gebruikt poll() om te wachten op key events zonder te blocken
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <poll.h>
#include <string.h>
#include <errno.h>

#define DEVICE_PATH "/dev/key_led"
#define POLL_TIMEOUT 1000  /* 1 seconde timeout */

void print_key_status(unsigned char key_value) {
    printf("Key pressed: ");
    if (key_value & 0x01) printf("KEY0 ");
    if (key_value & 0x02) printf("KEY1 ");
    if (key_value & 0x04) printf("KEY2 ");
    if (key_value & 0x08) printf("KEY3 ");
    printf("(0x%02X)\n", key_value);
}

int main(int argc, char *argv[]) {
    int fd;
    struct pollfd pfd;
    unsigned char key_value;
    int ret;
    int event_count = 0;
    
    printf("=== DE1-SoC KEY Poll Test ===\n\n");
    
    /* Open device */
    fd = open(DEVICE_PATH, O_RDWR | O_NONBLOCK);
    if (fd < 0) {
        perror("Failed to open device");
        printf("Make sure the kernel module is loaded:\n");
        printf("  sudo insmod key_led_driver.ko\n");
        return 1;
    }
    
    printf("Device opened successfully\n");
    printf("Using poll() to wait for key presses...\n");
    printf("Press Ctrl+C to exit\n\n");
    
    /* Setup poll structure */
    pfd.fd = fd;
    pfd.events = POLLIN;
    
    while (1) {
        printf("Waiting for key event (timeout: %d ms)...\n", POLL_TIMEOUT);
        
        /* Poll voor events */
        ret = poll(&pfd, 1, POLL_TIMEOUT);
        
        if (ret < 0) {
            if (errno == EINTR) {
                printf("Interrupted\n");
                break;
            }
            perror("Poll error");
            break;
        } else if (ret == 0) {
            /* Timeout */
            printf("Timeout - no key pressed\n");
        } else {
            /* Event available */
            if (pfd.revents & POLLIN) {
                ret = read(fd, &key_value, 1);
                if (ret > 0) {
                    event_count++;
                    printf("[Event #%d] ", event_count);
                    print_key_status(key_value);
                    printf("\n");
                }
            }
        }
    }
    
    close(fd);
    printf("\nTotal events received: %d\n", event_count);
    
    return 0;
}
