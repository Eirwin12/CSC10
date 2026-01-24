/*
 * Test programma voor KEY/LED driver
 * Simpel blocking read test - wacht op key press en print resultaat
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#define DEVICE_PATH "/dev/key_led"

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
    unsigned char key_value;
    int ret;
    
    printf("=== DE1-SoC KEY/LED Test Program ===\n\n");
    
    /* Open device */
    fd = open(DEVICE_PATH, O_RDWR);
    if (fd < 0) {
        perror("Failed to open device");
        printf("Make sure the kernel module is loaded:\n");
        printf("  sudo insmod key_led_driver.ko\n");
        return 1;
    }
    
    printf("Device opened successfully\n");
    printf("Waiting for key presses... (Press Ctrl+C to exit)\n\n");
    
    /* Test 1: Blocking read - wacht op key presses */
    while (1) {
        ret = read(fd, &key_value, 1);
        if (ret < 0) {
            if (errno == EINTR) {
                printf("\nInterrupted by signal\n");
                break;
            }
            perror("Read error");
            break;
        }
        
        if (ret > 0) {
            print_key_status(key_value);
            
            /* De LED is automatisch aangezet door de interrupt handler */
            printf("LED should now be ON for the pressed key(s)\n\n");
        }
    }
    
    /* Test 2: Handmatig LEDs aansturen */
    printf("\n=== Manual LED Control Test ===\n");
    
    printf("Setting all LEDs ON...\n");
    write(fd, "15\n", 3);  /* 15 = 0b1111 = alle LEDs aan */
    sleep(1);
    
    printf("Setting LED0 and LED2 ON...\n");
    write(fd, "5\n", 2);   /* 5 = 0b0101 = LED0 en LED2 aan */
    sleep(1);
    
    printf("Turning all LEDs OFF...\n");
    write(fd, "0\n", 2);   /* 0 = 0b0000 = alle LEDs uit */
    
    close(fd);
    printf("\nTest completed\n");
    
    return 0;
}
