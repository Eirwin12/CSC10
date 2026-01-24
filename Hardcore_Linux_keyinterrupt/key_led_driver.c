/*
 * DE1-SoC Key/LED Driver met Interrupt Support
 * Character device driver voor KEY interrupts en LED control
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/io.h>
#include <linux/interrupt.h>
#include <linux/uaccess.h>
#include <linux/wait.h>
#include <linux/poll.h>
#include <linux/sched.h>
#include <linux/slab.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("CSC10 Student");
MODULE_DESCRIPTION("DE1-SoC KEY/LED Driver with Interrupt Support");
MODULE_VERSION("1.0");

/* Hardware addresses - Lightweight HPS-to-FPGA bridge */
#define LW_BRIDGE_BASE      0xFF200000
#define LW_BRIDGE_SPAN      0x00200000

/* PIO offsets (relatief ten opzichte van LW bridge) */
#define LED_PIO_OFFSET      0x00000000
#define KEY_PIO_OFFSET      0x00000010

/* PIO register offsets */
#define PIO_DATA_REG        0x00
#define PIO_DIRECTION_REG   0x04
#define PIO_INTERRUPT_MASK  0x08
#define PIO_EDGE_CAPTURE    0x0C

/* IRQ number voor KEY interrupt (f2h_irq_p0[0] = IRQ 72) */
#define KEY_IRQ_NUMBER      72

/* Device info */
#define DEVICE_NAME         "key_led"
#define CLASS_NAME          "key_led_class"

/* Global variables */
static int major_number;
static struct class *key_led_class = NULL;
static struct device *key_led_device = NULL;
static struct cdev key_led_cdev;

static void __iomem *lw_bridge_base;
static void __iomem *led_pio_base;
static void __iomem *key_pio_base;

/* Interrupt data */
static unsigned char last_key_pressed = 0;
static int key_event_pending = 0;
static DECLARE_WAIT_QUEUE_HEAD(key_wait_queue);
static struct fasync_struct *async_queue = NULL;

/* Function prototypes */
static int device_open(struct inode *, struct file *);
static int device_release(struct inode *, struct file *);
static ssize_t device_read(struct file *, char __user *, size_t, loff_t *);
static ssize_t device_write(struct file *, const char __user *, size_t, loff_t *);
static unsigned int device_poll(struct file *, struct poll_table_struct *);
static int device_fasync(int, struct file *, int);
static irqreturn_t key_irq_handler(int, void *);

/* File operations structure */
static struct file_operations fops = {
    .owner = THIS_MODULE,
    .open = device_open,
    .release = device_release,
    .read = device_read,
    .write = device_write,
    .poll = device_poll,
    .fasync = device_fasync,
};

/*
 * Interrupt handler voor KEY presses
 */
static irqreturn_t key_irq_handler(int irq, void *dev_id)
{
    unsigned int edge_capture;
    
    /* Lees welke key(s) ingedrukt zijn */
    edge_capture = ioread32(key_pio_base + PIO_EDGE_CAPTURE);
    
    if (edge_capture) {
        /* Sla key press op */
        last_key_pressed = (unsigned char)edge_capture;
        
        /* Clear interrupt door naar edge capture register te schrijven */
        iowrite32(edge_capture, key_pio_base + PIO_EDGE_CAPTURE);
        
        /* Zet corresponderende LED aan */
        iowrite32(edge_capture, led_pio_base + PIO_DATA_REG);
        
        /* Signal waiting processes */
        key_event_pending = 1;
        wake_up_interruptible(&key_wait_queue);
        
        /* Send async notification (SIGIO) */
        if (async_queue) {
            kill_fasync(&async_queue, SIGIO, POLL_IN);
        }
        
        printk(KERN_INFO "KEY_LED: Key pressed: 0x%02X, LED set to: 0x%02X\n", 
               edge_capture, edge_capture);
    }
    
    return IRQ_HANDLED;
}

/*
 * Device open
 */
static int device_open(struct inode *inodep, struct file *filep)
{
    printk(KERN_INFO "KEY_LED: Device opened\n");
    return 0;
}

/*
 * Device release
 */
static int device_release(struct inode *inodep, struct file *filep)
{
    /* Remove async notification */
    device_fasync(-1, filep, 0);
    printk(KERN_INFO "KEY_LED: Device closed\n");
    return 0;
}

/*
 * Device read - lees laatste key press (blocking)
 */
static ssize_t device_read(struct file *filep, char __user *buffer, 
                          size_t len, loff_t *offset)
{
    unsigned char key_value;
    
    /* Wait voor key event */
    if (wait_event_interruptible(key_wait_queue, key_event_pending)) {
        return -ERESTARTSYS;
    }
    
    key_value = last_key_pressed;
    key_event_pending = 0;
    
    /* Copy naar user space */
    if (len > 0) {
        if (copy_to_user(buffer, &key_value, 1)) {
            return -EFAULT;
        }
        return 1;
    }
    
    return 0;
}

/*
 * Device write - schrijf naar LEDs
 * Format: echo "0x0F" > /dev/key_led  (zet alle LEDs aan)
 */
static ssize_t device_write(struct file *filep, const char __user *buffer,
                           size_t len, loff_t *offset)
{
    char kbuf[16];
    unsigned long led_value;
    int ret;
    
    if (len > sizeof(kbuf) - 1) {
        len = sizeof(kbuf) - 1;
    }
    
    if (copy_from_user(kbuf, buffer, len)) {
        return -EFAULT;
    }
    
    kbuf[len] = '\0';
    
    /* Parse input (support hex en decimal) */
    ret = kstrtoul(kbuf, 0, &led_value);
    if (ret) {
        printk(KERN_WARNING "KEY_LED: Invalid value\n");
        return -EINVAL;
    }
    
    /* Schrijf naar LED PIO (alleen lower 4 bits) */
    iowrite32(led_value & 0x0F, led_pio_base + PIO_DATA_REG);
    
    printk(KERN_INFO "KEY_LED: LED set to 0x%02lX\n", led_value & 0x0F);
    
    return len;
}

/*
 * Poll support voor non-blocking reads
 */
static unsigned int device_poll(struct file *filep, struct poll_table_struct *wait)
{
    poll_wait(filep, &key_wait_queue, wait);
    
    if (key_event_pending) {
        return POLLIN | POLLRDNORM;
    }
    
    return 0;
}

/*
 * Async notification support (SIGIO)
 */
static int device_fasync(int fd, struct file *filep, int mode)
{
    return fasync_helper(fd, filep, mode, &async_queue);
}

/*
 * Module initialization
 */
static int __init key_led_init(void)
{
    int result;
    dev_t dev;
    
    printk(KERN_INFO "KEY_LED: Initializing driver\n");
    
    /* Allocate device number */
    result = alloc_chrdev_region(&dev, 0, 1, DEVICE_NAME);
    if (result < 0) {
        printk(KERN_ALERT "KEY_LED: Failed to allocate device number\n");
        return result;
    }
    major_number = MAJOR(dev);
    
    /* Create device class */
    key_led_class = class_create(THIS_MODULE, CLASS_NAME);
    if (IS_ERR(key_led_class)) {
        unregister_chrdev_region(dev, 1);
        printk(KERN_ALERT "KEY_LED: Failed to create class\n");
        return PTR_ERR(key_led_class);
    }
    
    /* Create device */
    key_led_device = device_create(key_led_class, NULL, dev, NULL, DEVICE_NAME);
    if (IS_ERR(key_led_device)) {
        class_destroy(key_led_class);
        unregister_chrdev_region(dev, 1);
        printk(KERN_ALERT "KEY_LED: Failed to create device\n");
        return PTR_ERR(key_led_device);
    }
    
    /* Initialize cdev */
    cdev_init(&key_led_cdev, &fops);
    key_led_cdev.owner = THIS_MODULE;
    result = cdev_add(&key_led_cdev, dev, 1);
    if (result < 0) {
        device_destroy(key_led_class, dev);
        class_destroy(key_led_class);
        unregister_chrdev_region(dev, 1);
        printk(KERN_ALERT "KEY_LED: Failed to add cdev\n");
        return result;
    }
    
    /* Map hardware addresses */
    lw_bridge_base = ioremap(LW_BRIDGE_BASE, LW_BRIDGE_SPAN);
    if (!lw_bridge_base) {
        printk(KERN_ALERT "KEY_LED: Failed to map LW bridge\n");
        goto fail_ioremap;
    }
    
    led_pio_base = lw_bridge_base + LED_PIO_OFFSET;
    key_pio_base = lw_bridge_base + KEY_PIO_OFFSET;
    
    /* Initialize hardware */
    iowrite32(0x0, led_pio_base + PIO_DATA_REG);        /* LEDs uit */
    iowrite32(0xF, key_pio_base + PIO_INTERRUPT_MASK);  /* Enable all KEY interrupts */
    iowrite32(0xF, key_pio_base + PIO_EDGE_CAPTURE);    /* Clear edge capture */
    
    /* Request IRQ */
    result = request_irq(KEY_IRQ_NUMBER, key_irq_handler, 
                        IRQF_SHARED, DEVICE_NAME, (void *)&key_led_cdev);
    if (result) {
        printk(KERN_ALERT "KEY_LED: Failed to request IRQ %d\n", KEY_IRQ_NUMBER);
        goto fail_irq;
    }
    
    printk(KERN_INFO "KEY_LED: Driver loaded successfully (Major: %d, IRQ: %d)\n", 
           major_number, KEY_IRQ_NUMBER);
    printk(KERN_INFO "KEY_LED: Device node: /dev/%s\n", DEVICE_NAME);
    
    return 0;

fail_irq:
    iounmap(lw_bridge_base);
fail_ioremap:
    cdev_del(&key_led_cdev);
    device_destroy(key_led_class, dev);
    class_destroy(key_led_class);
    unregister_chrdev_region(dev, 1);
    return -1;
}

/*
 * Module cleanup
 */
static void __exit key_led_exit(void)
{
    dev_t dev = MKDEV(major_number, 0);
    
    /* Disable interrupts */
    iowrite32(0x0, key_pio_base + PIO_INTERRUPT_MASK);
    
    /* Free IRQ */
    free_irq(KEY_IRQ_NUMBER, (void *)&key_led_cdev);
    
    /* Unmap hardware */
    iounmap(lw_bridge_base);
    
    /* Remove character device */
    cdev_del(&key_led_cdev);
    device_destroy(key_led_class, dev);
    class_destroy(key_led_class);
    unregister_chrdev_region(dev, 1);
    
    printk(KERN_INFO "KEY_LED: Driver unloaded\n");
}

module_init(key_led_init);
module_exit(key_led_exit);
