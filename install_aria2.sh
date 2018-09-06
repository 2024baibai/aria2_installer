#!/bin/bash
#获取服务器IP
osip=$(curl -4s https://api.ip.sb/ip)

#安装函数
function centos(){
	yum -y install curl
	yum -y install epel-release
	yum -y install aria2
}
#CentOS 6安装
function centos6(){
	wget http://soft.xiaoz.org/linux/nettle-2.2-1.el6.rf.x86_64.rpm
	wget http://soft.xiaoz.org/linux/nettle-devel-2.2-1.el6.rf.x86_64.rpm
	wget http://soft.xiaoz.org/linux/gnutls-2.12.23-21.el6.x86_64.rpm
	wget http://soft.xiaoz.org/linux/aria2-1.16.4-1.el6.rf.x86_64.rpm
	rpm -ivh nettle-2.2-1.el6.rf.x86_64.rpm
	rpm -ivh nettle-devel-2.2-1.el6.rf.x86_64.rpm
	rpm -ivh gnutls-2.12.23-21.el6.x86_64.rpm
	rpm -ivh aria2-1.16.4-1.el6.rf.x86_64.rpm
	rm -rf *.rpm
}

#debian or ubuntu安装
function debian(){
	apt-get -y install curl
	apt-get -y install aria2
}

#Aria2低版本设置
function setting(){
	mkdir -p /data/aria2
	mkdir -p /data/aria2/download
	touch /data/aria2/aria2.session
	cp aria2.conf caddy.conf aria2.sh auto_tracker.sh /data/aria2
	
	echo "-------------------------------"
	read -p "设置用户名：" user
	read -p "设置密码：" pass
	echo "-------------------------------"
	sed -i "s/rpc-secret=/#rpc-secret=/g" /data/aria2/aria2.conf
	sed -i "s/#rpc-user=/rpc-user=${user}/g" /data/aria2/aria2.conf
	sed -i "s/#rpc-passwd=/rpc-passwd=${pass}/g" /data/aria2/aria2.conf
	#下载yaaw
	wget -P /data/aria2 https://github.com/helloxz/yaaw/archive/master.zip
	cd /data/aria2
	unzip master.zip
	mv yaaw-master/* ./
	
	#下载caddy server
	wget http://soft.xiaoz.org/linux/caddy.filemanager -O caddy && mv caddy /usr/bin/
	chmod +x /usr/bin/caddy
	#修改配置
	#sed -i "s/localhost/$1/g" /data/aria2/caddy.conf
	sed -i "s/username/${user}/g" /data/aria2/caddy.conf
	sed -i "s/password/${pass}/g" /data/aria2/caddy.conf
	#放行端口
	chk_firewall
	#启动服务
	cd /data/aria2
	nohup aria2c --conf-path=/data/aria2/aria2.conf > /data/aria2/aria2.log 2>&1 &
	nohup caddy -conf="/data/aria2/caddy.conf" > /data/aria2/caddy.log 2>&1 &
	echo "-------------------------------"
	echo "#####		安装完成，请牢记以下信息。	#####"
	echo "访问地址：http://${osip}:6080"
	echo "用户名：${user}"
	echo "密码：${pass}"
	echo "RPC地址：http://${user}:${pass}@$1:6800/jsonrpc"

    #添加定时任务，自动更新tracker
    echo "0 0 * * * sh /data/aria2/auto_tracker.sh" >> /var/spool/cron/root
	
	#一点点清理工作
	rm -rf /data/aria2/*.zip
	rm -rf /data/aria2/*.tar.gz
	rm -rf /data/aria2/*.txt
	rm -rf /data/aria2/*.md
	rm -rf /data/aria2/yaaw-*
}

#自动放行端口
function chk_firewall() {
	if [ -e "/etc/sysconfig/iptables" ]
	then
		iptables -I INPUT -p tcp --dport 6080 -j ACCEPT
		iptables -I INPUT -p tcp --dport 6800 -j ACCEPT
		iptables -I INPUT -p tcp --dport 51413 -j ACCEPT
		service iptables save
		service iptables restart
	else
		firewall-cmd --zone=public --add-port=6080/tcp --permanent
		firewall-cmd --zone=public --add-port=6800/tcp --permanent
		firewall-cmd --zone=public --add-port=51413/tcp --permanent
		firewall-cmd --reload
	fi
}

echo '#####		欢迎使用一键安装Aria2脚本^_^	#####'
echo '----------------------------------'
echo '请选择系统:'
echo "1) CentOS 7 X64"
echo "2) CentOS 6 X64"
echo "3) Debian 8+ X64 or Ubuntu 14+ X64"
echo "q) 退出"
echo '----------------------------------'
read -p ":" num
echo '----------------------------------'

case $num in
	1)
		#安装
		centos
		#设置
		setting $osip
		exit
	;;
	2)
		#安装aria2
		centos6
		setting $osip
		exit
	;;
	3)
		debian
		setting $osip
		echo "温馨提示：Debian/Ubuntu用户若无法访问，需要放行 6080/6800/51413 端口或关闭防火墙！"
		echo '----------------------------------'
		exit
	;;
	q)
		exit
	;;
	*)
		echo '错误的参数'
		exit
	;;
esac