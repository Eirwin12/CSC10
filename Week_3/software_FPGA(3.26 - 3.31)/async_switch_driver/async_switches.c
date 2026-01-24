#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
 
#define SWITCHES_DEVICE "/dev/switches"
#define LEDS_DEVICE "/dev/leds"
 
int main()
{
    sigset_t signal_set;
    uint8_t counter = 0;  // Teller voor interrupts
 
    // Maak een set van signals aan
    if (sigemptyset(&signal_set) < 0) {
        perror("sigemptyset");
        exit(EXIT_FAILURE);
    }
    // SIGINT wordt verstuurd bij indrukken ctrl-c
    if (sigaddset(&signal_set, SIGINT) < 0) {
        perror("sigaddset");
        exit(EXIT_FAILURE);
    }
    // SIGIO wordt aangeroepen bij interrupt op switches (opgaande flank)
    if (sigaddset(&signal_set, SIGIO) < 0) {
        perror("sigaddset");
        exit(EXIT_FAILURE);
    }
    // Block signals in signal_set (SIGINT en SIGIO) zodat we er in main op kunnen wachten
    if (sigprocmask(SIG_BLOCK, &signal_set, NULL) < 0) {
        perror("sigprocmask");
        exit(EXIT_FAILURE);
    }
 
    // Switches device openen
    int fd_switches = open(SWITCHES_DEVICE, O_RDONLY);
    if(fd_switches < 0) {
        perror("open switches");
        return EXIT_FAILURE;
    }
   
    // LEDs device openen
    int fd_leds = open(LEDS_DEVICE, O_WRONLY);
    if(fd_leds < 0) {
        perror("open leds");
        close(fd_switches);
        return EXIT_FAILURE;
    }
 
    printf("Applicatie registreren voor SIGIO bij device\n");
    // Geef het process id van dit proces door aan het device zodat deze signals kan sturen
    if (fcntl(fd_switches, F_SETOWN, getpid()) < 0) {
        perror("fcntl");
        close(fd_switches);
        close(fd_leds);
        return EXIT_FAILURE;
    }
    // Enable asynchronous notification zodat device signal SIGIO stuurt bij interrupt
    int flags = fcntl(fd_switches, F_GETFL);
    if (flags < 0) {
        perror("fcntl");
        close(fd_switches);
        close(fd_leds);
        return EXIT_FAILURE;
    }
    if (fcntl(fd_switches, F_SETFL, flags | FASYNC) < 0) {
        perror("fcntl");
        close(fd_switches);
        close(fd_leds);
        return EXIT_FAILURE;
    }
 
    printf("Wacht op signaal...\n");
    bool klaar = false;
    while (!klaar) {
        int sig_number;
        sigwait(&signal_set, &sig_number);
        if (sig_number == SIGIO) {
                uint8_t switch_value;
                lseek(fd_switches, 0, SEEK_SET);  // Reset offset
                if (read(fd_switches, &switch_value, 1) < 0) {
                    perror("read");
                    close(fd_switches);
                    close(fd_leds);
                    return EXIT_FAILURE;
                }
               
                // Verhoog counter bij elke interrupt
                counter++;
                printf("SIGIO ontvangen - Interrupt #%d - Counter: %d (0x%02X)\n", counter, counter, counter);
               
                // Stuur counter waarde naar LEDs (binair)
                if (write(fd_leds, &counter, 1) < 0) {
                    perror("write leds");
                    close(fd_switches);
                    close(fd_leds);
                    return EXIT_FAILURE;
                }
                printf("LEDs bijgewerkt naar: %d (binair: 0b", counter);
                for (int i = 7; i >= 0; i--) {
                    printf("%d", (counter >> i) & 1);
                }
                printf(")\n\n");
        }
        else if (sig_number == SIGINT) {
            printf("Signaal %d (SIGINT) ontvangen\n", sig_number);
            klaar = true;
        }
    }
 
    // Device sluiten
    close(fd_switches);
    close(fd_leds);
 
    return EXIT_SUCCESS;
}