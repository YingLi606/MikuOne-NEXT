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
	if test -f "$fileName"; then
		echo "[$(date +%y/%m/%d-%H:%M:%S)]:$*" >>"$fileName"
		loglen=$(grep -c "" "$fileName")
		if [ "$loglen" -gt "$fileMaxLen" ]; then
			sed -i "1,${fileDeleteLen}d" "$fileName"
		fi
	else
		echo "[$(date +%y/%m/%d-%H:%M:%S)]:$*" >"$fileName"
	fi
}

self_install() {
	if ! command -v "$1" &>/dev/null; then
		echo -e "${RED}未安装 $1，正在安装...${RES}"
		"${package_manager}" install -y "$1"
	fi
}

hcjx() {
	echo -e "${GREEN}请按回车键继续...${RES}"
	read -r
}

validity_git() {
	source ${HOME}/MikuOne-NEXT/config/config.sh
	if [ "${git}" = "" ]; then
		wheregit=$(
			whiptail --title "请选择默认安装源" --menu "以后的每次安装会优先考虑默认安装源" 15 60 4 \
				"1" "Github" \
				"3" "Github加速代理" \
				"0" "退出" 3>&1 1>&2 2>&3
		)
		case "${wheregit}" in
		1)
			Modify_the_variable git "https:\/\/github.com\/YingLi606\/MikuOne-NEXT.git" "${HOME}/MikuOne-NEXT/config/config.sh"
			Modify_the_variable rawgit "https:\/\/raw.githubusercontent.com\/YingLi606\/MikuOne-NEXT\/refs\/heads\/main\/" "${HOME}/MikuOne-NEXT/config/config.sh"
			return 0
			;;
		3)
			Modify_the_variable git "https:\/\/dl.gancmcs.top\/https:\/\/github.com\/YingLi606\/MikuOne-NEXT.git" "${HOME}/MikuOne-NEXT/config/config.sh"
			Modify_the_variable rawgit "https:\/\/dl.gancmcs.top\/https:\/\/raw.githubusercontent.com\/YingLi606\/MikuOne-NEXT\/refs\/heads\/main\/" "${HOME}/MikuOne-NEXT/config/config.sh"
			return 0
			;;
		*)
			echo -e " 未选择默认修改为 ${YELLOW}Github${RES} "
			Modify_the_variable git "https:\/\/github.com\/YingLi606\/MikuOne-NEXT.git" "${HOME}/MikuOne-NEXT/config/config.sh"
			Modify_the_variable rawgit "https:\/\/raw.githubusercontent.com\/YingLi606\/MikuOne-NEXT\/refs\/heads\/main\/" "${HOME}/MikuOne-NEXT/config/config.sh"
			return 0
			;;
		esac
	fi
}

validity_auto_upgrade() {
	source ${HOME}/MikuOne-NEXT/config/config.sh
	if [ "${auto_upgrade}" = "" ]; then
		wheregit=$(
			whiptail --title "选择默认安装源" --menu "是否自动更新软件包(建议开启)" 15 60 4 \
				"1" "开启" \
				"2" "关闭" \
				"0" "退出" 3>&1 1>&2 2>&3
		)
		case "${wheregit}" in
		1)
			Modify_the_variable auto_upgrade "true" "${HOME}/MikuOne-NEXT/config/config.sh"
			log "自动升级脚本开启"
			return 0
			;;
		2)
			Modify_the_variable auto_upgrade "false" "${HOME}/MikuOne-NEXT/config/config.sh"
			log "自动升级脚本关闭"
			return 0
			;;
		*)
			echo -e " 未选择默认修改为 ${YELLOW}false${RES} "
			Modify_the_variable auto_upgrade "false" "${HOME}/MikuOne-NEXT/config/config.sh"
			log "自动升级脚本关闭"
			return 0
			;;
		esac
	fi
}

validity_dir() {
	mkdir -p "${HOME}/MikuOne-NEXT/{download,config}"
	mkdir -p "${HOME}/.back"
	mkdir -p "${HOME}/.TEMP"
}

validity() {
	validity_dir
	validity_git
	validity_auto_upgrade
}

Modify_the_variable() {
	sed -i "s/^${1}=.*/${1}=${2}/" "${3}"
}

list_dir() {
	current_index=1
	list=$(ls "$1")
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
			"${package_manager}" update -y && "${package_manager}" upgrade -y
			Modify_the_variable last_time_aptup "${current_timestamp}" "${HOME}/MikuOne-NEXT/config/config.sh"
		else
			log "自动升级脚本未开启"
		fi
	fi
}

debuger() {
    echo -e "\n${INFO}==================== 脚本调试信息 ====================\033[0m"
    sleep 0.8
    
    echo -e "\n${INFO}正在读取脚本配置文件..."
    sleep 0.6
    if [ -f "${HOME}/MikuOne-NEXT/config/config.sh" ]; then
        echo -e "${SUSSEC}脚本定义的变量："
        cat "${HOME}/MikuOne-NEXT/config/config.sh"
    else
        echo -e "${WORRY} 配置文件 ${HOME}/MikuOne-NEXT/config/config.sh 不存在！"
    fi
    sleep 1
    
    echo -e "\n${INFO}正在检测运行环境..."
    sleep 0.5
    echo -e "${SUSSEC}当前运行环境：Android Termux"
    sleep 0.6
    
    echo -e "\n${INFO}环境备注：Termux专属轻量Linux环境，无需额外检测发行版"
    sleep 0.7
    
    echo -e "\n${INFO}正在获取网络信息..."
    sleep 0.6
    IP=$(ifconfig | grep inet | grep -vE 'inet6|127.0.0.1|100.100.' | awk '{print $2}' | head -n1)
    if [ -n "$IP" ]; then
        echo -e "${SUSSEC}设备IP地址：$IP"
    else
        echo -e "${WORRY} 未检测到有效IP（可能处于离线或仅本地网络）"
    fi
    sleep 0.8
    
    echo -e "\n${INFO}正在读取CPU信息..."
    sleep 0.6
    cpu_num=$(grep -c "model name" /proc/cpuinfo)
    cpu_user=$(top -b -n 1 | grep Cpu | awk '{print $2}' | cut -f 1 -d "%")
    cpu_system=$(top -b -n 1 | grep Cpu | awk '{print $4}' | cut -f 1 -d "%")
    cpu_idle=$(top -b -n 1 | grep Cpu | awk '{print $8}' | cut -f 1 -d "%")
    cpu_iowait=$(top -b -n 1 | grep Cpu | awk '{print $10}' | cut -f 1 -d "%")
    
    echo -e "${SUSSEC}CPU总核数：$cpu_num"
    echo -e "${SUSSEC}用户空间占用CPU：${cpu_user}%"
    echo -e "${SUSSEC}内核空间占用CPU：${cpu_system}%"
    echo -e "${SUSSEC}空闲CPU：${cpu_idle}%"
    echo -e "${SUSSEC}IO等待占用CPU：${cpu_iowait}%"
    sleep 1
    
    echo -e "\n${INFO}正在读取内存信息..."
    sleep 0.6
    mem_total=$(free | grep Mem | awk '{print $2 " KB"}')
    mem_sys_used=$(free | grep Mem | awk '{print $3 " KB"}')
    mem_sys_free=$(free | grep Mem | awk '{print $4 " KB"}')
    mem_user_used=$(free | sed -n 3p | awk '{print $3 " KB"}')
    mem_user_free=$(free | sed -n 3p | awk '{print $4 " KB"}')
    mem_swap_total=$(free | grep Swap | awk '{print $2 " KB"}')
    mem_swap_used=$(free | grep Swap | awk '{print $3 " KB"}')
    mem_swap_free=$(free | grep Swap | awk '{print $4 " KB"}')
    
    echo -e "${SUSSEC}物理内存总量：$mem_total"
    echo -e "${SUSSEC}系统已用内存：$mem_sys_used"
    echo -e "${SUSSEC}系统空闲内存：$mem_sys_free"
    echo -e "${SUSSEC}应用已用内存：$mem_user_used"
    echo -e "${SUSSEC}应用空闲内存：$mem_user_free"
    echo -e "${SUSSEC}交换分区总量：$mem_swap_total"
    echo -e "${SUSSEC}交换分区已用：$mem_swap_used"
    echo -e "${SUSSEC}交换分区空闲：$mem_swap_free"
    sleep 1
    
    echo -e "\n${INFO}正在读取近期运行日志（最后50行）..."
    sleep 0.8
    if [ -f "${HOME}/MikuOne-NEXT/log.log" ]; then
        echo -e "${SUSSEC}近期日志内容："
        tail -n 50 "${HOME}/MikuOne-NEXT/log.log"
    else
        echo -e "${WORRY} 日志文件 ${HOME}/MikuOne-NEXT/log.log 不存在！"
    fi
    sleep 0.5
    echo -e "\n${SUSSEC}==================== 调试信息显示完毕 ====================\033[0m"
}

get_linux_distro() {
    echo -e "${INFO}正在确认发行版..."
    sleep 0.5
    echo -e "${SUSSEC}当前发行版：termux"
    echo "termux"
}

detect_package_manager() {
    local package_manager="pkg"
    
    echo -e "\n${INFO}正在检测包管理器（Termux环境）..."
    sleep 0.6
    if command -v "$package_manager" >/dev/null 2>&1; then
        echo -e "${SUSSEC}检测到的包管理器：$package_manager"
        echo "$package_manager"
    else
        echo -e "${ERROR} Termux默认包管理器 pkg 未找到！请检查Termux环境是否正常。"
        return 1
    fi
    sleep 0.5
}

package_manager=$(detect_package_manager)

case ${1} in
-h | --help)
	echo -e "
-h | --help\t\t\t\t显示帮助信息
-s | --start [Android]\t启动脚本固定版本 [功能]
\t\tAndroid:
\t\t\tinstall proot\t\t安装proot工具
\t\t\tstart proot\t\t启动proot服务
"
	hcjx
	;;
-s | --start)
	case $2 in
	Android | A)
		log "指定加载安卓功能"
		source ${HOME}/MikuOne-NEXT/local/Android/Android_menu $3 $4 $5
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
		self_install aria2c 
		self_install tmux 
		self_install bc 
		validity
		variable
		bash ${HOME}/MikuOne-NEXT/function/update.sh
		log "检查更新"
		source ${HOME}/MikuOne-NEXT/local/Android/Android_menu $1 $2 $3
		;;
	esac
	;;
esac
