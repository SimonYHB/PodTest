#<center> Logan 
#### 一、简介：
移动端开发使用过程中，存在着纷繁复杂的各类日志，它们类型不一，上报时机不一，存储方式不一。有时为定位某一个问题，需要查询多渠道的日志。  
基于此，我们研发了一套在线日志回捞系统：**Logan**。  
我们可通过这一系统化工具，按需实时捞取客户端的各类日志，并以时间线重组，重现客户端发生的一切。  
Logan系统不是简单地上报各类日志，而是—— 
 
**针对一个特定用户，实时获取、重组 移动端所有的日志，系统化上报到后台，友好地还原APP上发生过的所有行为操作。**
<br/><br/>

####二、 Logan SDK 和 宿主APP 关系

在APP内部有各种各样的日志库，**Logan只对接各个日志库系统**。

<img src="./ABDImage.png">

 

#### 三、接入指南
1. 使用**cocopod** 或者 **拖入SDK**的方式接入Logan【建议使用pod依赖的方式接入。pod 依赖在对应的**.podspec 添加 s.dependency 'ABD', '1.0.0'**】

	以下是**pod**接入
	
		
		source 'http://gitlab.pab.com.cn/ARCH/share/CocoaPods/Specs.git'
 
		platform :ios,'8.0'
		 
		workspace 'InfoMonitor'
		 
		target 'InfoMonitorDemo' do
		   project 'InfoMonitorDemo/InfoMonitorDemo.xcodeproj'
		   pod 'FMDB', '2.5'
		   pod 'ABD','1.0.1'
		end
		target 'InfoMonitor' do
		    project 'InfoMonitor/InfoMonitor.xcodeproj'
		    pod 'ABD','1.0.1'
		end
		
	以下是**pod artifacotry**方式接入
		
		platform :ios, '8.0'
		source 'http://gitlab.pab.com.cn/ARCH/share/CocoaPods/Specs.git'
		
		workspace 'Genie'
		plugin 'cocoapods-art', :sources => [
		'framework-cocopods-release-local'
		]
		
		target 'Genie' do
		    project 'Genie.xcodeproj'
		    pod 'ABDFramework','1.0.1'
		end
		
2. 在日志写入的类中导入**"ABDManager.h"**
3. 初始化Logan SDK
	
		AppId: 需要到Logan后台进行申请，获取对应产品的唯一的AppId。【备注： 暂时使用口袋通用的APPId，例如："koudai"】
		deviceId: 设备的唯一标识符号，由产品生成对应的设备唯一标识符号，用来唯一定位某一个设备信息。
		
		[ABDManager setAppId:@"demo1212" deviceId:@"ios123456"];
		
4. 日志写入的方式:
	
		默认的写入方式:
		logStr 日志的内容信息
		type   日志的类型
		
		[ABDManager writeLog:logStr type:type];
		
		扩展的写入方式:
		logStr 日志的内容信息
		type   日志的类型
		extra  额外的信息
		tag	   为日志添加标签信息
		
		[ABDManager writeLog:logStr type:type extra:@"extra Infomation" tag:@"101010"]
		
5. 日志的上传机制

	**主动上传**
		
		source		信息的来源：用户主动上报的入口，默认为0
		extraInfo	额外的信息：例如图片截图的图片信息
		callBack 日志上传返回的状态码
		成功：返回 1000
		网络检测失败：返回-1001
		写库回调失败，返回:-1002
		
		[ABDManager uploadLogsSource:@"1" extraInfo:@[@"imgurl1",@"imgurl1"] callBack:^(NSInteger statusCode) {
        }];
        
     **push 指令上传**
		
		orderId			回捞id
		forceUpload		是否强制回捞
		dateStr			回捞的日期 "2019-9-12"

		[ABDManager uploadOrderId:@"pushOrderId" forceUpload:YES dateStr:@"2019-10-19"]
		
6. Logan 环境切换   

	* Logan 默认环境为prd
	* Logan 设置测试环境的方法【**1.0.1 切换环境⽅方式，后续⼜又进⾏行行优化**】

			[ABDManager setUploadUrl:@"https://bfiles-stg.pingan.com.cn/brop/stp/cust/mobile_monitor/abd/abd-log/report"];
		
7.	Logan后管平台

	* Debug环境: `http://logan.fat.qa.pab.com.cn/`
	* Release环境: `http://logan.pab.com.cn`

#### 四、Logan 逻辑描述
* 日志加密
	
	1. 加密方式采用AES。
	2. 秘钥：动态生成，一台设备一套秘钥。
* 日志的写入机制
	
	1. Logan的日志写入采用MMAP的方式进行高效的写入。日志会以日期 + Logan加密版本的格式写入本地，例如: 2019-10-1_1。
	2. 当天默认写入的日志信息为**10M**，超出则会被抛弃
	3. 日志在本地存储的时间，默认为**7天**，超出则会清除

* 日志的上传机制
	
	1. 在日志上传时候会在本地落地一条上传记录；
	2. 	如果上传成功，则会更新该条记录对应的LogId；
	3. 如果上传失败，则会继续重试两次，重试后还失败，则会放弃该次上传。清除本地的记录。
	4. 如果在上传中由于App被杀死，则在下次Logan启动后**10秒**的时候触发本地记录check，如果超过**7天**认为该记录过期，放弃上传；如果没有过期，则会继续上传。


* 网络诊断内容
	
		开始判断网络状....

		网络环境：4G 
		
		运营商：中国电信
		isoCountryCode：cn
		mobileCountryCode：460
		mobileNetworkCode：11
		
		开始 CDN 状态检测....
		
		http://cdn.sdb.com.cn/m/dns_detect.png200
		{"Content-Type":"image\/png","Access-Control-Allow-Origin":"*","X-Via":"1.1 PSfjfzdx2jw136:9 (Cdn Cache Server V2.0), 1.1 PSzjjxdx8kv246:3 (Cdn Cache Server V2.0)","Age":"756178","Server":"nginx","Cache-Control":"max-age=1296000","Date":"Thu, 31 Oct 2019 07:18:24 GMT","Access-Control-Allow-Credentials":"true","Content-Length":"82","Connection":"keep-alive","Etag":"\"5a72c119-52\"","Accept-Ranges":"bytes","Last-Modified":"Thu, 01 Feb 2018 07:26:17 GMT"}
		
		开始 DNS 解析....
		
		["180.101.49.12","180.101.49.11"]
		
		开始ping...
		ping: baidu www.baidu.com ...
		64 bytes from 180.101.49.12 icmp_seq=#0 type=ICMPv4TypeEchoReply time=50ms
		64 bytes from 180.101.49.12 icmp_seq=#1 type=ICMPv4TypeEchoReply time=30ms
		64 bytes from 180.101.49.12 icmp_seq=#2 type=ICMPv4TypeEchoReply time=42ms
		64 bytes from 180.101.49.12 icmp_seq=#3 type=ICMPv4TypeEchoReply time=30ms
		ping: taobao www.taobao.com ...
		64 bytes from 101.89.125.235 icmp_seq=#0 type=ICMPv4TypeEchoReply time=31ms
		64 bytes from 101.89.125.235 icmp_seq=#1 type=ICMPv4TypeEchoReply time=37ms
		64 bytes from 101.89.125.235 icmp_seq=#2 type=ICMPv4TypeEchoReply time=18ms
		64 bytes from 101.89.125.235 icmp_seq=#3 type=ICMPv4TypeEchoReply time=28ms



	