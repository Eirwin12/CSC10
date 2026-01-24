#include <linux/interrupt.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/jiffies.h>
#include <linux/io.h>

#define DEVNAME "PIO Interrupt Handler"

#define HW_REGS_BASE (0xFF200000)
#define HW_REGS_SPAN (0x00200000)
#define HW_REGS_MASK (HW_REGS_SPAN - 1)
#define LED_PIO_BASE (0x0)
#define HWREG(x) (*(volatile uint32_t *)(x))

// pointer to PIO device registers
static volatile unsigned int *PIO_ptr;
// irq number for switches PIO
static int irq_number;

static unsigned long last_interrupt_time = 0;

irqreturn_t irq_handler(int irq, void *dev_id)
{
	unsigned int irq_status = *(PIO_ptr + 3);
	*(PIO_ptr + 3) = 0xF0;

	unsigned long current_time = jiffies;

	if(time_before(current_time, last_interrupt_time + msecs_to_jiffies(200))){
		return IRQ_HANDLED;
	}
	last_interrupt_time = current_time;
	static int count = 0;
	HWREG(LED_PIO_BASE + HW_REGS_BASE) = count;
	count++;
	if(irq_status & 0x10){
		printk(KERN_INFO DEVNAME ": Switch SW4 is hoog gemaakt en count = %d !\n", count);	
	}
	if(irq_status & 0x20){
		printk(KERN_INFO DEVNAME ": Switch SW5 is hoog gemaakt en count = %d !\n", count);
	}
	if(irq_status & 0x40){
		printk(KERN_INFO DEVNAME ": Switch SW6 is hoog gemaakt en count = %d !\n", count);
	}
	if(irq_status & 0x80){
		printk(KERN_INFO DEVNAME ": Switch SW7 is hoog gemaakt en count = %d !\n", count);
	}
	//printk(KERN_INFO DEVNAME ": IRQ called %d time(s)!\n", count);
	return IRQ_HANDLED;
}

static int init_handler(struct platform_device *pdev)
{
	// map the PIO device registers into virtual memory
	void *mem_ptr = devm_platform_ioremap_resource(pdev, 0);
	if (IS_ERR(mem_ptr)) {
		printk(KERN_ALERT DEVNAME ": ERROR: no base address found for PIO device\n");
		return PTR_ERR(mem_ptr);
	}
	PIO_ptr = mem_ptr;
	// get the irq number of the PIO device
	irq_number = platform_get_irq(pdev, 0);
	if (irq_number < 0) {
		printk(KERN_ALERT DEVNAME ": ERROR: No IRQ number found for PIO device\n");
		return irq_number;
	}
	printk(KERN_INFO DEVNAME ": IRQ %d is being registered!\n", irq_number);
	// register irq handler
	int err = request_irq(irq_number, irq_handler, 0, DEVNAME, NULL);
	if (err != 0) {
		printk(KERN_ALERT DEVNAME ": ERROR: IRQ %d can not be registered\n", irq_number);
	}
	

	*(PIO_ptr + 3) = 0xF0;
	*(PIO_ptr + 2) = 0xF0;
	printk(KERN_INFO DEVNAME ": Module geladen. Interrupt actief voor SW4-SW7.\n");

	return err;
}

static void clean_handler(struct platform_device *pdev)
{
	*(PIO_ptr + 2) = 0x00;
	printk(KERN_INFO DEVNAME ": IRQ %d is being unregistered!\n", irq_number);
	// unregister the IRQ
	if (free_irq(irq_number, NULL) == NULL) {
		printk(KERN_ALERT DEVNAME ": ERROR: IRQ %d can not be unregistered\n", irq_number);
	}
}

// describe which device we want to bind to this kernel module
// this must match an entry in the device tree
static const struct of_device_id mijn_module_id[] ={
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
	// See https://elixir.bootlin.com/linux/v6.6.22/source/include/linux/platform_device.h#L236 for an explanation why we use .remove_new in stead of .remove
	.remove_new = clean_handler
};

// register this platform driver
module_platform_driver(mijn_module_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniël Versluis, Harry Broeders");
MODULE_DESCRIPTION("Kernel module to handle PIO interrupt from DE1-SoC board");
