/*
 * Test programma voor asynchrone KEY interrupts
 * Gebruikt SIGIO signaal om key presses te detecteren
 * Dit demonstreert asynchrone I/O vanuit user space
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>
#include <errno.h>

#define DEVICE_PATH "/dev/key_led"

static int device_fd = -1;
static volatile int key_events = 0;

void print_key_status(unsigned char key_value) {
    printf("Key pressed: ");
    if (key_value & 0x01) printf("KEY0 ");
    if (key_value & 0x02) printf("KEY1 ");
    if (key_value & 0x04) printf("KEY2 ");
    if (key_value & 0x08) printf("KEY3 ");
    printf("(0x%02X)\n", key_value);
}

/*
 * SIGIO signal handler - wordt aangeroepen bij key interrupt
 */
void sigio_handler(int signo) {
    unsigned char key_value;
    int ret;
    
    if (signo == SIGIO) {
        /* Read key value (non-blocking) */
        ret = read(device_fd, &key_value, 1);
        if (ret > 0) {
            printf("\n[ASYNC] ");
            print_key_status(key_value);
            key_events++;
        }
    }
}

/*
 * Ctrl+C handler
 */
void sigint_handler(int signo) {
    printf("\n\nReceived %d key events\n", key_events);
    printf("Exiting...\n");
    
    if (device_fd >= 0) {
        close(device_fd);
    }
    
    exit(0);
}

int main(int argc, char *argv[]) {
    int flags;
    struct sigaction sa_io, sa_int;
    
    printf("=== DE1-SoC Asynchronous KEY Test ===\n\n");
    
    /* Setup signal handlers */
    memset(&sa_io, 0, sizeof(sa_io));
    sa_io.sa_handler = sigio_handler;
    sigemptyset(&sa_io.sa_mask);
    sa_io.sa_flags = 0;
    
    if (sigaction(SIGIO, &sa_io, NULL) < 0) {
        perror("Failed to setup SIGIO handler");
        return 1;
    }
    
    memset(&sa_int, 0, sizeof(sa_int));
    sa_int.sa_handler = sigint_handler;
    sigemptyset(&sa_int.sa_mask);
    sa_int.sa_flags = 0;
    
    if (sigaction(SIGINT, &sa_int, NULL) < 0) {
        perror("Failed to setup SIGINT handler");
        return 1;
    }
    
    /* Open device */
    device_fd = open(DEVICE_PATH, O_RDWR | O_NONBLOCK);
    if (device_fd < 0) {
        perror("Failed to open device");
        printf("Make sure the kernel module is loaded:\n");
        printf("  sudo insmod key_led_driver.ko\n");
        return 1;
    }
    
    printf("Device opened successfully\n");
    
    /* Setup async notification */
    if (fcntl(device_fd, F_SETOWN, getpid()) < 0) {
        perror("Failed to set process owner");
        close(device_fd);
        return 1;
    }
    
    flags = fcntl(device_fd, F_GETFL);
    if (fcntl(device_fd, F_SETFL, flags | FASYNC) < 0) {
        perror("Failed to enable async notification");
        close(device_fd);
        return 1;
    }
    
    printf("Async notification enabled\n");
    printf("Press any KEY on the DE1-SoC board...\n");
    printf("Press Ctrl+C to exit\n\n");
    
    /* Main loop - kan andere dingen doen terwijl we wachten op key events */
    while (1) {
        /* Simulate doing other work */
        printf(".");
        fflush(stdout);
        sleep(1);
    }
    
    return 0;
}
