#!/bin/bash
# **************************************
# * Filename     : firewall manage.sh
# * Description  : #firewalld防*墙管理脚本

# ********************************************
function firewalld_menu(){
echo -e "\033[34m
*********************************** \
\n*\t1.查看防火墙状态\t\t\t\t2.开关防火墙 \t\t\t* \
\n\n*\t3.使新添加的策略立即生效   \t\t\t4.查看安全域策略 \t\t* \
\n\n* t5.重启防*墙     \t\t\t\t6.批量放行端口 \t\t\t*  \  
\n\n*\t7.批量放行服务   \t\t\t\t8.删除安全域策略 \t\t\t*  \
\n\n*\t9.批量拒绝指定端口连接   \t\t\t10.批量放行IP \t\t\t* \
\n\n*\t11.批量阻止IP访问    \t\t\t\t12.查看修改默认安全域 \t\t* \
\n\n*\t13.                 \t\t\t\t0.退出 \t\t\t\t*
*****************************************************************\033[0m"


read -p "请输入要操作的选项:" num
case $num in
	1)
	firewall_state=$(firewall-cmd --state)
	if [ "${firewall_state}" == "running" ];then
	   echo -e "\033[32mFirewall enable\033[0m"
	else
	   echo -e "\033[31mFirewall disable\033[0m"
	fi
	;;


	2)
	read -p "1.启动firewalld|2.关闭firewalld|0.退出:" run_firewall
	if [ "$run_firewall" == 1 ];then
	   systemctl start firewalld && systemctl enable firewalld &>/dev/null
	   if [ "$?" -eq 0 ];then
		  echo -e "\033[32mfirewall started successfully\033[0m"
	   else
		  echo -e "\033[31mfirewall start failed\033[0m"
	   fi
	elif [ "$run firewall" == 2 ];then
	   systemctl stop firewalld && systemctl disable firewalld &>/dev/null
	   if [ "$?" -eq 0 ];then
		  echo -e "\033[31mfirewall disabled successfully\033[0m"
	   fi
	elif [ "$run_firewall" == 0 ];then
		 continue
	else
		echo -e "\033[31m你输入的参数有误!(请输入0|1|2的数字)\033[0m"
	fi
	;;

	3)
	firewall-cmd --reload
	if [ "$?" -eq 0 ];then
		echo -e "\033[34mfirewall reloaded\033[0m"
	fi
	;;


	4)
	# zone_list=$(firewall-cmd --get-zones)
	read -p "1.查看所有安全域中的策略|2.查看常用安全域策略" zone_tactics
	if [ "$zone_tactics" == 1 ];then
		 firewall-cmd --list-all-zones
	elif [ "$zone_tactics" == 2 ];then
		 security_list=(public trusted block drop)
		 for frequently_zone in ${security_list[@]}
		 do
		 firewall-cmd --list-all --zone=${frequently_zone}
		 done
	else
		echo -e "\033[31m你输入的参数有误!(请输入1|2)\033[0m"
	fi
	;;

	5)
	systemctl restart firewalld
	if [ "$?" -eq 0 ];then
		 echo -e "\033[32mfirewall restarted successfully\033[0m"
	else	 
		 echo -e "\033[31mfirewall restart failed\033[0m"

	fi
	;;

	6)
	read -p "请输入端口(以空格隔开:22/tcp 443/tcp 8080/tcp):" port
	port_list=($port)
	for i in ${port_list[@]}
	do
	  firewall-cmd --permanent  --add=port=$i --zone=trusted
	done
	if [ $? -eq 0 ];then
		echo -e "\033[32m ${port_list[@]},port pass\033[0m"
		firewall-cmd --reload
		if [ "$?" -eq 0 ];then
			  echo -e "\033[32mfirewall Policy Pass\033[0m"
		fi
	else
		echo -e "\033[31输入格式错误,请输入正确的格式[以空格隔开:22/tcp 443/tcp 8080/tcp]\033[0m"
	fi
	;;


	7)
	read -p "请输入服务名(如需过滤多个服务请以空格隔开:http ssh https):" services
	services_list=($services)
	for service in ${services_list[@]}
	do
	  firewall-cmd --permanent --add-service=$service  --zone=trusted
	done  
	if [ $? -eq 0 ];then
	  echo -e "\033[32m ${services_list[@]},services pass\033[0m"
	  firewall-cmd --reload
	  if [ "$?" -eq 0 ];then
		 echo -e "\033[32mfirewall Policy Pass\033[0m"
	  fi
	else
		echo -e "\033[31格式有误,请输入正确的格式(以空格隔开:http ssh http)\033[0m"
		exit 1
	fi  
	;;

	8)
	zone_file=/etc/firewalld/zones/*
	read -p "1.清空所有策略|2.清空指定安全域策略"  cler_zone
	if [ "$cler_zone" == "1" ];then
	   for files in ${zone_file}
		do
		   #提取文件名
		   #filename=${files##*/}
		   echo -e "\033[31m delete $files successfuly\033[0m"
		   rm -rf $files
		done
		if [ $? -eq 0 ];then
		    echo -e "\033[34mAll policies cleared \033[0m"
			firewall-cmd --reload
			fi
	elif [ "$cler_zone" == "2" ];then
	    read -p  "请输入要清空的安全域:" cr_zone
		 delete=($cler_zone)
		 for delete_zone in ${delete[@]}
		 do
		     zone_file=/etc/firewalld/zones/${delete zone}.*
			 rm -rf ${zone file}
			 done
			 if [ "$?" -eq 0 ];then
			     firewall-cmd --reload &>/dev/null 2>&1
				 echo -e "\033[33m已删除${delete[@]}区域的所有策略\033[0m"
		     fi
	else		 
			 echo -e "\033[31m格式有误,请输入正确的格式(1|2)"
	
	fi
	;;


	9)
	read -p "请输入端口(如有多个端口请,以空格隔开:22/tcp 443/tcp 8080/tcp)"  down
	down_list=($down)
	for i in ${down_list[@]}
	do
	   firewall-cmd --permanent --zone=drop --add-port=$i
	done   
	   if [ $? -eq 0 ];then
	   echo -e "\033[32m ${down_list[@]},port down\033[0m"
	   firewall-cmd --reload
	   if [ "$?" -eq 0 ];then
		  echo -e "\033[31m策略已生效!\033[0m"
		  fi
	else	  
		  echo -e "\033[31m输入格式有误,请输入正确的格式[22/tcp 443/tcp 8080/tcp]\033[0m"
		  exit 1
	fi
	;;


	10)
	read -p "请输入IP(如要过滤多个IP请用空格隔开:172.168.1.1/32 192.168.1.1/32|192,168.1.0/24 172.168.2.0/24):"
	 pass_ip
	passip_list=($pass_ip)
	for ip_ps in ${passip_list[@]}
	do
	   firewall-cmd --permanent --add-source=${ip_ps} --zone=trusted
	done
	if [ $? -eq 0 ];then
		echo -e "\033[32m ${passip_list[@]},source-ip pass\033[0m"
		firewall-cmd --reload
		if [ "$?" -eq 0 ];then
		   echo -e "\033[32mfirewall Policy Pass\033[0m"
		fi

	else
		echo -e "\033[31m输入格式有误,请输入正确的格式[172.168.1.1/32 192.168.1.1/32|192,168.1.0/24 172.168.2.0/24]\033[0m"
		exit 1
	fi
	;;


	11)
	read -p "请输入IP(如有多个IP请用空格隔开:172.168.1.1/32 192.168.1.1/32|192.168.1.0/24 172.168.2.0/24):"
	  down_ip
	 downip_list=($down_ip)
	 for ip_dn in ${downip_list[@]}
	 do
		 firewall-cmd --permanent --add-source=${ip_dn} --zone=drop
	done
	 if [ $? -eq 0 ];then
		echo -e "\033[32m ${downip_list[@]},down-ip pass\033[0m"
		firewall-cmd --reload
		if [ "$?" -eq 0 ];then
			echo -e "\033[31mfirewall Policy Drop\033[0m"
		fi
		
	else
		echo -e " \033[31m输入格式有误,请输入正确的格式[172,168,1,1/32 192,168,1,1/32|192.168,1.0/24 172.168.2.0/24]\033[0m"
		exit 1
	fi
	;;

	12)
	default_zone=$(firewall-cmd --get-default-zone)
	read -p "1.查看默认安全域/2.修改默认安全域(trusted/drop/block/public):" remove_default_zone
	if [ "${remove_default_zone}" -eq "1" ];then
		echo -e "\033[32m当前默认安全域为:${default_zone}\033[0m"
	elif [ "${remove_default_zone}" -eq "2" ];then
		read -p "请输入新的默认安全域:" new_default_zone
		firewall-cmd --set-default-zone=${new_default_zone}
		if [ $? -eq 0 ];then
		   echo -e "\033[32m修改成功,当前默认安全域为:${new_default_zone}\033[0m"
		else
		   echo -e "\033[31m修改失败,输入的安全域不存在 033[0m"
		fi
	else
		   echo -e "\033[31m输入格式有误,请输入[1|2]\033[0m"


	fi
	;;

	0)
	exit 0
	;;

	*)
	echo "请输入正确的选项[0~10]"
	exit 1
	;;
esac
}
while true
do
 firewalld_menu
done
