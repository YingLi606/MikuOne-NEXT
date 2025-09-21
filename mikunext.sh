# # 脚本功能概述
# 该脚本主要用于系统管理和软件包的安装维护，支持 Linux 和 Android 系统。它包含了颜色定义、错误和信息提示、系统架构判断、软件包安装函数、目录有效性检查、Git 默认源设置、变量修改以及菜单选择等功能。

# # 主要函数说明
# - `variable`: 加载配置文件。
# - `self_install`: 根据传入的参数，使用对应的包管理器安装指定的软件包。
# - `hcjx`: 提示用户按回车键继续。
# - `validity_git`: 设置 Git 默认源。
# - `validity_dir`: 检查并创建必要的目录。
# - `validity`: 执行目录和 Git 源的有效性检查。
# - `Modify_the_variable`: 修改配置文件中的变量值。
# - `list_dir`: 显示目录列表供用户选择。
# - `apt_up`: 更新和升级 APT 包管理器的软件包。

# # 使用说明
# 脚本通过命令行参数执行不同的操作，支持 `-h` 或 `--help` 参数显示帮助信息。主要执行流程包括系统架构判断、软件包安装、目录和 Git 源检查，以及根据系统类型加载相应的菜单。
#字体颜色
########################################################
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
PINK='\e[1;35m'
RES='\e[0m'

ERROR="[${RED}错误${RES}]:"
WORRY="[${YELLOW}警告${RES}]:"
SUSSEC="[${GREEN}成功${RES}]:"
INFO="[${BLUE}信息${RES}]:"

declare -A arch_map=(["aarch64"]="arm64" ["armv7l"]="armhf" ["x86_64"]="amd64")
archurl="${arch_map[$(uname -m)]}"

variable() {
	source ${HOME}/MikuOne-NEXT/config/config.sh
}

log() {
	local fileName="${HOME}/MikuOne-NEXT/log.log"
	local fileMaxLen=100
	local fileDeleteLen=10
	if test $fileName; then
		echo "[$(date +%y/%m/%d-%H:%M:%S)]:$*" >>$fileName
		loglen=$(grep -c "" $fileName)
		if [ $loglen -gt $fileMaxLen ]; then
			sed -i '1,'$fileDeleteLen'd' $fileName
		fi
	else
		echo "[$(date +%y/%m/%d-%H:%M:%S)]:$*" >$fileName
	fi
}

self_install() {
    local pkg="$1"
    local cmd="$pkg"
    if [ "$pkg" = "aria2" ]; then
        cmd="aria2c"
    fi
	if ! command -v "$cmd" &>/dev/null; then
		echo -e "${RED}未安装 $pkg，正在安装...${RES}"
		${package_manager} install -y "$pkg"
		if ! command -v "$cmd" &>/dev/null; then
			echo -e "${ERROR} $pkg 安装完成，但未找到 $cmd 命令，请检查环境或重新安装${RES}"
			log "$pkg 安装后 $cmd 命令缺失"
			exit 1
		fi
	fi
	log "$pkg 已安装（命令 $cmd 可调用）"
}

hcjx() {
	echo -e "${GREEN}请按回车键继续...${RES}"
	read -r
}

validity_git() {
	source ${HOME}/MikuOne-NEXT/config/config.sh
	if [ "${git}" = "" ]; then
		wheregit=$(
			whiptail --title "选择默认安装源" --menu "以后的每次安装会优先考虑默认安装源" 15 60 4 \
				"1" "Github" \
				"2" "Github加速代理" \
				"0" "退出" 3>&1 1>&2 2>&3
		)
		case ${wheregit} in
		1)
			Modify_the_variable git "https:\/\/github.com\/" ${HOME}/MikuOne-NEXT/config/config.sh
			Modify_the_variable rawgit "https:\/\/raw.githubusercontent.com\/YingLi606\/MikuOne-NEXT\/refs\/heads\/main\/" ${HOME}/MikuOne-NEXT/config/config.sh
			return 0
			;;
		2)
			Modify_the_variable git "https:\/\/gh.xmly.dev\/https:\/\/github.com\/" ${HOME}/MikuOne-NEXT/config/config.sh
			Modify_the_variable rawgit "https:\/\/gh.xmly.dev\/https:\/\/raw.githubusercontent.com\/YingLi606\/MikuOne-NEXT\/refs\/heads\/main\/" ${HOME}/MikuOne-NEXT/config/config.sh
			return 0
			;;
		*)
			echo -e " 未选择默认修改为 ${YELLOW}Github${RES} "
			Modify_the_variable rawgit "https:\/\/raw.githubusercontent.com\/MIt-gancm\/Autumn-leaves\/refs\/heads\/main\/" ${HOME}/MikuOne-NEXT/config/config.sh
			return 0
			;;
		esac
	fi
}

validity_auto_upgrade() {
	source ${HOME}/MikuOne-NEXT/config/config.sh
	if [ "${auto_upgrade}" = "" ]; then
		wheregit=$(
			whiptail --title "选择默认安装源" --menu "是否自动更新软件包(默认关闭)" 15 60 4 \
				"1" "开启" \
				"2" "关闭" \
				"0" "退出" 3>&1 1>&2 2>&3
		)
		case ${wheregit} in
		1)
			Modify_the_variable auto_upgrade "true" ${HOME}/MikuOne-NEXT/config/config.sh
			log "自动升级脚本开启"
			return 0
			;;
		2)
			Modify_the_variable auto_upgrade "false" ${HOME}/MikuOne-NEXT/config/config.sh
			log "自动升级脚本关闭"
			return 0
			;;
		*)
			echo -e " 未选择默认修改为 ${YELLOW}false${RES} "
			Modify_the_variable auto_upgrade "false" ${HOME}/MikuOne-NEXT/config/config.sh
			log "自动升级脚本关闭"
			return 0
			;;
		esac
	fi
}

validity_dir() {
	mkdir -p ${HOME}/MikuOne-NEXT/{download,config}
	mkdir -p ${HOME}/.back
	mkdir -p ${HOME}/.TEMP
}

validity() {
	validity_dir
	validity_git
	validity_auto_upgrade
}

Modify_the_variable() {
	sed -i "s/^${1}=.*/${1}=${2}/" ${3}
}

list_dir() {
	current_index=1
	list=$(ls $1)
	list_items=($list)
	list_names=""
	for item in $list; do
		list_names+=" ${current_index} ${item}"
		let current_index++
	done
	user_choice=$(whiptail --title "选择" --menu "选择功能" 15 70 8 0 返回上级 ${list_names} 3>&1 1>&2 2>&3)
}

apt_up() {
	source ${HOME}/MikuOne-NEXT/config/config.sh
	current_timestamp=$(date +%s)
	if [[ -z "${last_time_aptup}" || $((current_timestamp - last_time_aptup)) -ge $((5 * 24 * 60 * 60)) ]]; then
		if [ "${auto_upgrade}" = "true" ]; then
			log "自动升级脚本开启"
			$package_manager update -y && $package_manager upgrade -y
			Modify_the_variable last_time_aptup ${current_timestamp} ${HOME}/MikuOne-NEXT/config/config.sh
		else
			log "自动升级脚本未开启"
		fi
	fi
}

debuger() {
	echo "${INFO}脚本定义的变量：$(cat ${HOME}/MikuOne-NEXT/config/config.sh)" 
	case $(uname -o) in
	Android)
		echo -e "${INFO}当前运行环境为Android${RES}"
		;;
	*)
		echo -e "${INFO}当前运行环境为Linux${RES}"
		if [ "${system_os_type}" = "" ] ; then
			echo -e "${INFO}完整linux环境或非本脚本安装的proot${RES}"
		fi
		;;
	esac
	echo -e "${INFO}近期日志:"
	IP=`ifconfig | grep inet | grep -vE 'inet6|127.0.0.1' | awk '{print $2}'`  
	echo "IP地址："$IP  
	cpu_num=`grep -c "model name" /proc/cpuinfo`  
	echo "cpu总核数："$cpu_num  
	cpu_user=`top -b -n 1 | grep Cpu | awk '{print $2}' | cut -f 1 -d "%"`  
	echo "用户空间占用CPU百分比："$cpu_user  
	cpu_system=`top -b -n 1 | grep Cpu | awk '{print $4}' | cut -f 1 -d "%"`  
	echo "内核空间占用CPU百分比："$cpu_system  
	cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $8}' | cut -f 1 -d "%"`  
	echo "空闲CPU百分比："$cpu_idle  
	cpu_iowait=`top -b -n 1 | grep Cpu | awk '{print $10}' | cut -f 1 -d "%"`  
	echo "等待输入输出占CPU百分比："$cpu_iowait  
	mem_total=`free | grep Mem | awk '{print $2}'`  
	echo "物理内存总量："$mem_total  
	mem_sys_used=`free | grep Mem | awk '{print $3}'`  
	echo "已使用内存总量(操作系统)："$mem_sys_used  
	mem_sys_free=`free | grep Mem | awk '{print $4}'`  
	echo "剩余内存总量(操作系统)："$mem_sys_free  
	mem_user_used=`free | sed -n 3p | awk '{print $3}'`  
	echo "已使用内存总量(应用程序)："$mem_user_used  
	mem_user_free=`free | sed -n 3p | awk '{print $4}'`  
	echo "剩余内存总量(应用程序)："$mem_user_free  
	mem_swap_total=`free | grep Swap | awk '{print $2}'`  
	echo "交换分区总大小："$mem_swap_total  
	mem_swap_used=`free | grep Swap | awk '{print $3}'`  
	echo "已使用交换分区大小："$mem_swap_used  
	mem_swap_free=`free | grep Swap | awk '{print $4}'`  
	echo "剩余交换分区大小："$mem_swap_free  
	tail -n 50 ${HOME}/MikuOne-NEXT/log.log 
}

get_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/issue ]; then
        local issue_content=$(cat /etc/issue | awk '{print $1; exit}')
        echo "$issue_content" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

detect_package_manager() {
    local distro=$(get_linux_distro)
    local pm=""
    case "$distro" in
        "ubuntu"|"debian"|"linuxmint"|"pop"|"kali")
            pm="apt"
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            pm="yum"
            ;;
        "fedora")
            pm="dnf"
            ;;
        "arch"|"manjaro"|"endeavouros")
            pm="pacman"
            ;;
        "opensuse"|"suse")
            pm="zypper"
            ;;
        *)
            if command -v apt >/dev/null 2>&1; then
                pm="apt"
            elif command -v dnf >/dev/null 2>&1; then
                pm="dnf"
            elif command -v yum >/dev/null 2>&1; then
                pm="yum"
            elif command -v pacman >/dev/null 2>&1; then
                pm="pacman"
            elif command -v zypper >/dev/null 2>&1; then
                pm="zypper"
			elif [ -d "/data/data/com.termux/files/usr" ]; then
				pm="pkg"
            else
                pm="unknown"
                return 1
            fi
            ;;
    esac
	log "检测到的包管理器: $pm"
    echo "$pm"
}

package_manager=$(detect_package_manager)

case ${1} in
-h | --help)
	echo -e "
-h | --help\t\t\t\t显示帮助信息
-s | --start [Android/Linux]\t启动脚本固定版本 [功能]
\t\tAndroid:
\t\t\tinstall proot\t\t安装proot工具
\t\t\tstart proot\t\t启动proot服务
\t\tLinux:
\t\t\tdownload_JAVA|dj\t下载JAVA环境（别名dj）
\t\t\tinstall_MC_SERVER|imcs\t安装MC_SERVER服务（别名imcs）
\t\t\tstart_MC_SERVER|smcs\t启动MC_SERVER服务（别名smcs）
\t\t\trm_MC_SERVER|rmcs\t移除MC_SERVER服务（别名rmcs）
\t\t\tinstallMCSManager | imcsm安装我的世界面板（别名imcsm）
\t\t\tstartMCSManager | startcsm\t启动我的世界面板（别名startcsm）
\t\t\tstopMCSManager | stopcsm\t停止我的世界面板（别名stopcsm）
\t\t\tinstallNapCatQQ | inQQ\t安装NapCatQQ（别名inQQ）
\t\t\tstartNapCatQQ | startnQQ\t启动NapCatQQ（别名startnQQ）
\t\t\tstartNapCatQQB | startnQQB\t后台启动NapCatQQ（后台）（别名startnQQB）
\t\t\tstopNapCatQQ | stopnQQ\t停止NapCatQQ（别名stopnQQ）
"
	hcjx
	;;
-s | --start)
	case $2 in
	Android | A)
		log "指定加载安卓功能"
		source ${HOME}/MikuOne-NEXT/local/Android/Android_menu $3 $4 $5
		;;
	Linux | L)
		log "指定加载Linux功能"
		source ${HOME}/MikuOne-NEXT/local/Linux/Linux_menu $3 $4 $5
		;;
	esac
	;;
*)
	apt_up
	log "初始化完成"
	case $(uname -o) in
	Android)
		log "加载安卓功能"
		self_install jq 
		self_install git 
		self_install wget 
		self_install whiptail  
		self_install tmux 
		self_install bc
		self_install aria2 
		validity
		variable
		bash ${HOME}/MikuOne-NEXT/function/update.sh
		log "检查更新"
		source ${HOME}/MikuOne-NEXT/local/Android/Android_menu $1 $2 $3
		sleep 2
		clear
		;;
	*)
		log "加载Linux功能"
		self_install jq
		self_install git
		self_install wget
		self_install whiptail
		self_install tmux
		self_install bc
		validity
		variable
		bash ${HOME}/MikuOne-NEXT/function/update.sh
		log "检查更新"
		source ${HOME}/MikuOne-NEXT/local/Linux/Linux_menu $1 $2 $3
		sleep 2
		clear
		;;
	esac
	;;
esac
