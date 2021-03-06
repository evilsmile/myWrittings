1. 准备知识
   物理层的任务是接收一个原始的位流，并试图将它传递到目标机器。
   PHY是物理层接口收发器，它实现物理层。包括MII（与介质无关接口）子层、PCS（物理编码子层）等其它子层。
   PHY在发送数据的时候，接收MAC发过来的数据（对PHY来说，没有帧的概念，对它来说一切都是原始的位流）。然后每4bit增加1bit的检错码，然后把并行数据转化为串行流数据，再按物理层的编码规则把数据编码，再变为模拟信号把数据送出去。
   隔离变压器把PHY送出来的差分信号用差模耦合的线圈耦合滤波以增强信号，并通过电磁场的转换耦合到连接网线的另一端。
   MII，与介质无关表明在不对MAC硬件重新设计或交换的情况下，任何类型的PHY设备都可以正常工作。
   MAC（介质访问控制协议）主要负责控制与连接物理层的物理介质，以实现无差错传输。在发送数据的时候，MAC协议可以事先判断是否可以发送数据，如果可以发送将给数据加上一些控制信息，最终将数据以及控制信息以规定的格式发送到物理层；在接收数据的时候，MAC协议首先判断输入的信息是否有传输错误，如果没有错误，则去年控制信息发送到LLC层。

2. DM9000

   [====DM9000的管脚===]
   分为8大类：
   一、MII Interface
       外部扩张接口
   二、Processor Interface
       处理器（ARM）与DM9000的接口，包括：片选、地址、数据、命令、状态标志
       IO16：字命令标志，当内部存储器的总线是16位或32位时
       INT：中断请求
   三、EEPROM Interface
       控制EEPROM的接口
   四、Clock Interface
       25M时钟接口
   五、LED Interface
   六、10/100M PHY/Fiber
       与网线相连的。
   七、Miscellaneous
   八、Power Pins

	管脚号      	输入输出类型	管脚名称 	管脚功能
   	1		I		IOR#		读命令
  	2		I		IOW#		写命令
       	3		I		AEN		地址使能
	4		O		IOWAIT		L表示命令等待，正常情况下是H。使用上拉电阻进行上拉，增强信号
	6~13 82~89	I/O		SD0~15		数据总线
	92		I		CMD		H:data; L:addr	
	100		O		INT		中断请求
   

    [==DM9000的控制器==]
    DM9000有许多的控制和状态寄存器，我们可以通过主机控制它。这些寄存器(CSRs)是字节对齐的。所有的(CSRs)被硬件设置为它们默认的值，也可以被软件设置为特定的值。


    [==DM9000的初始化==]
    (1. 配置相关的管脚
    (2. 进行ID测试
    (3. 配置寄存器
       (a. 激活内部PHY
       (b. 软件复位
       (c. 使能中断
       (d. 清除原网络状和中断状态
       (e. 对发射和接收进行新的控制
       (f. 设置MAC地址
       (g. 清除原网络状态和中断状态
       (h. 使能中断

    [==DM9000发送数据包==]
    DM9000发送数据包共包括两个过程：（1）发送过程；（2）状态置位过程
    发送过程：
      a.检测内在数据位宽
      b.将数据写入TX SRAM
      c.将传输的长度写入MDRAL＆MDRAH
      d.将TXCR的TXREQ置为1，当数据发送完毕后将TXREQ置为0（这个标志可以用来检测数据是否发送完毕）。
    置位过程：
      a.系统会将ISR(reg_FEH)的bit[1]即PTS置1（之前必须设置IMR的PTM位为1，即使能数据包发送）。这个状态位可以用在中断服务函数中。
      b.系统会使NSR(reg_01)的bit[2]即TX1END置1.这个中断位可以用在轮询中。
     注意，内存数据位宽是可以通过ISR的bit[7:6]设置的，可以设置为8bit、16bit、32bit。 

     [==DM9000数据包接收===]
     DM9000数据包的接收共包括两个过程：（1）接收过程；（2）状态置位过程
     接收过程：
       a.通过MRCMDX读取数据包的第一个字节，并辨别其后是否有数据包； 
       b.驱动IO的宽度
       c.通过MRCMD读数据包的第二和第三字节，得到RXSR的值和接收数据包的长度
       d.接收数据包
     状态置位过程：
       数据包接收完成后，会置位ISR的第一位为1.


     [=== DM9000 ISR===]
     中断状态寄存器。读取该中断状态寄存器之后，还需要将读取结果存放回该寄存器，也就是需要清除中断状态，否则无法再次响应中断。


3. Linux网络驱动程序
   Linux网络驱动程序的体系结构从上到下可依次划分为网络协议接口、网络设备接口层、提供实际功能的设备驱动功能层以及网络设备媒介层。Linux内核中提供了网络设备接口级别以上层次的代码，所以移植或编写特定网络硬件的驱动程序最主要的工作就是完成设备驱动功能层，主要包括数据的接收、发送等控制。在Linux中所有网络都抽象为一个接口，由结构体net_device来表示网络设备在内核中的运行情况，即网络设备接口。它既包括了网络设备接口，如loopback设备，也包括了硬件网络设备接口，如以太网卡。
   驱动程序运行时，操作系统先调用检测例程以发现安装的网卡，如网卡支持即插即用，检测例程自动发现网卡参数。否则，驱动程序运行之前，设置好网卡参数供驱动程序使用。核心发送数据时，调用驱动程序的发送例程。将数据定入空间，再激活物理发送过程。面向物理层程序中断处理例程。当网卡接收数据、发送过程结束或出错时，网卡产生中断，核心调用中断处理例程，再判断中断发生原因，并进行处理。
   驱动程序流程分为主程序和中断服务程序。主程序进行DM9000的初始化和网卡检测、网卡参数的获取。中断服务程序则以程序查询方式识别中断源，完成相应处理。
 			主程序
			   |
			   @
		    DM9000初始化
		    	   |
			   @
		       检测网卡
		           |
			   @
		     获取网卡参数
		           |
			   @
			 开中断
			   |
			   @
			 中断服务
			   |
			   @
			  END

	  中断服务入口
	       |
	       @
	   现场保护
	       |
	       @
	     ERROR?
	       |
	       @
	    错误处理
	       |
	       @
	  收到新的数据
	       |
	       @
	 读取新收到的数据
	       |
	       @
      送到上层应用软件处理
               |
	       @
	    发送数据
	       |
	       @
     确定接收主机的物理地址
               |
	       @
	    发送数据
	       |
	       @
	    中断返回
   在整个过程中，首先要通过检测物理设备的硬件特性判断网络物理设备是否存在，然后决定是否启动这个驱动程序。接着会对设备进行资源配置，比如，即插即用的硬件就可以在这个时候进行配置；而在嵌入式平台上，以太网的MAC地址也在这里指定。配置好硬件占用的资源后，就可向系统申请这些资源，如中断、I／O空间等。最后，对结构体net_device相应的成员变量初始化，使得一个网络设备可被系统使用。
   数据包的发送和接收是实现Linux网络驱动程序中的关键过程。对这两个过程处理的好坏直接影响到网络的整个运行质量。驱动程序中并不存在一个接收方法 。就由底层驱动程序来通知系统有数据收到。一般情况下，设备收到数据后都会产生一个中断，在中断程序中驱动程序申请一块sk_buff，从硬件读出数据放到申请好的缓冲区中。
