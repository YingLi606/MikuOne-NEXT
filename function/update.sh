source ${HOME}/MikuOne-NEXT/config/config.sh
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

A_DIR="${HOME}/MikuOne-NEXT"
B_DIR="${HOME}/.back"
TEMP_DIR="${HOME}/.TEMP"
REMOTE_URL="${rawgit}config/version"
LOCAL_VERSION_FILE="${HOME}/MikuOne-NEXT/config/version"
log 清理临时目录
rm -rf $TEMP_DIR

if [ -f "$LOCAL_VERSION_FILE" ]; then
	LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE" | jq -r .version)
else
	echo "本地版本文件不存在，无法进行版本比较！"
fi

echo -e "${INFO} 正在获取最新版本信息..."
log "更新源信息:$RESPONSE"
log "更新地址: $REMOTE_URL"
RESPONSE=$(curl --connect-timeout 10 -s $REMOTE_URL)

if [ $? -ne 0 ]; then
	echo -e "${WORRY} ❌ 无法获取版本信息，请检查你的网络环境"
fi

REMOTE_VERSION=$(echo $RESPONSE | jq -r .version)
GIT_CLONE=$(echo $RESPONSE | jq -r .git_clone)
DESCRIPTION=$(echo $RESPONSE | jq -r .description)

log "本地版本: $LOCAL_VERSION"
log "云端版本: $REMOTE_VERSION"
log "公告: $DESCRIPTION"

if [ "$(printf '%s\n' "$REMOTE_VERSION" "$LOCAL_VERSION" | sort -V | tail -n1)" != "$LOCAL_VERSION" ]; then
	echo "本地版本: $LOCAL_VERSION"
	echo "云端版本: $REMOTE_VERSION"
	echo "公告: $DESCRIPTION "

	echo "发现新版本，准备更新..."

	log 进行git克隆
	echo -e "${INFO}正在下载更新..."
	if git clone --depth 1 ${git}$GIT_CLONE $TEMP_DIR ; then
	    log 仓库拉取成功
	else
		rm -rf $TEMP_DIR
	    git config --global http.postBuffer 524288000
	    git config --global http.maxRequestBuffer 100M
		log 设置缓冲区
		log 重新拉取
		git clone --depth 1 ${git}$GIT_CLONE $TEMP_DIR
	fi
	if [ $? -ne 0 ]; then
		echo -e "${ERROR}❌ 更新失败，无法克隆仓库！"
		log 拉取失败
		rm -rf $TEMP_DIR
		exit 1
	fi

	echo -e "${INFO}备份当前A分区..."
	log 创建备份的 tar.gz 压缩包
	log "BACKUP_FILE=".back/backup_$(date +%Y%m%d_%H%M%S)_${LOCAL_VERSION}_to_${REMOTE_VERSION}.tar.gz""
	BACKUP_FILE=".back/backup_$(date +%Y%m%d_%H%M%S)_${LOCAL_VERSION}_to_${REMOTE_VERSION}.tar.gz"
	log "正在创建备份的压缩文件: $BACKUP_FILE"
	if ! tar -czf "$BACKUP_FILE" -C "$HOME" MikuOne-NEXT; then
		echo -e "${ERROR}备份失败！"
	fi

	log 更新A分区
	echo -e "${INFO}更新A分区..."
	rm -rf $A_DIR/*
	cp -r $TEMP_DIR/* $A_DIR/

	log 清理临时目录
	rm -rf $TEMP_DIR
	if [ "${qqBot}" != "" ]; then
		Modify_the_variable qqBot ${qqBot} ${HOME}/MikuOne-NEXT/config/config.sh
	fi
	chmod 777 ${HOME}/MikuOne-NEXT/mikunext.sh
	echo "更新完成！将在3秒后重启脚本...当前版本: $REMOTE_VERSION"
	log 更新成功
	# 倒计时3秒后重启脚本，最后清空终端
	sleep 1
	echo "2秒后重启..."
	sleep 1
	echo "1秒后重启..."
	sleep 1
	clear
	exit 1
	${HOME}/MikuOne-NEXT/mikunext.sh
else
	echo "✅ 当前是最新版本，无需更新！"
	log 已是最新版本
fi
