#include <linux/cdev.h>
#include <linux/fs.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/interrupt.h>
 
#define DEVNAME "switches"
 
// data can be global because there will be no minor devices
// virtual address of switches PIO
static volatile unsigned int *PIO_ptr;
 
// device number
static dev_t dev = 0;
// device major number
static int dev_major = 0;
 
// device class structure
static struct class *my_dev_class = NULL;
 
// char device structure
static struct cdev my_dev_cdev;
 
// irq number for switches PIO
static int irq_number;
 
// variabele om de lijst met processen die asynchroon geïnformeerd moeten worden te bewaren
static struct fasync_struct *my_async_queue = NULL;
 
// IRQ handler
static irqreturn_t irq_handler(int irq, void *dev_id)
{
    // Clear edge capture register
    *(PIO_ptr + 3) = 0x0F;
   
    printk(KERN_INFO DEVNAME ": IRQ received, sending SIGIO signal\n");
   
    // Stuur SIGIO signal naar geregistreerde processen
    kill_fasync(&my_async_queue, SIGIO, POLL_IN);
   
    return IRQ_HANDLED;
}
 
static int my_dev_open(struct inode *inode, struct file *file)
{
    printk(KERN_INFO DEVNAME ": Device open\n");
    return 0;
}
 
static int my_dev_release(struct inode *inode, struct file *file)
{
    printk(KERN_INFO DEVNAME ": Device close\n");
    return 0;
}
 
static ssize_t my_dev_read(struct file *file, char *buf, size_t count, loff_t *offset)
{
    uint8_t switch_value;
   
    printk(KERN_INFO DEVNAME ": Device read\n");
   
    // Check if already read
    if (*offset > 0) {
        return 0;  // EOF
    }
   
    // Read switch value from PIO register
    switch_value = (uint8_t)(*PIO_ptr & 0xFF);
   
    printk(KERN_INFO DEVNAME ": Switch value read: 0x%02X\n", switch_value);
   
    // Copy to user space
    if (copy_to_user(buf, &switch_value, 1)) {
        printk(KERN_ALERT DEVNAME ": ERROR: copy_to_user failed\n");
        return -EFAULT;
    }
   
    *offset = 1;
    return 1;  // Return number of bytes read
}
 
// fasync handler
static int my_dev_fasync(int fd, struct file *filp, int on)
{
    printk(KERN_INFO DEVNAME ": Device fasync\n");
   
    int err = fasync_helper(fd, filp, on, &my_async_queue);
    if (err < 0) {
        printk(KERN_ALERT DEVNAME ": ERROR: fasync_helper failed\n");
        return err;
    }
   
    static int on_counter = 0;
   
    if (on) {
        on_counter++;
        if (on_counter == 1) {
            // Registreer interrupt
            printk(KERN_INFO DEVNAME ": Registering IRQ %d\n", irq_number);
            err = request_irq(irq_number, irq_handler, 0, DEVNAME, NULL);
            if (err != 0) {
                printk(KERN_ALERT DEVNAME ": ERROR: IRQ %d can not be registered\n", irq_number);
                return err;
            }
           
            // Enable interrupts in PIO module
            *(PIO_ptr + 3) = 0x0F;  // Clear edge capture register
            *(PIO_ptr + 2) = 0x0F;  // Interrupt mask register
            printk(KERN_INFO DEVNAME ": Interrupts enabled\n");
        }
    } else {
        on_counter--;
        if (on_counter == 0) {
            // Disable interrupts in PIO module
            *(PIO_ptr + 2) = 0x00;  // Interrupt mask register (disable)
           
            // Free IRQ
            free_irq(irq_number, NULL);
            printk(KERN_INFO DEVNAME ": Interrupts disabled and IRQ freed\n");
        }
    }
   
    return 0;
}
 
// initialize file operations
static const struct file_operations my_dev_fops = {
    .open = my_dev_open,
    .release = my_dev_release,
    .read = my_dev_read,
    .fasync = my_dev_fasync
};
 
// callback function called when a device is added to this class
// used to set the permissions of the device node to 0666 (read and write for all users)
static int my_dev_uevent(const struct device *dev, struct kobj_uevent_env *env)
{
    int ret = add_uevent_var(env, "DEVMODE=%#o", 0666);
    if (ret < 0) {
        printk(KERN_ALERT DEVNAME ": ERROR: add uevent var failed\n");
        return ret;
    }
    return 0;
}
 
static int init_handler(struct platform_device *pdev)
{
    printk(KERN_INFO DEVNAME ": Create character device\n");
   
    // allocate a range of char device numbers
    // in this case only one minor number
    // the major number will be assigned dynamically
    int err = alloc_chrdev_region(&dev, 0, 1, "switches");
    if (err < 0) {
        printk(KERN_ALERT DEVNAME ": ERROR: no major device number available\n");
        return err;
    }
   
    // extract the assigned major device number
    dev_major = MAJOR(dev);
   
    // create device class
    my_dev_class = class_create("switches");
    if (IS_ERR(my_dev_class)) {
        printk(KERN_ALERT DEVNAME ": ERROR: class can not be created for device\n");
        err = PTR_ERR(my_dev_class);
        goto cleanup_chrdev_region;
    }
   
    // my_dev_uevent is called when a device is added to this class
    my_dev_class->dev_uevent = my_dev_uevent;
   
    // init new device
    cdev_init(&my_dev_cdev, &my_dev_fops);
    my_dev_cdev.owner = THIS_MODULE;
   
    // create device in /sys/devices/virtual/switches/switches
    err = cdev_add(&my_dev_cdev, MKDEV(dev_major, 0), 1);
    if (err < 0) {
        printk(KERN_ALERT DEVNAME ": ERROR: device number can not be added for device\n");
        goto cleanup_class;
    }
   
    // create device node /dev/switches
    struct device *my_dev = device_create(my_dev_class, NULL, MKDEV(dev_major, 0), NULL, "switches");
    if (IS_ERR(my_dev)) {
        printk(KERN_ALERT DEVNAME ": ERROR: device can not be created for driver\n");
        err = PTR_ERR(my_dev);
        goto cleanup_cdev;
    }
   
    // map the PIO device registers into virtual memory
    void *mem_ptr = devm_platform_ioremap_resource(pdev, 0);
    if (IS_ERR(mem_ptr)) {
        printk(KERN_ALERT DEVNAME ": ERROR: no base address found for PIO device\n");
        err = PTR_ERR(mem_ptr);
        goto cleanup_device;
    }
   
    PIO_ptr = mem_ptr;
   
    // Get the IRQ number of the PIO device
    irq_number = platform_get_irq(pdev, 0);
    if (irq_number < 0) {
        printk(KERN_ALERT DEVNAME ": ERROR: No IRQ number found for PIO device\n");
        err = irq_number;
        goto cleanup_device;
    }
   
    printk(KERN_INFO DEVNAME ": IRQ %d is being registered\n", irq_number);
   
    // Register IRQ handler
    err = request_irq(irq_number, irq_handler, 0, DEVNAME, NULL);
    if (err != 0) {
        printk(KERN_ALERT DEVNAME ": ERROR: IRQ %d can not be registered\n", irq_number);
        goto cleanup_device;
    }
   
    // Enable interrupts in PIO module
    *(PIO_ptr + 3) = 0x0F;  // Clear edge capture register
    *(PIO_ptr + 2) = 0x0F;  // Interrupt mask register (enable interrupts)
   
    return 0;
   
    // cleanup on errors
cleanup_device:
    device_destroy(my_dev_class, MKDEV(dev_major, 0));
   
cleanup_cdev:
    cdev_del(&my_dev_cdev);
   
cleanup_class:
    class_destroy(my_dev_class);
   
cleanup_chrdev_region:
    unregister_chrdev_region(dev, 1);
    return err;
}
 
static void clean_handler(struct platform_device *pdev)
{
    printk(KERN_INFO DEVNAME ": Destroy character device\n");
   
    // Disable interrupts in PIO module
    if (PIO_ptr != NULL) {
        *(PIO_ptr + 2) = 0x00;  // Interrupt mask register
    }
   
    // Unregister IRQ
    printk(KERN_INFO DEVNAME ": IRQ %d is being unregistered\n", irq_number);
    free_irq(irq_number, NULL);
   
    device_destroy(my_dev_class, MKDEV(dev_major, 0));
    cdev_del(&my_dev_cdev);
    class_destroy(my_dev_class);
    unregister_chrdev_region(dev, 1);
}
 
// describe which device we want to bind to this kernel module
// this must match an entry in the device tree
static const struct of_device_id mijn_module_id[] = {
    {.compatible = "switches"},
    {}
};
 
// platform driver structure linking handlers to events
static struct platform_driver mijn_module_driver = {
    .driver = {
        .name = DEVNAME,
        .owner = THIS_MODULE,
        .of_match_table = of_match_ptr(mijn_module_id),
    },
    .probe = init_handler,
    .remove_new = clean_handler
};
 
// register this platform driver
module_platform_driver(mijn_module_driver);
 
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniël Versluis, Harry Broeders");
MODULE_DESCRIPTION("Kernel module to handle PIO interrupt from DE1-SoC board with async I/O")