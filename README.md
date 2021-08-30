## brew start mysql with binlog

### Conf my.cnf

```shell
 gary@garydeMacBook-Pro  ~  sudo vi /usr/local/etc/my.cnf
Password:
 gary@garydeMacBook-Pro  ~  cat /usr/local/etc/my.cnf
# Default Homebrew MySQL server config
[mysqld]
# Only allow connections from localhost
bind-address = 127.0.0.1
log-bin = mysql-bin
binlog-format = ROW
server_id = 12
```

### brew restart mysql

```shell
 gary@garydeMacBook-Pro  ~  brew services restart mysql@5.6
Stopping `mysql@5.6`... (might take a while)
==> Successfully stopped `mysql@5.6` (label: homebrew.mxcl.mysql@5.6)
==> Successfully started `mysql@5.6` (label: homebrew.mxcl.mysql@5.6)
```

### conf mysql user

```mysql
mysql> CREATE USER 'canal'@'localhost' IDENTIFIED BY 'canal';
Query OK, 0 rows affected (0.00 sec)

mysql> GRANT ALL PRIVILEGES ON *.* TO 'canal'@'localhost' ;
Query OK, 0 rows affected (0.00 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE USER 'canal'@'127.0.0.1' IDENTIFIED BY 'canal';
Query OK, 0 rows affected (0.00 sec)

mysql> GRANT ALL PRIVILEGES ON *.* TO 'canal'@'127.0.0.1' ;
Query OK, 0 rows affected (0.00 sec)

mysql>  FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)
```

## quick start canal serverMode on tcp with local mysql

### 选择一个[发布版本](https://github.com/alibaba/canal/releases) 并解压到一个零时目录

> 我选择的是当前最新的[canal.deployer-1.1.5.tar.gz](https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.deployer-1.1.5.tar.gz)

```shell
 gary@garydeMacBook-Pro  ~  tar zxvf canal.deployer-1.1.5.tar.gz -C /tmp/canal
```

### 配置 canal.properties & base-instance.xml &  instance.properties

```shell
gary@garydeMacBook-Pro  /tmp/canal  cat /tmp/canal/conf/canal.properties
#################################################
######### 		common argument		#############
#################################################
# tcp bind ip
canal.ip =
# register ip to zookeeper
canal.register.ip =
canal.port = 11111
canal.metrics.pull.port = 11112
# canal instance user/passwd
# canal.user = canal
# canal.passwd = E3619321C1A937C46A0D8BD1DAC39F93B27D4458

# canal admin config
#canal.admin.manager = 127.0.0.1:8089
canal.admin.port = 11110
canal.admin.user = admin
canal.admin.passwd = 4ACFE3202A5FF5CF467898FC58AAB1D615029441
# admin auto register
#canal.admin.register.auto = true
#canal.admin.register.cluster =
#canal.admin.register.name =

canal.zkServers =
# flush data to zk
canal.zookeeper.flush.period = 1000
canal.withoutNetty = false
# tcp, kafka, rocketMQ, rabbitMQ
canal.serverMode = tcp
# flush meta cursor/parse position to file
canal.file.data.dir = ${canal.conf.dir}
canal.file.flush.period = 1000
## memory store RingBuffer size, should be Math.pow(2,n)
canal.instance.memory.buffer.size = 16384
## memory store RingBuffer used memory unit size , default 1kb
canal.instance.memory.buffer.memunit = 1024
## meory store gets mode used MEMSIZE or ITEMSIZE
canal.instance.memory.batch.mode = MEMSIZE
canal.instance.memory.rawEntry = true

## detecing config
canal.instance.detecting.enable = false
#canal.instance.detecting.sql = insert into retl.xdual values(1,now()) on duplicate key update x=now()
canal.instance.detecting.sql = select 1
canal.instance.detecting.interval.time = 3
canal.instance.detecting.retry.threshold = 3
canal.instance.detecting.heartbeatHaEnable = false

# support maximum transaction size, more than the size of the transaction will be cut into multiple transactions delivery
canal.instance.transaction.size =  1024
# mysql fallback connected to new master should fallback times
canal.instance.fallbackIntervalInSeconds = 60

# network config
canal.instance.network.receiveBufferSize = 16384
canal.instance.network.sendBufferSize = 16384
canal.instance.network.soTimeout = 30

# binlog filter config
canal.instance.filter.druid.ddl = true
canal.instance.filter.query.dcl = false
canal.instance.filter.query.dml = false
canal.instance.filter.query.ddl = false
canal.instance.filter.table.error = false
canal.instance.filter.rows = false
canal.instance.filter.transaction.entry = false
canal.instance.filter.dml.insert = false
canal.instance.filter.dml.update = false
canal.instance.filter.dml.delete = false

# binlog format/image check
canal.instance.binlog.format = ROW,STATEMENT,MIXED
canal.instance.binlog.image = FULL,MINIMAL,NOBLOB

# binlog ddl isolation
canal.instance.get.ddl.isolation = false

# parallel parser config
canal.instance.parser.parallel = true
## concurrent thread number, default 60% available processors, suggest not to exceed Runtime.getRuntime().availableProcessors()
#canal.instance.parser.parallelThreadSize = 16
## disruptor ringbuffer size, must be power of 2
canal.instance.parser.parallelBufferSize = 256

# table meta tsdb info
canal.instance.tsdb.enable = true
canal.instance.tsdb.dir = ${canal.file.data.dir:../conf}/${canal.instance.destination:}
canal.instance.tsdb.url = jdbc:h2:${canal.instance.tsdb.dir}/h2;CACHE_SIZE=1000;MODE=MYSQL;
canal.instance.tsdb.dbUsername = canal
canal.instance.tsdb.dbPassword = canal
# dump snapshot interval, default 24 hour
canal.instance.tsdb.snapshot.interval = 24
# purge snapshot expire , default 360 hour(15 days)
canal.instance.tsdb.snapshot.expire = 360

#################################################
######### 		destinations		#############
#################################################
canal.destinations = example
# conf root dir
canal.conf.dir = ../conf
# auto scan instance dir add/remove and start/stop instance
canal.auto.scan = true
canal.auto.scan.interval = 5
# set this value to 'true' means that when binlog pos not found, skip to latest.
# WARN: pls keep 'false' in production env, or if you know what you want.
canal.auto.reset.latest.pos.mode = false

canal.instance.tsdb.spring.xml = classpath:spring/tsdb/h2-tsdb.xml
#canal.instance.tsdb.spring.xml = classpath:spring/tsdb/mysql-tsdb.xml

canal.instance.global.mode = spring
canal.instance.global.lazy = false
canal.instance.global.manager.address = ${canal.admin.manager}
#canal.instance.global.spring.xml = classpath:spring/memory-instance.xml
canal.instance.global.spring.xml = classpath:spring/file-instance.xml
#canal.instance.global.spring.xml = classpath:spring/default-instance.xml

##################################################
######### 	      MQ Properties      #############
##################################################
# aliyun ak/sk , support rds/mq
canal.aliyun.accessKey =
canal.aliyun.secretKey =
canal.aliyun.uid=

canal.mq.flatMessage = true
canal.mq.canalBatchSize = 50
canal.mq.canalGetTimeout = 100
# Set this value to "cloud", if you want open message trace feature in aliyun.
canal.mq.accessChannel = local

canal.mq.database.hash = true
canal.mq.send.thread.size = 30
canal.mq.build.thread.size = 8

##################################################
######### 		     Kafka 		     #############
##################################################
kafka.bootstrap.servers = 127.0.0.1:9092
kafka.acks = all
kafka.compression.type = none
kafka.batch.size = 16384
kafka.linger.ms = 1
kafka.max.request.size = 1048576
kafka.buffer.memory = 33554432
kafka.max.in.flight.requests.per.connection = 1
kafka.retries = 0

kafka.kerberos.enable = false
kafka.kerberos.krb5.file = "../conf/kerberos/krb5.conf"
kafka.kerberos.jaas.file = "../conf/kerberos/jaas.conf"

##################################################
######### 		    RocketMQ	     #############
##################################################
rocketmq.producer.group = test
rocketmq.enable.message.trace = false
rocketmq.customized.trace.topic =
rocketmq.namespace =
rocketmq.namesrv.addr = 127.0.0.1:9876
rocketmq.retry.times.when.send.failed = 0
rocketmq.vip.channel.enabled = false
rocketmq.tag =

##################################################
######### 		    RabbitMQ	     #############
##################################################
rabbitmq.host =
rabbitmq.virtual.host =
rabbitmq.exchange =
rabbitmq.username =
rabbitmq.password =
rabbitmq.deliveryMode =%
gary@garydeMacBook-Pro  /tmp/canal  cat /tmp/canal/conf/spring/base-instance.xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tx="http://www.springframework.org/schema/tx"
	xmlns:aop="http://www.springframework.org/schema/aop" xmlns:lang="http://www.springframework.org/schema/lang"
	xmlns:context="http://www.springframework.org/schema/context"
	xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-2.0.xsd
           http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop-2.0.xsd
           http://www.springframework.org/schema/lang http://www.springframework.org/schema/lang/spring-lang-2.0.xsd
           http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx-2.0.xsd
           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-2.5.xsd"
	default-autowire="byName">

	<!-- properties -->
	<bean class="com.alibaba.otter.canal.instance.spring.support.PropertyPlaceholderConfigurer" lazy-init="false">
		<property name="ignoreResourceNotFound" value="true" />
		<property name="systemPropertiesModeName" value="SYSTEM_PROPERTIES_MODE_OVERRIDE"/><!-- 允许system覆盖 -->
		<property name="locationNames">
			<list>
				<value>classpath:canal.properties</value>
				<value>classpath:${canal.instance.destination:}/instance.properties</value>
			</list>
		</property>
	</bean>

	<bean id="socketAddressEditor" class="com.alibaba.otter.canal.instance.spring.support.SocketAddressEditor" />
	<bean class="org.springframework.beans.factory.config.CustomEditorConfigurer">
		<property name="propertyEditorRegistrars">
			<list>
				<ref bean="socketAddressEditor" />
			</list>
		</property>
	</bean>

	<bean id="baseEventParser" class="com.alibaba.otter.canal.parse.inbound.mysql.MysqlEventParser">
		<property name="destination" value="${canal.instance.destination}" />
		<property name="slaveId" value="${canal.instance.mysql.slaveId:1234}" />
		<!-- 心跳配置 -->
		<property name="detectingEnable" value="${canal.instance.detecting.enable:false}" />
		<property name="detectingSQL" value="${canal.instance.detecting.sql}" />
		<property name="detectingIntervalInSeconds" value="${canal.instance.detecting.interval.time:5}" />
		<property name="haController">
			<bean class="com.alibaba.otter.canal.parse.ha.HeartBeatHAController">
				<property name="detectingRetryTimes" value="${canal.instance.detecting.retry.threshold:3}" />
				<property name="switchEnable" value="${canal.instance.detecting.heartbeatHaEnable:false}" />
			</bean>
		</property>

		<property name="alarmHandler" ref="alarmHandler" />

		<!-- 解析过滤处理 -->
		<property name="eventFilter">
			<bean class="com.alibaba.otter.canal.filter.aviater.AviaterRegexFilter" >
				<constructor-arg index="0" value="${canal.instance.filter.regex:.*\..*}" />
			</bean>
		</property>

		<!-- 最大事务解析大小，超过该大小后事务将被切分为多个事务投递 -->
		<property name="transactionSize" value="${canal.instance.transaction.size:1024}" />

		<!-- 网络链接参数 -->
		<property name="receiveBufferSize" value="${canal.instance.network.receiveBufferSize:16384}" />
		<property name="sendBufferSize" value="${canal.instance.network.sendBufferSize:16384}" />
		<property name="defaultConnectionTimeoutInSeconds" value="${canal.instance.network.soTimeout:30}" />

		<!-- 解析编码 -->
		<!-- property name="connectionCharsetNumber" value="${canal.instance.connectionCharsetNumber:33}" /-->
		<property name="connectionCharset" value="${canal.instance.connectionCharset:UTF-8}" />

		<!-- 解析位点记录 -->
		<property name="logPositionManager">
			<bean class="com.alibaba.otter.canal.parse.index.MemoryLogPositionManager" />
		</property>

		<!-- failover切换时回退的时间 -->
		<property name="fallbackIntervalInSeconds" value="${canal.instance.fallbackIntervalInSeconds:60}" />

		<!-- 解析数据库信息 -->
		<property name="masterInfo">
			<bean class="com.alibaba.otter.canal.parse.support.AuthenticationInfo">
				<property name="address" value="${canal.instance.master.address}" />
				<property name="username" value="${canal.instance.dbUsername:canal}" />
				<property name="password" value="${canal.instance.dbPassword:canal}" />
				<property name="defaultDatabaseName" value="${canal.instance.defaultDatabaseName:test}" />
			</bean>
		</property>
		<property name="standbyInfo">
			<bean class="com.alibaba.otter.canal.parse.support.AuthenticationInfo">
				<property name="address" value="${canal.instance.standby.address}" />
				<property name="username" value="${canal.instance.dbUsername:canal}" />
				<property name="password" value="${canal.instance.dbPassword:canal}" />
				<property name="defaultDatabaseName" value="${canal.instance.defaultDatabaseName:test}" />
			</bean>
		</property>

		<!-- 解析起始位点 -->
		<property name="masterPosition">
			<bean class="com.alibaba.otter.canal.protocol.position.EntryPosition">
				<property name="journalName" value="${canal.instance.master.journal.name}" />
				<property name="position" value="${canal.instance.master.position}" />
				<property name="timestamp" value="${canal.instance.master.timestamp}" />
			</bean>
		</property>
		<property name="standbyPosition">
			<bean class="com.alibaba.otter.canal.protocol.position.EntryPosition">
				<property name="journalName" value="${canal.instance.standby.journal.name}" />
				<property name="position" value="${canal.instance.standby.position}" />
				<property name="timestamp" value="${canal.instance.standby.timestamp}" />
			</bean>
		</property>
		<property name="filterQueryDml" value="${canal.instance.filter.query.dml:false}" />
		<property name="filterQueryDcl" value="${canal.instance.filter.query.dcl:false}" />
	</bean>

	<!--bean id="baseEventParser" class="com.alibaba.otter.canal.parse.inbound.mysql.rds.RdsBinlogEventParserProxy" abstract="true">
		<property name="accesskey" value="${canal.aliyun.accesskey:}" />
		<property name="secretkey" value="${canal.aliyun.secretkey:}" />
		<property name="instanceId" value="${canal.instance.rds.instanceId:}" />
	</bean -->
</beans>%
 gary@garydeMacBook-Pro  /tmp/canal  cat /tmp/canal/conf/example/instance.properties
#################################################
## mysql serverId , v1.0.26+ will autoGen
# canal.instance.mysql.slaveId=0

# enable gtid use true/false
canal.instance.gtidon=false

# position info
canal.instance.master.address=127.0.0.1:3306
canal.instance.master.journal.name=
canal.instance.master.position=
canal.instance.master.timestamp=
canal.instance.master.gtid=

# rds oss binlog
canal.instance.rds.accesskey=
canal.instance.rds.secretkey=
canal.instance.rds.instanceId=

# table meta tsdb info
canal.instance.tsdb.enable=true
#canal.instance.tsdb.url=jdbc:mysql://127.0.0.1:3306/canal_tsdb
#canal.instance.tsdb.dbUsername=canal
#canal.instance.tsdb.dbPassword=canal

#canal.instance.standby.address =
#canal.instance.standby.journal.name =
#canal.instance.standby.position =
#canal.instance.standby.timestamp =
#canal.instance.standby.gtid=

# username/password
canal.instance.dbUsername=canal
canal.instance.dbPassword=canal
canal.instance.connectionCharset = UTF-8
canal.instance.defaultDatabaseName=test
# enable druid Decrypt database password
canal.instance.enableDruid=false
#canal.instance.pwdPublicKey=MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALK4BUxdDltRRE5/zXpVEVPUgunvscYFtEip3pmLlhrWpacX7y7GCMo2/JM6LeHmiiNdH1FWgGCpUfircSwlWKUCAwEAAQ==

# table regex
canal.instance.filter.regex=.*\\..*
# table black regex
canal.instance.filter.black.regex=mysql\\.slave_.*
# table field filter(format: schema1.tableName1:field1/field2,schema2.tableName2:field1/field2)
#canal.instance.filter.field=test1.t_product:id/subject/keywords,test2.t_company:id/name/contact/ch
# table field black filter(format: schema1.tableName1:field1/field2,schema2.tableName2:field1/field2)
#canal.instance.filter.black.field=test1.t_product:subject/product_image,test2.t_company:id/name/contact/ch

# mq config
canal.mq.topic=example
# dynamic topic route by schema or table regex
#canal.mq.dynamicTopic=mytest1.user,mytest2\\..*,.*\\..*
canal.mq.partition=0
# hash partition config
#canal.mq.partitionsNum=3
#canal.mq.partitionHash=test.table:id^name,.*\\..*
#canal.mq.dynamicTopicPartitionNum=test.*:4,mycanal:6
#################################################
```

### start canal server

```shell
 gary@garydeMacBook-Pro  /tmp/canal  sh bin/startup.sh
```

## run test app

> Test com.alibaba.otter.SimpleCanalClientExample
> 
> changelog
>
>================&gt; binlog[mysql-bin.000001:530] , name[test,xdual] , eventType : INSERT
 id : 1    update=true
 x : 2021-08-30 22:19:29    update=true
