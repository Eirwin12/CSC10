#define switches (volatile int *) 0x0002010
#define leds (int *) 0x0002000
void main()
{ 
    while (1) {
        *leds = *switches;
    }
}
