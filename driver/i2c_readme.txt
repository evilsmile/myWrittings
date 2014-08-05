一、在Linux驱动中，I2C系统中主要包含以下成员：
 1. I2C Adapter I2C适配器
 2. I2C Driver  某个I2C设备的驱动，可以以driver来理解
 3. I2C Client  某个I2C设备的设备声明，可以以device来理解.

二、I2C Adapter
  I2C Adapter是CPU集成或外接的I2C适配器，用来控制各种I2C从设备，其驱动需要完成对适配器的完整描述，最主要的工作是需要完成i2c_algorithm结构体。这个结构体包含了此I2C控制器的数据传输具体实现，以及对外上报此设备所支持的功能类型。i2c_algorithm结构体中包含了master_xfer、smbus_xfer、functionality三个函数。如果一个I2C适配器不支持I2C通道，那么就将master_xfer成员设为NULL。如果适配器支持SMBUS协议，那么需要去实现smbus_xfer，如果smbus_xfer指针被设置为NULL，那么当使用SMBUS协议的时候将会通过I2C通道进行仿真。master_xfer指向的函数的返回值应该是已经成功处理的消息数，或者返回负数表示出错了。functionality指针很简单，告诉询问这个I2C主控制器都支持什么功能。
  在内核的driver/i2c/i2c-sub.c中实现了一个i2c adapter的例子。

三、I2C Driver
   具体的I2C设备驱动，如相机、传感器、触摸屏、背光控制器等觉硬件设备大多都有或都是通过I2C协议与主机进行数据传输、控制。相应结构体为struct i2c_driver。如同普通设备的驱动能够驱动多个设备一样，一个I2C driver也可以对应多个I2C client。

四、I2C Client
   即I2C设备。I2C设备的注册一般在板级代码中。相关的结构体为i2c_client, i2c_board_info。

五、I2C对外API
  Linux内核中I2C子系统对驱动模块的API：
  // 对外数据结构
  struct i2c_driver — 代表一个I2C设备驱动
  struct i2c_client — 代表一个I2C从设备
  struct i2c_board_info — 从设备创建的模版
  I2C_BOARD_INFO — 创建I2C设备的宏，包含名字和地址
  struct i2c_algorithm — 代表I2C传输方法
  struct i2c_bus_recovery_info — I2C总线恢复信息？内核新加入的结构，不是很清楚。
  //对外函数操作
  module_i2c_driver — 注册I2C设备驱动的宏定义
  i2c_register_board_info — 静态声明（注册）I2C设备，可多个
  i2c_verify_client — 如果设备是i2c_client的dev成员则返回其父指针，否则返回NULL。用来校验设备是否为I2C设备
  i2c_lock_adapter — I2C总线持锁操作，会找到最根源的那个i2c_adapter。说明你的模块必须符合GPL协议才可以使用这个接口。后边以GPL代表。
  i2c_unlock_adapter — 上一个的反操作，GPL
  i2c_new_device — 由i2c_board_info信息声明一个i2c设备（client），GPL
  i2c_unregister_device — 上一个的反操作，GPL。
  i2c_new_dummy — 声明一个名为dummy（指定地址）的I2C设备，GPL
  i2c_verify_adapter — 验证是否是i2c_adapter
  i2c_add_adapter — 声明I2C适配器，系统动态分配总线号。
  i2c_add_numbered_adapter — 同样是声明I2C适配器，但是指定了总线号，GPL
  i2c_del_adapter — 卸载I2C适配器
  i2c_del_driver — 卸载I2C设备驱动
  i2c_use_client — i2c_client引用数+1
  i2c_release_client — i2c_client引用数-1
  __i2c_transfer — 没有自动持锁(adapter lock)的I2C传输接口
  i2c_transfer — 自动持锁的I2C传输接口
  i2c_master_send — 单条消息发送
  i2c_master_recv — 单条消息接收
  i2c_smbus_read_byte — SMBus “receive byte” protocol
  i2c_smbus_write_byte — SMBus “send byte” protocol
  i2c_smbus_read_byte_data — SMBus “read byte” protocol
  i2c_smbus_write_byte_data — SMBus “write byte” protocol
  i2c_smbus_read_word_data — SMBus “read word” protocol
  i2c_smbus_write_word_data — SMBus “write word” protocol
  i2c_smbus_read_block_data — SMBus “block read” protocol
  i2c_smbus_write_block_data — SMBus “block write” protocol
  i2c_smbus_xfer — execute SMBus protocol operations

  对以上一些I2C的API进行分类：

  No.		Adapter				Driver			Device(client)			Transfer
  1		i2c_add_adapter	 		module_i2c_driver	i2c_register_board_info	 	__i2c_transfer
  2	 	i2c_add_numbered_adapter	i2c_del_driver	 	i2c_new_device	 		i2c_transfer
  3	 	i2c_del_adapter	  	 				i2c_new_dummy	 		i2c_master_send
  4	 	i2c_lock_adapter	  	 			i2c_verify_client	 	i2c_master_recv
  5	 	i2c_unlock_adapter	  	 			i2c_unregister_device	 	i2c_smbus_read_byte
  6	 	i2c_verify_adapter	  	 			i2c_use_client	 		i2c_smbus_write_byte
  7	    								i2c_release_client	 	i2c_smbus_read_byte_data
  8	  	  	  	 									i2c_smbus_write_byte_data
  9	  	  	  	 									i2c_smbus_read_word_data
  10	  	  	  	 									i2c_smbus_write_word_data
  11	  	  	  	 									i2c_smbus_read_block_data
  12	  	  	  	 									i2c_smbus_write_block_data
  13	  	  	  	 									i2c_smbus_xfer

  六、I2C Client的注册
    i2c_client即I2C设备的注册接口有三个：
       i2c_register_board_info(int busnum, struct i2c_board_info const *info, unsigned len)
       [busnum：通过总线号指定这个（些）设备属于哪个总线  \
		info： i2c设备的数组集合    \
		len：数组个数ARRAY_SIZE(info)]
       i2c_new_device(struct i2c_adapter *adap, struct i2c_board_info const *info)
	[adap：此设备所依附的I2C适配器指针   \
		info: 此设备的描述]
       i2c_new_dummy
    而i2c_new_dummy在内部其实也就是将client的name指定为dummy后依次执行的是i2c_new_device。

    集成的I2C设备注册过程应该在板级代码初始化期间，也就是arch_initcall前后的时间，或者就在这个时候，调用i2c_register_board_info注册。一定要在I2C适配器驱动注册前完成。真实的I2C设备是在适配器成功注册后才被生成。如果在I2C适配器注册完后还想要添加I2C设备的话，就要通过新的方式i2c_new_device。

    I2C设备驱动通常只是需要挂载在I2C总线（即依附于I2C子系统),I2C子系统对于设备驱动来说只是一个载体、基石。许多设备的主要核心是建立在其他子系统上，如策略感应器、三轴传感器、触摸屏等通常主要工作集中在INPUT子系统中，而相机模块、FM模块、GPS模块大多主要领队于V4L2子系统。这也能通过I2C设计理念证明，I2C的产生正是为了节省外围电路复杂度，让CPU使用有限的IO口挂载更多的外部模块。假如CPU的扩展IO口足够多，I2C也没什么必要存在了，毕竟直接操作IO口驱动设备比I2C来的简单。

七、I2C Adapter的注册
   I2C Adapter的注册通过两个方法：
    int i2c_add_adapter(struct i2c_adapter *adapter);
    int i2c_add_numbered_adapter(struct i2c_adapter *adap);
   两者的区别是，后者在注册时已经指定了I2C适配器的总线号，而前者的总线号将由系统自动分配。
   在i2c_add_numbered_adapter使用前必须制定adap->nr。如果给定-1，说明还是叫系统自动去生成总线号的。
   这两种方法的注册方式应用于不同的使用场景。
    a. i2c_add_adapter的使用经常是用来注册可插拔设备，如USP PCI设备等。主板上的其他模块与其没有直接联系，就是现有模块不在乎新加入的I2C适配器的总线号是多少，因为它们不不需要。反而这个可插拔设备上的一些模块会需要其注册成功的适配器指针。回看一开始就分析的i2c_client，会发现不同的场景的设备与其匹配的适配器有着这样的对应关系：
      (1. i2c_register_board_info需要指定已有的busnum，而i2c_add_numbered_adapter注册前已经指定总线号；
      (2. i2c_new_device需要指定adapter指针，而i2c_add_adapter注册成功后恰好这个指针就有了。
    b. i2c_add_numbered_adapter用来注册CPU自带的I2C适配器，或是集成在主板上的I2C适配器。主板上的其他I2C从设备（client）在注册时候需要这个总线号。

