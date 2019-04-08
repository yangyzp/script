#!/bin/bash
#
# #------------------------------------------------------------------#
# |   LemonBench 服务器测试工具      LemonBench Server Test Utility   |
# #------------------------------------------------------------------#
# | Written by iLemonrain <ilemonrain@ilemonrain.com>                |
# | My Blog: https://ilemonrain.com                                  |
# | Telegram: https://t.me/ilemonrain                                |
# | Telegram (For +86 User): https://t.me/ilemonrain_chatbot         |
# | Telegram Channel: https://t.me/ilemonrain_channel                |
# #------------------------------------------------------------------#
# | If you like this project, feel free to donate!                   |
# | 如果你喜欢这个项目，欢迎投喂打赏！                                  |
# |                                                                  |
# | Donate Method 打赏方式：                                          |
# | Alipay QR Code: http://t.cn/EA3pZNt                              |
# | 支付宝二维码：http://t.cn/EA3pZNt                                 |
# | Wechat QR Code: http://t.cn/EA3p639                              |
# | 微信二维码: http://t.cn/EA3p639                                   |
# #------------------------------------------------------------------#
#
# 使用方法 (任选其一):
# (1) wget -qO- https://ilemonrain.com/download/shell/LemonBench.sh | bash
# (2) curl -fsSL https://ilemonrain.com/download/shell/LemonBench.sh | bash
#
# 更新日志：
# 20190407 BetaVersion:
# [F] 修复Spoofer无法获取结果的BUG
# 20190406 BetaVersion:
# [+] 增加CPU/内存性能测试
# [M] 调整测试顺序
#
# 20190405 BetaVersion:
# [F] 修复Speedtest测试一处失效节点
#
# 20190404 BetaVersion:
# [+] 针对物理服务器，增加了虚拟化检测
# [+] 增加了对IPV6的支持
# [+] 增加网络信息模块
# [F] 修复了几处检测BUG
#
# === 全局定义 =====================================

# 全局参数定义
BuildTime="20190407 BetaVersion"

# 字体颜色定义
Font_Black="\033[30m"  
Font_Red="\033[31m" 
Font_Green="\033[32m"  
Font_Yellow="\033[33m"  
Font_Blue="\033[34m"  
Font_Purple="\033[35m"  
Font_SkyBlue="\033[36m"  
Font_White="\033[37m" 
Font_Suffix="\033[0m"

# 消息提示定义
Msg_Info="${Font_Blue}[Info] ${Font_Suffix}"
Msg_Warning="${Font_Yellow}[Warning] ${Font_Suffix}"
Msg_Debug="${Font_Yellow}[Debug] ${Font_Suffix}"
Msg_Error="${Font_Red}[Error] ${Font_Suffix}"
Msg_Success="${Font_Green}[Success] ${Font_Suffix}"
Msg_Fail="${Font_Red}[Failed] ${Font_Suffix}"

# =================================================

# === 全局模块 =====================================

# Trap终止信号捕获
trap "Global_TrapSigExit_Sig1" 1
trap "Global_TrapSigExit_Sig2" 2
trap "Global_TrapSigExit_Sig3" 3
trap "Global_TrapSigExit_Sig15" 15

# Trap终止信号1 - 处理
Global_TrapSigExit_Sig1() {
    echo -e "\n\n${Msg_Error}接收到终止信号(SIGHUP), 正在退出 ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# Trap终止信号2 - 处理 (Ctrl+C)
Global_TrapSigExit_Sig2() {
    echo -e "\n\n${Msg_Error}接收到终止信号(SIGINT / Ctrl+C), 正在退出 ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# Trap终止信号3 - 处理
Global_TrapSigExit_Sig3() {
    echo -e "\n\n${Msg_Error}接收到终止信号(SIGQUIT), 正在退出 ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# Trap终止信号15 - 处理 (进程被杀)
Global_TrapSigExit_Sig15() {
    echo -e "\n\n${Msg_Error}接收到终止信号(SIGTERM), 正在退出 ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# 简易JSON解析器
PharseJSON() {
    # 使用方法: PharseJSON "要解析的原JSON文本" "要解析的键值"
    # Example: PharseJSON ""Value":"123456"" "Value" [返回结果: 123456]
    echo -n $1 | grep -oP '(?<='$2'":)[0-9A-Za-z]+'
    if [ "$?" = "1" ]; then
        echo -n $1 | grep -oP ''$2'[" :]+\K[^"]+'
        if [ "$?" = "1" ]; then
            echo -n "null"
            return 1
        fi
    fi
}

# 读取配置文件
ReadConfig() {
    # 使用方法: ReadConfig <配置文件> <读取参数>
    # Example: ReadConfig "/etc/config.cfg" "Parameter"
    cat $1 | sed '/^'$2'=/!d;s/.*=//'
}

# 程序启动动作
Global_StartupInit_Action() {
    Global_Startup_Header
    echo -e "${Msg_Info}已启动测试模式：${Font_SkyBlue}${Global_TestModeTips}${Font_Suffix}"
    # 清理残留，为新一次的运行做好准备
    echo -e "${Msg_Info}正在初始化环境，请稍后 ..."
    rm -rf /tmp/.LBench_tmp
    rm -rf /.tmp_LBench/
    mkdir /tmp/.LBench_tmp/
    echo -e "${Msg_Info}正在检查必需环境 ..."
    Check_Virtwhat
    Check_Speedtest
    Check_BestTrace
    Check_Spoofer
    Check_SysBench
    echo -e "${Msg_Info}正在启动测试 ...\n\n"
    clear
}

# 捕获异常信号后的动作
Global_TrapSigExit_Action() {
    rm -rf /tmp/.LBench_tmp
    rm -rf /.tmp_LBench/
}

# =================================================

# =============== -> 主程序开始 -< ===============

# =============== SystemInfo模块 部分 ===============
SystemInfo_GetHostname() {
    LBench_Result_Hostname="$(hostname)"
}

SystemInfo_GetCPUInfo() {
    mkdir -p /tmp/.LBench_tmp/data >/dev/null 2>&1
    cat /proc/cpuinfo > /tmp/.LBench_tmp/data/cpuinfo
    local ReadCPUInfo="cat /tmp/.LBench_tmp/data/cpuinfo"
    LBench_Result_CPUModelName="$($ReadCPUInfo | awk -F ': ' '/model name/{print $2}' | sort -u)"
    LBench_Result_CPUCacheSize="$($ReadCPUInfo | awk -F ': ' '/cache size/{print $2}' | sort -u)"
    LBench_Result_CPUPhysicalNumber="$($ReadCPUInfo | awk -F ': ' '/physical id/{print $2}' | sort -u | wc -l)"
    LBench_Result_CPUCoreNumber="$($ReadCPUInfo | awk -F ': ' '/cpu cores/{print $2}' | sort -u)"
    LBench_Result_CPUThreadNumber="$($ReadCPUInfo | awk -F ': ' '/cores/{print $2}' | wc -l)"
    LBench_Result_CPUProcessorNumber="$($ReadCPUInfo | awk -F ': ' '/processor/{print $2}' | wc -l)"
    LBench_Result_CPUSiblingsNumber="$($ReadCPUInfo | awk -F ': ' '/siblings/{print $2}' | sort -u)"
    LBench_Result_CPUTotalCoreNumber="$($ReadCPUInfo | awk -F ': ' '/physical id/&&/0/{print $2}' | wc -l)"
    # 虚拟化能力检测
    SystemInfo_GetVirtType
    if [ "${Var_VirtType}" = "dedicated" ] || [ "${Var_VirtType}" = "wsl" ]; then
        LBench_Result_CPUIsPhysical="1"
        local VirtCheck="$(cat /proc/cpuinfo | grep -oE 'vmx|svm' | uniq)"
        if [ "${VirtCheck}" != "" ]; then
            LBench_Result_CPUVirtualization="1"
            local VirtualizationType="$(lscpu | awk /Virtualization:/'{print $2}')"
            LBench_Result_CPUVirtualizationType="${VirtualizationType}"
        else
            LBench_Result_CPUVirtualization="0"
        fi
    else
        LBench_Result_CPUIsPhysical="0"
    fi
}

SystemInfo_GetSystemBit() {
    LBench_Result_SystemBit="$(uname -m)"
    if [ "${LBench_Result_SystemBit}" = "unknown" ]; then
        LBench_Result_SystemBit="$(arch)"
    fi
}

SystemInfo_GetMemInfo(){
    mkdir -p /tmp/.LBench_tmp/data >/dev/null 2>&1
    cat /proc/meminfo > /tmp/.LBench_tmp/data/meminfo
    local ReadMemInfo="cat /tmp/.LBench_tmp/data/meminfo"
    # 获取总内存
    LBench_Result_MemoryTotal_KB="$($ReadMemInfo | awk '/MemTotal/{print $2}')"
    LBench_Result_MemoryTotal_MB="$(echo $LBench_Result_MemoryTotal_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_MemoryTotal_GB="$(echo $LBench_Result_MemoryTotal_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取可用内存
    local MemFree="$($ReadMemInfo | awk '/MemFree/{print $2}')"
    local Buffers="$($ReadMemInfo | awk '/Buffers/{print $2}')"
    local Cached="$($ReadMemInfo | awk '/Cached/{print $2}')"
    LBench_Result_MemoryFree_KB="$(echo $MemFree $Buffers $Cached | awk '{printf $1+$2+$3}')"
    LBench_Result_MemoryFree_MB="$(echo $LBench_Result_MemoryFree_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_MemoryFree_GB="$(echo $LBench_Result_MemoryFree_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取已用内存
    local MemUsed="$(echo $LBench_Result_MemoryTotal_KB $LBench_Result_MemoryFree_KB | awk '{printf $1-$2}' )"
    LBench_Result_MemoryUsed_KB="$MemUsed"
    LBench_Result_MemoryUsed_MB="$(echo $LBench_Result_MemoryUsed_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_MemoryUsed_GB="$(echo $LBench_Result_MemoryUsed_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取Swap总量
    LBench_Result_SwapTotal_KB="$($ReadMemInfo | awk '/SwapTotal/{print $2}')"
    LBench_Result_SwapTotal_MB="$(echo $LBench_Result_SwapTotal_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_SwapTotal_GB="$(echo $LBench_Result_SwapTotal_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取可用Swap
    LBench_Result_SwapFree_KB="$($ReadMemInfo | awk '/SwapTotal/{print $2}')"
    LBench_Result_SwapFree_MB="$(echo $LBench_Result_SwapFree_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_SwapFree_GB="$(echo $LBench_Result_SwapFree_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取已用Swap
    local SwapUsed="$(echo $LBench_Result_SwapTotal_KB $LBench_Result_SwapFree_KB | awk '{printf $1-$2}')"
    LBench_Result_SwapUsed_KB="$SwapUsed"
    LBench_Result_SwapUsed_MB="$(echo $LBench_Result_SwapUsed_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_SwapUsed_GB="$(echo $LBench_Result_SwapUsed_KB | awk '{printf "%.2f\n",$1/1048576}')"
}

SystemInfo_GetOSRelease() {
    if [ -f "/etc/centos-release" ]; then    # CentOS
        Var_OSRelease="centos"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3,$4}')"
        if [ "$(rpm -qa | grep -o el6 | sort -u)" = "el6" ]; then
            Var_CentOSELRepoVersion="6"
            local Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $3}')"
        elif [ "$(rpm -qa | grep -o el7 | sort -u)" = "el7" ]; then
            Var_CentOSELRepoVersion="7"
            local Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $4}')"
        else
            local Var_CentOSELRepoVersion="unknown"
            local Var_OSReleaseVersion="<Unknown Release>"
        fi        
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/fedora-release" ]; then  # Fedora
        Var_OSRelease="fedora"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3}')"
        local Var_OSReleaseVersion="$(cat /etc/fedora-release | awk '{print $3,$4,$5,$6,$7}')"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/lsb-release" ]; then     # Ubuntu
        Var_OSRelease="ubuntu"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/NAME/{print $3}' | head -n1)"
        local Var_OSReleaseVersion="$(cat /etc/os-release | awk -F '[= "]' '/VERSION/{print $3,$4,$5,$6,$7}' | head -n1)"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
        Var_OSReleaseVersion_Short="$(cat /etc/lsb-release | awk -F '[= "]' '/DISTRIB_RELEASE/{print $2}')"
    elif [ -f "/etc/debian_version" ]; then  # Debian
        Var_OSRelease="debian"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3,$4}')"
        local Var_OSReleaseVersion="$(cat /etc/debian_version | awk '{print $1}')"
        local Var_OSReleaseVersionShort="$(cat /etc/debian_version | awk '{printf "%d\n",$1}')"
        if [ "${Var_OSReleaseVersionShort}" = "7" ]; then
            Var_OSReleaseVersion_Short="7"
        elif [ "${Var_OSReleaseVersionShort}" = "8" ]; then
            Var_OSReleaseVersion_Short="8"
        elif [ "${Var_OSReleaseVersionShort}" = "9" ]; then
            Var_OSReleaseVersion_Short="9"
        else
            Var_OSReleaseVersion_Short="sid"
        fi
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/alpine-release" ]; then  # Alpine Linux
        Var_OSRelease="alpinelinux"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/NAME/{print $3,$4}' | head -n1)"
        local Var_OSReleaseVersion="$(cat /etc/alpine-release | awk '{print $1}')"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    else
        Var_OSRelease="unknown" # 未知系统分支
        LBench_Result_OSReleaseFullName="[Error: 未知系统分支 !]"
    fi
}

SystemInfo_GetVirtType() {
    if [ ! -f "/usr/sbin/virt-what" ]; then
        Var_VirtType="Unknown"
        LBench_Result_VirtType="[Error: 未安装virt-what !]"
    elif [ -f "/.dockerenv" ]; then # 处理Docker虚拟化
        Var_VirtType="docker"
        LBench_Result_VirtType="Docker"
    elif [ -c "/dev/lxss" ]; then # 处理WSL虚拟化
        Var_VirtType="wsl"
        LBench_Result_VirtType="Windows Subsystem for Linux (WSL)"
    else # 正常判断流程
        Var_VirtType="$(virt-what | xargs)"
        local Var_VirtTypeCount="$(echo $Var_VirtTypeCount | wc -l)"
        if [ "${Var_VirtTypeCount}" -gt "1" ]; then   # 处理嵌套虚拟化
            LBench_Result_VirtType="echo ${Var_VirtType}"
            Var_VirtType="$(echo ${Var_VirtType} | head -n1)" # 使用检测到的第一种虚拟化继续做判断
        elif [ "${Var_VirtTypeCount}" -eq "1" ] && [ "${Var_VirtType}" != "" ]; then # 只有一种虚拟化
            LBench_Result_VirtType="${Var_VirtType}"
        else
            local Var_BIOSVendor="$(dmidecode -s bios-vendor)"
            if [ "${Var_BIOSVendor}" = "SeaBIOS" ]; then
                Var_VirtType="Unknown"
                LBench_Result_VirtType="Unknown with SeaBIOS BIOS"
            else
                Var_VirtType="dedicated"
                LBench_Result_VirtType="dedicated with ${Var_BIOSVendor} BIOS"
            fi
        fi
    fi
}

SystemInfo_GetLoadAverage() {
    local Var_LoadAverage="$(cat /proc/loadavg)"
    LBench_Result_LoadAverage_1min="$(echo ${Var_LoadAverage} | awk '{print $1}')"
    LBench_Result_LoadAverage_5min="$(echo ${Var_LoadAverage} | awk '{print $2}')"
    LBench_Result_LoadAverage_15min="$(echo ${Var_LoadAverage} | awk '{print $3}')"
}

SystemInfo_GetDiskStat() {
    LBench_Result_DiskRootPath="$(df -x tmpfs / | awk 'NR==2 {print $1}')"
    local Var_DiskTotalSpace_KB="$(df -x tmpfs / | awk 'NR==2 {print $2}')"
    LBench_Result_DiskTotal_KB="${Var_DiskTotalSpace_KB}"
    LBench_Result_DiskTotal_MB="$(echo ${Var_DiskTotalSpace_KB} | awk '{printf "%.2f\n",$1/1000}')"
    LBench_Result_DiskTotal_GB="$(echo ${Var_DiskTotalSpace_KB} | awk '{printf "%.2f\n",$1/1000000}')"
    LBench_Result_DiskTotal_TB="$(echo ${Var_DiskTotalSpace_KB} | awk '{printf "%.2f\n",$1/1000000000}')"
    local Var_DiskUsedSpace_KB="$(df -x tmpfs / | awk 'NR==2 {print $3}')"
    LBench_Result_DiskUsed_KB="${Var_DiskUsedSpace_KB}"
    LBench_Result_DiskUsed_MB="$(echo ${LBench_Result_DiskUsed_KB} | awk '{printf "%.2f\n",$1/1000}')"
    LBench_Result_DiskUsed_GB="$(echo ${LBench_Result_DiskUsed_KB} | awk '{printf "%.2f\n",$1/1000000}')"
    LBench_Result_DiskUsed_TB="$(echo ${LBench_Result_DiskUsed_KB} | awk '{printf "%.2f\n",$1/1000000000}')"
    local Var_DiskFreeSpace_KB="$(df -x tmpfs / | awk 'NR==2 {print $4}')"
    LBench_Result_DiskFree_KB="${Var_DiskFreeSpace_KB}"
    LBench_Result_DiskFree_MB="$(echo ${LBench_Result_DiskFree_KB} | awk '{printf "%.2f\n",$1/1000}')"
    LBench_Result_DiskFree_GB="$(echo ${LBench_Result_DiskFree_KB} | awk '{printf "%.2f\n",$1/1000000}')"
    LBench_Result_DiskFree_TB="$(echo ${LBench_Result_DiskFree_KB} | awk '{printf "%.2f\n",$1/1000000000}')"
}

SystemInfo_GetNetworkInfo() {
    LBench_Result_LocalIP_IPV4="$(curl -s http://ipv4.whatismyip.akamai.com/)"
    LBench_Result_LocalIP_IPV6="$(curl -s http://ipv6.whatismyip.akamai.com/)"
    # 判断三种网络情况：
    # - IPV4 Only：只有IPV4
    # - IPV6 Only：只有IPV6
    # - DualStack：双栈 (IPV4+IPV6)
    #
    # 判断IPV4 Only
    if [ "${LBench_Result_LocalIP_IPV4}" != "" ] && [ "${LBench_Result_LocalIP_IPV6}" = "" ]; then
        LBench_Result_NetworkStat="ipv4only"
        local IPAPI_Result_IPV4="$(curl -s4 https://ipapi.co/json/)"
    # 判断IPV6 Only
    elif [ "${LBench_Result_LocalIP_IPV4}" = "" ] && [ "${LBench_Result_LocalIP_IPV6}" != "" ]; then
        LBench_Result_NetworkStat="ipv6only"
        local IPAPI_Result_IPV6="$(curl -s6 https://ipapi.co/json/)"
    # 判断双栈
    elif [ "${LBench_Result_LocalIP_IPV4}" != "" ] && [ "${LBench_Result_LocalIP_IPV6}" != "" ]; then
        LBench_Result_NetworkStat="dualstack"
        local IPAPI_Result_IPV4="$(curl -s4 https://ipapi.co/json/)"
        local IPAPI_Result_IPV6="$(curl -s6 https://ipapi.co/json/)"
    # 返回未知值
    else
        LBench_Result_NetworkStat="unknown"
    fi
    # 提取IPV4信息
    if [ "${IPAPI_Result_IPV4}" != "" ]; then
        IPAPI_IPV4_ip="$(PharseJSON "${IPAPI_Result_IPV4}" "ip")"
        IPAPI_IPV4_city="$(PharseJSON "${IPAPI_Result_IPV4}" "city")"
        IPAPI_IPV4_region="$(PharseJSON "${IPAPI_Result_IPV4}" "region")"
        IPAPI_IPV4_country="$(PharseJSON "${IPAPI_Result_IPV4}" "country")"
        IPAPI_IPV4_country_name="$(PharseJSON "${IPAPI_Result_IPV4}" "country_name")"
        IPAPI_IPV4_asn="$(PharseJSON "${IPAPI_Result_IPV4}" "asn")"
        IPAPI_IPV4_org="$(PharseJSON "${IPAPI_Result_IPV4}" "org")"
    fi
    if [ "${IPAPI_Result_IPV6}" != "" ]; then
        IPAPI_IPV6_ip="$(PharseJSON "${IPAPI_Result_IPV6}" "ip")"
        IPAPI_IPV6_city="$(PharseJSON "${IPAPI_Result_IPV6}" "city")"
        IPAPI_IPV6_region="$(PharseJSON "${IPAPI_Result_IPV6}" "region")"
        IPAPI_IPV6_country="$(PharseJSON "${IPAPI_Result_IPV6}" "country")"
        IPAPI_IPV6_country_name="$(PharseJSON "${IPAPI_Result_IPV6}" "country_name")"
        IPAPI_IPV6_asn="$(PharseJSON "${IPAPI_Result_IPV6}" "asn")"
        IPAPI_IPV6_org="$(PharseJSON "${IPAPI_Result_IPV6}" "org")"
    fi
}

Function_GetSystemInfo() {
    clear
    echo -e "${Msg_Info}LemonBench Server Test Toolkit Build ${BuildTime}"
    echo -e "${Msg_Info}SystemInfo - 正在获取系统信息 ..."
    Check_Virtwhat
    echo -e "${Msg_Info}正在获取CPU信息 ..."
    SystemInfo_GetCPUInfo
    SystemInfo_GetLoadAverage
    SystemInfo_GetSystemBit
    echo -e "${Msg_Info}正在获取内存信息 ..."
    SystemInfo_GetMemInfo
    echo -e "${Msg_Info}正在获取虚拟化类型信息 ..."
    SystemInfo_GetVirtType
    echo -e "${Msg_Info}正在获取系统版本信息 ..."
    SystemInfo_GetOSRelease
    echo -e "${Msg_Info}正在获取磁盘信息 ..."
    SystemInfo_GetDiskStat
    echo -e "${Msg_Info}正在获取网络信息 ..."
    SystemInfo_GetNetworkInfo
    clear
}

Function_ShowSystemInfo() {
    echo -e "\n ${Font_Yellow}-> 系统信息${Font_Suffix}\n"
    echo -e " ${Font_Yellow}系统名称:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_OSReleaseFullName}${Font_Suffix}"
    echo -e " ${Font_Yellow}CPU型号:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUModelName}${Font_Suffix}"
    echo -e " ${Font_Yellow}CPU缓存大小:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUCacheSize}${Font_Suffix}"
    # CPU数量 分支判断
    if [ "${LBench_Result_CPUIsPhysical}" = "1" ]; then
        # 如果只存在1个物理CPU (单路物理服务器)
        if [ "${LBench_Result_CPUPhysicalNumber}" -eq "1" ]; then
            echo -e " ${Font_Yellow}CPU数量:${Font_Suffix}\t\t${LBench_Result_CPUPhysicalNumber} ${Font_SkyBlue}物理CPU${Font_Suffix}, ${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}核心${Font_Suffix}, ${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}线程${Font_Suffix}"
        # 存在多个CPU, 继续深入分析检测 (多路物理服务器)
        else 
            echo -e " ${Font_Yellow}CPU数量:${Font_Suffix}\t\t${LBench_Result_CPUPhysicalNumber} ${Font_SkyBlue}物理CPU${Font_Suffix}, ${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}核心/CPU${Font_Suffix}, ${LBench_Result_CPUSiblingsNumber} ${Font_SkyBlue}线程/CPU${Font_Suffix} (总共 ${Font_SkyBlue}${LBench_Result_CPUTotalCoreNumber}${Font_Suffix} 核心, ${Font_SkyBlue}${LBench_Result_CPUProcessorNumber}${Font_Suffix} 线程)"
        fi
        if [ "${LBench_Result_CPUVirtualization}" = "1" ]; then
            echo -e " ${Font_Yellow}虚拟化已就绪:${Font_Suffix}\t\t${Font_SkyBlue}是${Font_Suffix} ${Font_SkyBlue}(基于${Font_Suffix} ${LBench_Result_CPUVirtualizationType}${Font_SkyBlue})${Font_Suffix}"
        else
            echo -e " ${Font_Yellow}虚拟化已就绪:${Font_Suffix}\t\t${Font_SkyRed}否${Font_Suffix}"
        fi
    elif [ "${Var_VirtType}" = "openvz" ]; then
        echo -e " ${Font_Yellow}CPU数量:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix} (${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}宿主机核心${Font_Suffix})"
    else
        echo -e " ${Font_Yellow}CPU数量:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix}"
    fi
    echo -e " ${Font_Yellow}虚拟化类型:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_VirtType}${Font_Suffix}"
    # 内存使用率 分支判断
    if [ "${LBench_Result_MemoryUsed_KB}" -lt "1024" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1048576" ]; then
        echo -e " ${Font_Yellow}内存使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_MemoryUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1048576" ]; then
        echo -e " ${Font_Yellow}内存使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_MemoryUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1073741824" ]; then
        echo -e " ${Font_Yellow}内存使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_GB} GB${Font_Suffix}"
    else
        echo -e " ${Font_Yellow}内存使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_GB} GB${Font_Suffix}"
    fi
    # Swap使用率 分支判断
    if [ "${LBench_Result_SwapTotal_KB}" -eq "0" ]; then
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}[无Swap分区/文件]${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1024" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1048576" ]; then
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_KB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1024" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1073741824" ]; then
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_KB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1048576" ]; then
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1073741824" ]; then
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
    else
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
    fi
    # 启动磁盘
    echo -e "${Font_Yellow} 引导设备:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskRootPath}${Font_Suffix}"
    # 磁盘使用率 分支判断
    if [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ]; then
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_GB} GB${Font_Suffix}"
    elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_GB} GB${Font_Suffix}"
    elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -ge "1000000000" ]; then
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_TB} TB${Font_Suffix}"
    else
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_TB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_TB} TB${Font_Suffix}"
    fi
    # 系统负载
    echo -e " ${Font_Yellow}系统负载(1/5/15min):${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_LoadAverage_1min} ${LBench_Result_LoadAverage_5min} ${LBench_Result_LoadAverage_15min} ${Font_Suffix}"
}

Function_ShowNetworkInfo() {
    echo -e "\n ${Font_Yellow}-> 网络信息${Font_Suffix}\n"
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e " ${Font_Yellow}IPV4 - 本机IP:${Font_Suffix}\t\t${Font_SkyBlue}[${IPAPI_IPV4_country}] ${IPAPI_IPV4_ip}${Font_Suffix}"
        echo -e " ${Font_Yellow}IPV4 - ASN信息:${Font_Suffix}\t${Font_SkyBlue}${IPAPI_IPV4_asn} (${IPAPI_IPV4_org})${Font_Suffix}"
        echo -e " ${Font_Yellow}IPV4 - 归属地:${Font_Suffix}\t\t${Font_SkyBlue}${IPAPI_IPV4_country_name}, ${IPAPI_IPV4_region}, ${IPAPI_IPV4_city}${Font_Suffix}"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e " ${Font_Yellow}IPV6 - 本机IP:${Font_Suffix}\t\t${Font_SkyBlue}[${IPAPI_IPV6_country}] ${IPAPI_IPV6_ip}${Font_Suffix}"
        echo -e " ${Font_Yellow}IPV6 - ASN信息:${Font_Suffix}\t${Font_SkyBlue}${IPAPI_IPV6_asn} (${IPAPI_IPV6_org})${Font_Suffix}"
        echo -e " ${Font_Yellow}IPV6 - 归属地:${Font_Suffix}\t\t${Font_SkyBlue}${IPAPI_IPV6_country_name}, ${IPAPI_IPV6_region}, ${IPAPI_IPV6_city}${Font_Suffix}"
    fi
}

# =============== 测试启动与结束动作 ===============
Function_BenchStart() {
    clear
    echo -e "${Font_SkyBlue}LemonBench${Font_Suffix} ${Font_Yellow}Server Test Tookit${Font_Suffix} ${BuildTime} ${Font_SkyBlue}(C)iLemonrain. All Rights Reserved.${Font_Suffix}"
    echo -e "=========================================================================================="
    echo -e " "
    echo -e " ${Msg_Info}${Font_Yellow}测试开始时间：${Font_Suffix} ${Font_SkyBlue}$(date +"%Y-%m-%d %H:%M:%S")${Font_Suffix}"
    echo -e " ${Msg_Info}${Font_Yellow}测试模式：${Font_Suffix} ${Font_SkyBlue}${Global_TestModeTips}${Font_Suffix}"
    echo -e " "
}

Function_BenchFinish() {
    echo -e ""
    echo -e "=========================================================================================="
    echo -e " "
    echo -e " ${Msg_Info}${Font_Yellow}测试结束时间：${Font_Suffix} ${Font_SkyBlue}$(date +"%Y-%m-%d %H:%M:%S")${Font_Suffix}"
    echo -e " "
}

# =============== Speedtest 部分 ===============
Run_Speedtest() {
    # 调用方式: Run_Speedtest "服务器ID" "节点名称(用于显示)"
    if [ -f "/usr/sbin/speedtest-cli" ]; then
        Speedtest_Exec="speedtest-cli"
    else
        Speedtest_Exec="speedtest"
    fi 
    echo -n -e " $2\c"
    Speedtest_Result_Ping=""
    Speedtest_Result_Download=""
    Speedtest_Result_Upload=""
    if [ "$1" = "default" ]; then
        local Speedtest_Result="$(${Speedtest_Exec} --simple --bytes)"
    else
        local Speedtest_Result="$(${Speedtest_Exec} --server $1 --simple --bytes)"
    fi
    Speedtest_Result_Ping="$(echo "${Speedtest_Result}" | awk '(NR==1){print $2}')"
    Speedtest_Result_Download="$(echo "${Speedtest_Result}" | awk '(NR==2){print $2}')"
    Speedtest_Result_Upload="$(echo "${Speedtest_Result}" | awk '(NR==3){print $2}')"
    echo -n -e "\r $2\t\t${Font_SkyBlue}${Speedtest_Result_Upload}${Font_Suffix} MB/s\t${Font_SkyBlue}${Speedtest_Result_Download}${Font_Suffix} MB/s\t${Font_SkyBlue}${Speedtest_Result_Ping}${Font_Suffix} ms\n"
}

Function_Speedtest_Fast() {
    echo -e "\n ${Font_Yellow}-> Speedtest.net 网速测试${Font_Suffix}\n"
    Check_Speedtest
    echo -e " ${Font_Yellow}节点名称\t\t上传速度\t下载速度\tPing延迟${Font_Suffix}"
    Run_Speedtest "default" "距离最近测速点"
    Run_Speedtest "5145" "华北-北京联通"
    Run_Speedtest "16803" "华东-上海移动"
    Run_Speedtest "17251" "华南-广州电信"
}

Function_Speedtest_Full() {
    echo -e "\n ${Font_Yellow}-> Speedtest.net 网速测试${Font_Suffix}\n"
    Check_Speedtest
    echo -e " ${Font_Yellow}节点名称\t\t上传速度\t下载速度\tPing延迟${Font_Suffix}"
    # 默认测试
    Run_Speedtest "default" "距离最近测速点"
    # ST测试
    Run_Speedtest "10392" "ST-美国洛杉矶"
    # 国内测试
    Run_Speedtest "9484" "东北-吉林联通"
    # Run_Speedtest "16375" "东北-吉林移动"  # 暂不可用
    Run_Speedtest "5145" "华北-北京联通"
    Run_Speedtest "17184" "华北-天津移动"
    Run_Speedtest "13704" "华中-南京联通"
    Run_Speedtest "5396" "华中-苏州电信"
    Run_Speedtest "5083" "华东-上海联通"
    Run_Speedtest "16803" "华东-上海移动"
    Run_Speedtest "17251" "华南-广东电信"
    Run_Speedtest "4515" "华南-广东移动"
    Run_Speedtest "5103" "西南-昆明联通"
    Run_Speedtest "6168" "西南-昆明移动"
    Run_Speedtest "4690" "西北-兰州联通"
    Run_Speedtest "10305" "西北-广西电信"
    Run_Speedtest "16145" "西北-兰州移动"
}

# =============== 磁盘测试 部分 ===============
Run_DiskTest() {
    # 调用方式: Run_DiskTest "测试文件名" "块大小" "写入次数" "测试项目名称"
    SystemInfo_GetVirtType
    mkdir -p /.tmp_LBench/DiskTest >/dev/null 2>&1
    mkdir -p /tmp/.LBench_tmp/data >/dev/null 2>&1
    local Var_DiskTestResultFile="/tmp/.LBench_tmp/data/disktest_result"
    # 将先测试读，后测试写
    echo -n -e " $4\c"
    # 清理缓存，避免影响测试结果
    sync
    if [ "${Var_VirtType}" != "docker" ] && [ "${Var_VirtType}" != "wsl" ]; then
        echo 3 > /proc/sys/vm/drop_caches
    fi
    # 避免磁盘压力过高，启动测试前暂停1秒
    sleep 1
    # 正式写测试 新版代码
    dd if=/dev/zero of=/.tmp_LBench/DiskTest/$1 bs=$2 count=$3 oflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_WriteSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} MB\/s|[0-9]{1,}.[0-9]{1,} MB\/秒|[0-9]{1,} MB\/s|[0-9]{1,} MB\/秒|[0-9]{1,}.[0-9]{1,} GB\/s|[0-9]{1,} MB\/s|[0-9]{1,} MB\/秒|[0-9]{1,}.[0-9]{1,} GB\/秒")"
    DiskTest_WriteSpeed="$(echo "${DiskTest_WriteSpeed_ResultRAW}" | sed "s/s/秒/")"
    local DiskTest_WriteTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_WriteTime="$(echo ${DiskTest_WriteTime_ResultRAW} | awk '{print $1}')"
    DiskTest_WriteIOPS="$(echo ${DiskTest_WriteTime} $3 | awk '{printf "%d\n",$2/$1}')"
    DiskTest_WritePastTime="$(echo ${DiskTest_WriteTime} | awk '{printf "%.2f\n",$1}')" 
    echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime} 秒)${Font_Suffix}\t\t\c"
    # 清理结果文件，准备下一次测试
    rm -f ${Var_DiskTestResultFile}
    # 清理缓存，避免影响测试结果
    sync
    if [ "${Var_VirtType}" != "docker" ] && [ "${Var_VirtType}" != "wsl" ]; then
        echo 3 > /proc/sys/vm/drop_caches
    fi
    sleep 0.5
    # 正式读测试 新版代码
    dd if=/.tmp_LBench/DiskTest/$1 of=/dev/null bs=$2 count=$3 iflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_ReadSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} MB\/s|[0-9]{1,}.[0-9]{1,} MB\/秒|[0-9]{1,} MB\/s|[0-9]{1,} MB\/秒|[0-9]{1,}.[0-9]{1,} GB\/s|[0-9]{1,} MB\/s|[0-9]{1,} MB\/秒|[0-9]{1,}.[0-9]{1,} GB\/秒")"
    DiskTest_ReadSpeed="$(echo "${DiskTest_ReadSpeed_ResultRAW}" | sed "s/s/秒/")"
    local DiskTest_ReadTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_ReadTime="$(echo ${DiskTest_ReadTime_ResultRAW} | awk '{print $1}')"
    DiskTest_ReadIOPS="$(echo ${DiskTest_ReadTime} $3 | awk '{printf "%d\n",$2/$1}')"
    DiskTest_ReadPastTime="$(echo ${DiskTest_ReadTime} | awk '{printf "%.2f\n",$1}')" 
    rm -f ${Var_DiskTestResultFile}
    # 输出结果
    echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime} 秒)${Font_Suffix}\t\t${Font_SkyBlue}${DiskTest_ReadSpeed} (${DiskTest_ReadIOPS} IOPS, ${DiskTest_ReadPastTime} 秒)${Font_Suffix}\n"
    rm -rf /.tmp_LBench/DiskTest/
}

Function_DiskTest_Fast() {
    echo -e "\n ${Font_Yellow}-> 磁盘性能测试 (4K块/1M块, Direct写入)${Font_Suffix}\n"
    SystemInfo_GetVirtType
    SystemInfo_GetOSRelease
    if [ "${Var_VirtType}" = "docker" ] || [ "${Var_VirtType}" = "wsl" ]; then
        echo -e " ${Msg_Warning}由于系统架构限制，磁盘测试结果可能会受到缓存影响，仅供参考！\n"
    fi
    echo -e " ${Font_Yellow}测试项目\t\t写入速度\t\t\t\t读取速度${Font_Suffix}"
    Run_DiskTest "100MB.test" "4k" "25600" "100MB-4K块"
    Run_DiskTest "1000MB.test" "1M" "1000" "1000MB-1M块"
}

Function_DiskTest_Full() {
    echo -e "\n ${Font_Yellow}-> 磁盘性能测试 (4K块/1M块, Direct写入)${Font_Suffix}\n"
    SystemInfo_GetVirtType
    SystemInfo_GetOSRelease
    if [ "${Var_VirtType}" = "docker" ] || [ "${Var_VirtType}" = "wsl" ]; then
        echo -e " ${Msg_Warning}由于系统架构限制，磁盘测试结果可能会受到缓存影响，仅供参考！\n"
    fi
    echo -e " ${Font_Yellow}测试项目\t\t写入速度\t\t\t\t读取速度${Font_Suffix}"
    Run_DiskTest "10MB.test" "4k" "2560" "10MB-4K块"
    Run_DiskTest "10MB.test" "1M" "10" "10MB-1M块"
    Run_DiskTest "100MB.test" "4k" "25600" "100MB-4K块"
    Run_DiskTest "100MB.test" "1M" "100" "100MB-1M块"
    Run_DiskTest "1000MB.test" "4k" "256000" "1000MB-4K块"
    Run_DiskTest "1000MB.test" "1M" "1000" "1000MB-1M块"
}

# =============== BestTrace 部分 ===============
Run_BestTrace() {
    # 调用方式: Run_BestTrace "目标IP" "ICMP/TCP" "最大跃点数" "说明"
    if [ "$2" = "tcp" ] || [ "$2" = "TCP" ]; then
        echo -e "路由追踪到 $4 (TCP 模式, 最大 $3 跃点)"
        echo -e "============================================================"
        besttrace -g cn -q 1 -T -m $3 $1
    else
        echo -e "路由追踪到 $4 (ICMP 模式, 最大 $3 跃点)"
        echo -e "============================================================"
        besttrace -g cn -q 1 -m $3 $1
    fi
}

Function_BestTrace_Fast() {
    Check_BestTrace
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> 路由追踪测试 (IPV4)${Font_Suffix}\n"
        Run_BestTrace "123.125.99.1" "TCP" "30" "北京联通"
        Run_BestTrace "180.153.28.1" "TCP" "30" "上海电信"
        Run_BestTrace "211.139.129.1" "TCP" "30" "广州移动"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> 路由追踪测试 (IPV6)${Font_Suffix}\n"
        Run_BestTrace6 "2408:80f0:4100:2005::3" "ICMP" "30" "北京联通-IPV6"
        Run_BestTrace6 "240e:0:a::c9:1cb4" "ICMP" "30" "北京电信-IPV6"
        Run_BestTrace6 "2409:8080:0:2:103:1b1:0:1" "ICMP" "30" "北京移动-IPV6"
        Run_BestTrace6 "2001:da8:a0:1001::1" "ICMP" "30" "北京教育网CERNET2-IPV6"
    fi
}

Function_BestTrace_Full() {
    Check_BestTrace
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> 路由追踪测试 (IPV4)${Font_Suffix}\n"
        # 国内部分
        Run_BestTrace "123.125.99.1" "TCP" "30" "北京联通"
        Run_BestTrace "180.149.128.1" "TCP" "30" "北京电信"
        Run_BestTrace "211.136.93.48" "TCP" "30" "北京移动"
        Run_BestTrace "58.247.0.2" "TCP" "30" "上海联通" #
        Run_BestTrace "180.153.28.1" "TCP" "30" "上海电信"
        Run_BestTrace "211.136.97.65" "TCP" "30" "上海移动"
        Run_BestTrace "210.21.4.130" "TCP" "30" "广州联通"
        Run_BestTrace "121.14.50.65" "TCP" "30" "广州电信"
        Run_BestTrace "211.139.129.1" "TCP" "30" "广州移动"
        # 美国部分
        Run_BestTrace "173.82.149.19" "TCP" "30" "美国洛杉矶-Cloudcone [MultaCom机房]"
        Run_BestTrace "162.212.59.219" "TCP" "30" "美国达拉斯-SubnetLabs [Incero机房]"
        Run_BestTrace "198.55.111.55" "TCP" "30" "美国洛杉矶-QuadraNet [QuadraNet机房]"
        Run_BestTrace "23.95.99.2" "TCP" "30" "美国新泽西-ColoCrossing [ColoCrossing机房]"
        Run_BestTrace "94.158.244.1" "TCP" "30" "美国俄勒冈-MivoCloud"
        Run_BestTrace "209.141.32.12" "TCP" "30" "美国拉斯维加斯-BuyVM [Cogentco机房]"
        Run_BestTrace "185.215.227.1" "TCP" "30" "美国达拉斯-LetBox [GTT机房]"
        Run_BestTrace "speedtest-sfo2.digitalocean.com" "TCP" "30" "美国旧金山-DigitalOcean SFO2"
        Run_BestTrace "lax-ca-us-ping.vultr.com" "TCP" "30" "美国洛杉矶-Vultr"
        Run_BestTrace "nj-us-ping.vultr.com" "TCP" "30" "美国新泽西-Vultr"
        Run_BestTrace "23.224.2.1" "TCP" "30" "美国洛杉矶-CeraNetworks"
        # 欧洲部分
        Run_BestTrace "84.200.17.54" "TCP" "30" "德国法兰克福-acclerated.de"
        Run_BestTrace "speedtest-fra1.digitalocean.com" "TCP" "30" "德国法兰克福-DigitalOcean FRA1"
        Run_BestTrace "195.201.65.92" "TCP" "30" "德国法兰克福-Hetzener"
        Run_BestTrace "149.202.203.96" "TCP" "30" "法国-OVH"
        Run_BestTrace "77.78.107.117" "TCP" "30" "捷克-FinalTek"
        Run_BestTrace "77.55.224.12" "TCP" "30" "波兰华沙-Nazwa.pl"
        # 日本部分
        Run_BestTrace "210.140.10.72" "TCP" "30" "日本东京-IDCF"
        Run_BestTrace "202.5.222.221" "TCP" "30" "日本大阪-XTOM"
        Run_BestTrace "hnd-jp-ping.vultr.com" "TCP" "30" "日本东京-Vultr"
        # 韩国部分
        Run_BestTrace "168.126.63.1" "TCP" "30" "韩国首尔KT"
        Run_BestTrace "58.120.136.1" "TCP" "30" "韩国首尔SKBroadBand"
        Run_BestTrace "uplus.co.kr" "TCP" "30" "韩国首尔LG"
        # 香港部分
        Run_BestTrace "42.200.128.126" "TCP" "30" "香港HKT-42段"
        Run_BestTrace "58.152.66.77" "TCP" "30" "香港HKT-58段"
        Run_BestTrace "61.238.140.253" "TCP" "30" "香港HKBN"
        Run_BestTrace "118.140.65.194" "TCP" "30" "香港HGC"
        # 台湾部分
        Run_BestTrace "211.22.184.1" "TCP" "30" "台湾HiNet"
        Run_BestTrace "210.203.22.27" "TCP" "30" "台湾APTG"
        Run_BestTrace "175.98.130.15" "TCP" "30" "台湾TWMBroadBand"
        Run_BestTrace "103.51.140.34" "TCP" "30" "台湾Chief"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> 路由追踪测试 (IPV6)${Font_Suffix}\n"
        Run_BestTrace6 "2408:80f0:4100:2005::3" "ICMP" "30" "北京联通-IPV6"
        Run_BestTrace6 "240e:0:a::c9:1cb4" "ICMP" "30" "北京电信-IPV6"
        Run_BestTrace6 "2409:8080:0:2:103:1b1:0:1" "ICMP" "30" "北京移动-IPV6"
        Run_BestTrace6 "2001:da8:a0:1001::1" "ICMP" "30" "北京教育网CERNET2-IPV6"
        Run_BestTrace6 "100ge10-2.core1.hkg1.he.net" "ICMP" "30" "香港HE-IPV6"
        Run_BestTrace6 "100ge11-2.core1.tyo1.he.net" "ICMP" "30" "日本东京HE-IPV6"
        Run_BestTrace6 "100ge2-2.core1.lax1.he.net" "ICMP" "30" "美国洛杉矶HE-IPV6"
        Run_BestTrace6 "100ge13-1.core1.nyc4.he.net" "ICMP" "30" "美国纽约州HE-IPV6"
        Run_BestTrace6 "100ge7-2.core1.fra1.he.net" "ICMP" "30" "德国法兰克福HE-IPV6"
    fi
}

Function_SpooferTest() {
    if [ "${Var_SpooferDisabled}" = "1" ]; then
        return 0
    fi
    echo -e "\n ${Font_Yellow}-> Spoofer测试${Font_Suffix}\n"
    Check_Spoofer
    mkdir /tmp/.LBench_tmp/ >/dev/null
    echo -e "正在运行Spoofer测试，请耐心等待..."
    sleep 2
    /usr/sbin/spoofer-prober -s0 -r0 | tee -a /tmp/.LBench_tmp/spoofer.log
    if [ "$?" = "0" ]; then
        echo -e "\nSpoofer测试结果：$(cat /tmp/.LBench_tmp/spoofer.log | awk '/https:\/\/spoofer/{print $1}' | awk 'NR==2')"
    else
        echo -e "\nSpoofer测试失败! 请使用 cat /tmp/.LBench_tmp/spoofer.log 查看日志!"
    fi
    rm -rf /tmp/.LBench_tmp/spoofer.log
}

# =============== SysBench - CPU性能 部分 ===============
Run_SysBench_CPU() {
    # 调用方式: Run_SysBench_CPU "线程数" "测试时长(秒)" "测试遍数" "说明"
    # 变量初始化
    maxtestcount="$3"
    local count="1"
    local TestScore="0"
    local TotalScore="0"
    # 运行测试
    while [ $count -le $maxtestcount ]
    do
        echo -e "\r ${Font_Yellow}$4:${Font_Suffix}\t$count/$maxtestcount \c"
        local TestResult="$(sysbench --test=cpu --num-threads=$1 --cpu-max-prime=10000 --max-requests=1000000 --max-time=$2 run)"
        local TestScore="$(echo ${TestResult} | grep -oE "total number of events: [0-9]+" | grep -oE "[0-9]+")"
        local TestScoreAvg="$(echo ${TestScore} $2 | awk '{printf "%d",$1/$2}')"
        let TotalScore=TotalScore+TestScoreAvg
        let count=count+1
        local TestResult=""
        local TestScore="0"
    done
    ResultScore="$(echo "${TotalScore} ${maxtestcount}" | awk '{printf "%d",$1/$2}')"
    echo -e "\r ${Font_Yellow}$4:${Font_Suffix}\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}分${Font_Suffix}"
}

Function_SysBench_CPU_Fast() {
    echo -e "\n ${Font_Yellow}-> CPU性能测试 (快速模式, 1-Pass @ 5sec)${Font_Suffix}\n"
    Run_SysBench_CPU "1" "5" "1" "1 线程测试"
    if [ "${LBench_Result_CPUThreadNumber}" != "1" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUThreadNumber}" "5" "1" "${LBench_Result_CPUThreadNumber} 线程测试"
    fi
}

Function_SysBench_CPU_Full() {
    echo -e "\n ${Font_Yellow}-> CPU性能测试 (完整模式, 3-Pass @ 30sec)${Font_Suffix}\n"
    Run_SysBench_CPU "1" "30" "3" "1 线程测试"
    if [ "${LBench_Result_CPUThreadNumber}" != "1" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUThreadNumber}" "30" "3" "${LBench_Result_CPUThreadNumber} 线程测试"
    fi
}

# =============== SysBench - 内存性能 部分 ===============
Run_SysBench_Memory() {
    # 调用方式: Run_SysBench_Memory "线程数" "测试时长(秒)" "测试遍数" "测试模式(读/写)" "读写方式(顺序/随机)" "说明"
    # 变量初始化
    maxtestcount="$3"
    local count="1"
    local TestScore="0.00"
    local TestSpeed="0.00"
    local TotalScore="0.00"
    local TotalSpeed="0.00"
    # 运行测试
    while [ $count -le $maxtestcount ]
    do
        echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t$count/$maxtestcount \c"
        local TestResult="$(sysbench --test=memory --num-threads=$1 --memory-total-size=1000000M --memory-oper=$4 --max-time=$2 --memory-access-mode=$5 run)"
        local TestScore="$(echo "${TestResult}" | grep -i "Operations performed:" | grep -oE "[0-9]+\.[0-9]+")"
        local TestSpeed="$(echo "${TestResult}" | grep -i "MB transferred" | grep -oE "[0-9]+\.[0-9]+" | sed -n "2p")"
        local TotalScore="$(echo "${TotalScore} ${TestScore}" | awk '{printf "%.2f",$1+$2}')"
        local TotalSpeed="$(echo "${TotalSpeed} ${TestSpeed}" | awk '{printf "%.2f",$1+$2}')"
        let count=count+1
        local TestResult=""
        local TestScore="0.00"
        local TestSpeed="0.00"
    done
    ResultScore="$(echo "${TotalScore} ${maxtestcount} 1000" | awk '{printf "%.2f",$1/$2/$3}')"
    ResultSpeed="$(echo "${TotalSpeed} ${maxtestcount}" | awk '{printf "%.2f",$1/$2}')"
    echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t${Font_SkyBlue}${ResultScore}K${Font_Suffix} ${Font_Yellow}ops${Font_Suffix} (${Font_SkyBlue}${ResultSpeed}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix})"
}

Function_SysBench_Memory_Fast() {
    echo -e "\n ${Font_Yellow}-> 内存性能测试 (快速模式, 1-Pass @ 5sec)${Font_Suffix}\n"
    Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "5" "1" "read" "seq" "${LBench_Result_CPUThreadNumber} 线程测试-顺序读"
    Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "5" "1" "read" "seq" "${LBench_Result_CPUThreadNumber} 线程测试-顺序写"
    Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "5" "1" "write" "rnd" "${LBench_Result_CPUThreadNumber} 线程测试-随机读"
    Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "5" "1" "write" "rnd" "${LBench_Result_CPUThreadNumber} 线程测试-随机写"
}

Function_SysBench_Memory_Full() {
    echo -e "\n ${Font_Yellow}-> 内存性能测试 (标准模式, 3-Pass @ 30sec)${Font_Suffix}\n"
    Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "30" "3" "read" "seq" "${LBench_Result_CPUThreadNumber} 线程测试-顺序读"
    Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "30" "3" "read" "seq" "${LBench_Result_CPUThreadNumber} 线程测试-顺序写"
    Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "30" "3" "write" "rnd" "${LBench_Result_CPUThreadNumber} 线程测试-随机读"
    Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "30" "3" "write" "rnd" "${LBench_Result_CPUThreadNumber} 线程测试-随机写"
}

# =============== 检查 Virt-what 组件 ===============
Check_Virtwhat() {
    if [ ! -f "/usr/sbin/virt-what" ]; then
        SystemInfo_GetOSRelease
        if [ "${Var_OSRelease}" = "centos" ]; then
            echo -e "${Msg_Warning}未检测到Virt-What模块，正在安装..."
            yum -y install virt-what
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}未检测到Virt-What模块，正在安装..."
            apt-get install -y virt-what
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}未检测到Virt-What模块，正在安装..."
            dnf -y install virt-what
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}未检测到Virt-What模块，正在安装..."
            apk update
            apk add virt-what
        else
            echo -e "${Msg_Warning}未检测到Virt-What模块，但无法确定当前系统分支!"
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/sbin/virt-what" ]; then
        echo -e "Virt-What模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

# =============== 检查 Speedtest 组件 ===============
Check_Speedtest() {
    speedtest --version >/dev/null 2>&1
    if [ "$?" != "0" ]; then
        SystemInfo_GetOSRelease
        if [ "${Var_OSRelease}" = "centos" ]; then
            echo -e "${Msg_Warning}未检测到Speedtest模块，正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            yum -y install epel-release
            yum -y install python-pip
            echo -e "${Msg_Info}正在安装Speedtest模块 ..."
            pip install speedtest-cli
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}未检测到Speedtest模块，正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apt-get update
            apt-get --no-install-recommends -y install python-pip
            echo -e "${Msg_Info}正在安装Speedtest模块 ..."
            pip install speedtest-cli
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}未检测到Speedtest模块，正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            dnf -y install python-pip
            echo -e "${Msg_Info}正在安装Speedtest模块 ..."
            pip install speedtest-cli
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}未检测到Speedtest模块，正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apk update
            apk add py2-pip
            echo -e "${Msg_Info}正在安装Speedtest模块 ..."
            pip install speedtest-cli
        else
            echo -e "${Msg_Warning}未检测到Speedtest模块，但无法确定当前系统分支!"
        fi      
    fi
    # 二次检测
    speedtest --version >/dev/null
    if [ "$?" != "0" ]; then
        echo -e "Speedtest模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

# =============== 检查 BestTrace 组件 ===============
Check_BestTrace() {
    if [ ! -f "/usr/sbin/besttrace" ]; then
        SystemInfo_GetOSRelease
        mkdir -p /tmp/.LBench_tmp/
        if [ "${Var_OSRelease}" = "centos" ]; then
            echo -e "${Msg_Warning}未检测到BestTrace模块，正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            yum -y install curl unzip
            echo -e "${Msg_Info}正在下载BestTrace组件 ..."
            curl https://lemonbench.download.ilemonrain.com/BestTrace/besttrace -o /tmp/.LBench_tmp/besttrace
            echo -e "${Msg_Info}正在安装BestTrace组件 ..."
            mv /tmp/.LBench_tmp/besttrace /usr/sbin/besttrace
            chmod +x /usr/sbin/besttrace
            echo -e "${Msg_Info}正在清理环境 ..."
            rm -rf /tmp/.LBench_tmp/besttrace
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}未检测到BestTrace模块，正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apt-get update
            apt-get --no-install-recommends -y install wget unzip curl ca-certificates
            echo -e "${Msg_Info}正在下载BestTrace组件 ..."
            curl https://lemonbench.download.ilemonrain.com/BestTrace/besttrace -o /tmp/.LBench_tmp/besttrace
            echo -e "${Msg_Info}正在安装BestTrace组件 ..."
            mv /tmp/.LBench_tmp/besttrace /usr/sbin/besttrace
            chmod +x /usr/sbin/besttrace
            echo -e "${Msg_Info}正在清理环境 ..."
            rm -rf /tmp/.LBench_tmp/besttrace
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}未检测到BestTrace模块，正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            dnf -y install wget unzip curl
            echo -e "${Msg_Info}正在下载BestTrace组件 ..."
            curl https://lemonbench.download.ilemonrain.com/BestTrace/besttrace -o /tmp/.LBench_tmp/besttrace
            echo -e "${Msg_Info}正在安装BestTrace组件 ..."
            mv /tmp/.LBench_tmp/besttrace /usr/sbin/besttrace
            chmod +x /usr/sbin/besttrace
            echo -e "${Msg_Info}正在清理环境 ..."
            rm -rf /tmp/.LBench_tmp/besttrace
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}未检测到BestTrace模块，正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apk update
            apk add wget unzip curl
            echo -e "${Msg_Info}正在下载BestTrace组件 ..."
            curl https://lemonbench.download.ilemonrain.com/BestTrace/besttrace -o /tmp/.LBench_tmp/besttrace
            echo -e "${Msg_Info}正在安装BestTrace组件 ..."
            mv /tmp/.LBench_tmp/besttrace /usr/sbin/besttrace
            chmod +x /usr/sbin/besttrace
            echo -e "${Msg_Info}正在清理环境 ..."
            rm -rf /tmp/.LBench_tmp/besttrace
        else
            echo -e "${Msg_Warning}未检测到BestTrace模块，但无法确定当前系统分支!"
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/sbin/besttrace" ]; then
        echo -e "BestTrace模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

# =============== 检查 Spoofer 组件 ===============
Check_Spoofer() {
    # 如果是快速模式启动，则跳过Spoofer相关检查及安装
    if [ "${Global_TestMode}" = "fast" ]; then
        return 0
    fi
    # 检测是否存在已安装的Spoofer模块
    if [ -f "/usr/sbin/spoofer-prober" ]; then
        return 0
    else
        echo -e "${Msg_Warning}未检测到Spoofer模块，正在安装..."
        Check_Spoofer_PreBuild
    fi
    # 如果预编译安装失败了，则开始编译安装
    if [ ! -f "/usr/sbin/spoofer-prober" ]; then
        echo -e "${Msg_Warning}Spoofer模块预编译安装失败，正在尝试编译安装 ..."
        Check_Spoofer_InstantBuild
    fi
    # 如果编译安装仍然失败，则停止运行
    if [ ! -f "/usr/sbin/spoofer-prober" ]; then
        echo -e "${Msg_Error}Spoofer模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

Check_Spoofer_PreBuild() {
    # 获取系统信息
    SystemInfo_GetOSRelease
    SystemInfo_GetSystemBit
    # 判断CentOS分支
    if [ "${Var_OSRelease}" = "centos" ]; then
        local SysRel="centos"
        # 判断系统位数
        if [ "${LBench_Result_SystemBit}" = "i386" ]; then
            local SysBit="i386"
        elif [ "${LBench_Result_SystemBit}" = "x86_64" ]; then
            local SysBit="x86_64"
        else
            local SysBit="unknown"
        fi
        # 判断版本号
        if [ "${Var_CentOSELRepoVersion}" = "6" ]; then
            local SysVer="6"
        elif [ "${Var_CentOSELRepoVersion}" = "7" ]; then
            local SysVer="7"
        else
            local SysVer="unknown"
        fi
    # 判断Debian分支
    elif [ "${Var_OSRelease}" = "debian" ]; then
        local SysRel="debian"
        # 判断系统位数
        if [ "${LBench_Result_SystemBit}" = "i386" ]; then
            local SysBit="i386"
        elif [ "${LBench_Result_SystemBit}" = "x86_64" ]; then
            local SysBit="x86_64"
        else
            local SysBit="unknown"
        fi
        # 判断版本号
        if [ "${Var_OSReleaseVersion_Short}" = "8" ]; then
            local SysVer="9"
        elif [ "${Var_OSReleaseVersion_Short}" = "9" ]; then
            local SysVer="9"
        else
            local SysVer="unknown"
        fi
    # 判断Ubuntu分支
    elif [ "${Var_OSRelease}" = "ubuntu" ]; then
        local SysRel="ubuntu"
        # 判断系统位数
        if [ "${LBench_Result_SystemBit}" = "i386" ]; then
            local SysBit="i386"
        elif [ "${LBench_Result_SystemBit}" = "x86_64" ]; then
            local SysBit="x86_64"
        else
            local SysBit="unknown"
        fi
        # 判断版本号
        if [ "${Var_OSReleaseVersion_Short}" = "14.04" ]; then
            local SysVer="14.04"
        elif [ "${Var_OSReleaseVersion_Short}" = "16.04" ]; then
            local SysVer="16.04"
        elif [ "${Var_OSReleaseVersion_Short}" = "18.04" ]; then
            local SysVer="18.04"
        elif [ "${Var_OSReleaseVersion_Short}" = "18.10" ]; then
            local SysVer="18.10"
        elif [ "${Var_OSReleaseVersion_Short}" = "19.04" ]; then
            local SysVer="19.04"
        else
            local SysVer="unknown"
        fi
    fi
    if [ "${SysBit}" = "unknown" ] || [ "${SysVer}" = "unknown" ]; then
        echo -e "${Msg_Warning}无法确认当前系统的版本号及位数，或目前暂不支持预编译组件！"
    else
        if [ "${SysRel}" = "centos" ]; then
            echo -e "${Msg_Info}检测到系统: ${SysRel} ${SysVer} ${SysBit}"
            echo -e "${Msg_Info}正在安装必需组件 ..."
            yum install -y epel-release
            yum install -y protobuf-devel libpcap-devel openssl-devel traceroute wget
            echo -e "${Msg_Info}正在下载 Spoofer 预编译组件 ..."
            mkdir -p /tmp/_LBench/src/
            wget -O /tmp/_LBench/src/spoofer-prober.tar.gz https://lemonbench.download.ilemonrain.com/Spoofer/${SysRel}/${SysVer}/${SysBit}/spoofer-prober.gz
            echo -e "${Msg_Info}正在安装 Spoofer ..."
            gzip -dN /tmp/_LBench/src/spoofer-prober.tar.gz
            cp -f /tmp/_LBench/src/spoofer-prober /usr/sbin/spoofer-prober
            chmod +x /usr/sbin/spoofer-prober
            echo -e "${Msg_Info}正在清理临时文件 ..."
            rm -f /tmp/_LBench/src/spoofer-prober.tar.gz
            rm -f /tmp/_LBench/src/spoofer-prober
        elif [ "${SysRel}" = "ubuntu" ] || [ "${SysRel}" = "debian" ]; then
            echo -e "${Msg_Info}检测到系统: ${SysRel} ${SysVer} ${SysBit}"
            echo -e "${Msg_Info}正在安装必需组件 ..."
            apt-get update
            apt-get install --no-install-recommends -y ca-certificates libprotobuf-dev libpcap-dev traceroute wget
            echo -e "${Msg_Info}正在下载 Spoofer 预编译组件 ..."
            mkdir -p /tmp/_LBench/src/
            wget -O /tmp/_LBench/src/spoofer-prober.tar.gz https://lemonbench.download.ilemonrain.com/Spoofer/${SysRel}/${SysVer}/${SysBit}/spoofer-prober.gz
            echo -e "${Msg_Info}正在安装 Spoofer ..."
            gzip -dN /tmp/_LBench/src/spoofer-prober.tar.gz
            cp -f /tmp/_LBench/src/spoofer-prober /usr/sbin/spoofer-prober
            chmod +x /usr/sbin/spoofer-prober
            echo -e "${Msg_Info}正在清理临时文件 ..."
            rm -f /tmp/_LBench/src/spoofer-prober.tar.gz
            rm -f /tmp/_LBench/src/spoofer-prober
        else
            echo -e "${Msg_Warning}无法确认当前系统的版本号及位数，或目前暂不支持预编译组件！"
        fi
    fi
}

Check_Spoofer_InstantBuild() {
    SystemInfo_GetOSRelease
    SystemInfo_GetCPUInfo
    if [ "${Var_OSRelease}" = "centos" ]; then
        echo -e "${Msg_Info}已检测到系统: ${Var_OSRelease}"
        echo -e "${Msg_Info}正在准备编译环境 ..."
        yum install -y epel-release
        yum install -y wget make gcc gcc-c++ traceroute openssl-devel protobuf-devel bison flex libpcap-devel
        echo -e "${Msg_Info}正在下载源码包 ..."
        mkdir -p /tmp/_LBench/src/
        wget -qO /tmp/_LBench/src/spoofer.tar.gz https://lemonbench.download.ilemonrain.com/Spoofer/Spoofer.tar.gz
        echo -e "${Msg_Info}正在编译安装 Spoofer ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-1.4.2
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/sbin/spoofer-prober
        echo -e "${Msg_Info}正在清理临时文件 ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
        echo -e "${Msg_Info}已检测到系统: ${Var_OSRelease}"
        echo -e "${Msg_Info}正在准备编译环境 ..."
        apt-get update
        apt-get install -y --no-install-recommends wget gcc g++ make traceroute protobuf-compiler libpcap-dev libprotobuf-dev openssl libssl-dev ca-certificates
        echo -e "${Msg_Info}正在下载源码包 ..."
        mkdir -p /tmp/_LBench/src/
        wget -qO /tmp/_LBench/src/spoofer.tar.gz https://lemonbench.download.ilemonrain.com/Spoofer/Spoofer.tar.gz
        echo -e "${Msg_Info}正在编译安装 Spoofer ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-1.4.2
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/sbin/spoofer-prober
        echo -e "${Msg_Info}正在清理临时文件 ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    elif [ "${Var_OSRelease}" = "fedora" ]; then
        echo -e "${Msg_Info}已检测到系统: ${Var_OSRelease}"
        echo -e "${Msg_Info}正在准备编译环境 ..."
        dnf install -y wget make gcc gcc-c++ traceroute openssl-devel protobuf-devel bison flex libpcap-devel
        echo -e "${Msg_Info}正在下载源码包 ..."
        mkdir -p /tmp/_LBench/src/
        wget -qO /tmp/_LBench/src/spoofer.tar.gz https://lemonbench.download.ilemonrain.com/Spoofer/Spoofer.tar.gz
        echo -e "${Msg_Info}正在编译安装 Spoofer ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-1.4.2
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/sbin/spoofer-prober
        echo -e "${Msg_Info}正在清理临时文件 ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
        echo -e "${Msg_Info}已检测到系统: ${Var_OSRelease}"
        echo -e "${Msg_Info}正在准备编译环境 ..."
        apk update
        apk add traceroute gcc g++ make openssl-dev protobuf-dev libpcap-dev
        echo -e "${Msg_Info}正在下载源码包 ..."
        mkdir -p /tmp/_LBench/src/
        wget -qO /tmp/_LBench/src/spoofer.tar.gz https://lemonbench.download.ilemonrain.com/Spoofer/Spoofer.tar.gz
        echo -e "${Msg_Info}正在编译安装 Spoofer ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-1.4.2
        ./configure && make -j
        cp prober/spoofer-prober /usr/sbin/spoofer-prober
        echo -e "${Msg_Info}正在清理临时文件 ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    else
        echo -e "${Msg_Error}程序不支持当前系统的编译运行！ (目前仅支持 CentOS/Debian/Ubuntu/Fedora/AlpineLinux) "
    fi
}

# =============== 检查 SysBench 组件 ===============
Check_SysBench() {
    if [ ! -f "/usr/bin/sysbench" ]; then
        SystemInfo_GetOSRelease
        if [ "${Var_OSRelease}" = "centos" ]; then
            echo -e "${Msg_Warning}未检测到SysBench模块，正在安装..."
            yum -y install epel-release
            yum -y install sysbench
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}未检测到SysBench模块，正在安装..."
            apt-get install -y sysbench
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}未检测到SysBench模块，正在安装..."
            dnf -y install sysbench
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}未检测到SysBench模块，正在安装..."
            echo -e "${Msg_Warning}SysBench模块目前暂不支持Alpine Linux，正在跳过..."
            Var_Skip_SysBench="1"
        else
            echo -e "${Msg_Warning}未检测到SysBench模块，但无法确定当前系统分支!"
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/bin/sysbench" ] && [ "${Var_OSRelease}" != "alpinelinux" ]; then
        echo -e "SysBench模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

# =============== 全局启动信息 ===============
Global_Startup_Header() {
    echo -e "
 ${Font_Green}#-----------------------------------------------------------#${Font_Suffix}
 ${Font_Green}@${Font_Suffix}   ${Font_Blue}LBench${Font_Suffix} ${Font_Yellow}服务器测试工具${Font_Suffix}  ${Font_SkyBlue}LemonBench${Font_Suffix} ${Font_Yellow}Server Test Toolkit${Font_Suffix}   ${Font_Green}@${Font_Suffix}
 ${Font_Green}#-----------------------------------------------------------#${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Written by${Font_Suffix} ${Font_SkyBlue}iLemonrain${Font_Suffix} ${Font_Blue}<ilemonrain@ilemonrain.com>${Font_Suffix}         ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}My Blog:${Font_Suffix} ${Font_SkyBlue}https://ilemonrain.com${Font_Suffix}                           ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Telegram:${Font_Suffix} ${Font_SkyBlue}https://t.me/ilemonrain${Font_Suffix}                         ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Telegram (For +86 User):${Font_Suffix} ${Font_SkyBlue}https://t.me/ilemonrain_chatbot${Font_Suffix}  ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Telegram Channel:${Font_Suffix} ${Font_SkyBlue}https://t.me/ilemonrain_channel${Font_Suffix}         ${Font_Green}@${Font_Suffix}
 ${Font_Green}#-----------------------------------------------------------#${Font_Suffix}

 Version: ${BuildTime}

 如需反馈BUG，请通过：
 https://t.me/ilemonrain 或 https://t.me/ilemonrain_chatbot
 联系我，谢谢你们的支持！

 使用方法 (任选其一):
 (1) wget -qO- https://ilemonrain.com/download/shell/LemonBench.sh | bash
 (2) curl -fsSL https://ilemonrain.com/download/shell/LemonBench.sh | bash

"
}

# =============== 入口 - 快速测试 (fast) ===============
Entrance_FastBench() {
    Global_TestMode="fast"
    Global_TestModeTips="快速测试"
    Global_StartupInit_Action
    Function_GetSystemInfo
    Function_BenchStart
    Function_ShowSystemInfo
    Function_ShowNetworkInfo
    Function_SysBench_CPU_Fast
    Function_SysBench_Memory_Fast
    Function_DiskTest_Fast
    Function_Speedtest_Fast
    Function_BestTrace_Fast
    Function_BenchFinish    
}

# =============== 入口 - 完全测试 (full) ===============
Entrance_FullBench() {
    Global_TestMode="full"
    Global_TestModeTips="全面测试"
    Global_StartupInit_Action
    Function_GetSystemInfo
    Function_BenchStart
    Function_ShowSystemInfo
    Function_ShowNetworkInfo
    Function_SysBench_CPU_Full
    Function_SysBench_Memory_Full
    Function_DiskTest_Full
    Function_Speedtest_Full
    Function_BestTrace_Full
    Function_SpooferTest
    Function_BenchFinish
}

# =============== 入口 - 仅Speedtest测试-快速模式 (spfast) ===============
Entrance_Speedtest_Fast() {
    Global_TestMode="speedtest-fast"
    Global_TestModeTips="仅Speedtest测试 (快速测试)"
    Function_BenchStart
    Check_Speedtest
    Function_Speedtest_Fast
    Function_BenchFinish
}

# =============== 入口 - 仅Speedtest测试-全面模式 (spfull) ===============
Entrance_Speedtest_Full() {
    Global_TestMode="speedtest-full"
    Global_TestModeTips="仅Speedtest测试 (全面测试)"
    Check_Speedtest
    Function_BenchStart
    Function_Speedtest_Full
    Function_BenchFinish
}

# =============== 入口 - 仅磁盘性能测试-快速模式 (dtfast) ===============
Entrance_DiskTest_Fast() {
    Global_TestMode="disktest-fast"
    Global_TestModeTips="仅磁盘性能测试 (快速测试)"
    Function_BenchStart
    Function_DiskTest_Fast
    Function_BenchFinish
}

# =============== 入口 - 仅磁盘性能测试-全面模式 (dtfull) ===============
Entrance_DiskTest_Full() {
    Global_TestMode="disktest-full"
    Global_TestModeTips="仅磁盘性能测试 (全面测试)"
    Function_BenchStart
    Function_DiskTest_Full
    Function_BenchFinish
}

# =============== 入口 - 仅路由追踪测试-快速模式 (btfast) ===============
Entrance_BestTrace_Fast() {
    Global_TestMode="besttrace-fast"
    Global_TestModeTips="仅路由追踪测试 (快速测试)"
    Check_BestTrace
    Function_BenchStart
    Function_BestTrace_Fast
    Function_BenchFinish
}

# =============== 入口 - 仅路由追踪测试-完全模式 (btfull) ===============
Entrance_BestTrace_Full() {
    Global_TestMode="besttrace-full"
    Global_TestModeTips="仅路由追踪测试 (全面测试)"
    Check_BestTrace
    Function_BenchStart
    Function_BestTrace_Full
    Function_BenchFinish
}

# =============== 入口 - 仅Spoofer测试-快速模式 (spf) ===============
Entrance_Spoofer() {
    Global_TestMode="spoofer"
    Global_TestModeTips="仅Spoofer测试"
    Check_Spoofer
    Function_BenchStart
    Function_SpooferTest
    Function_BenchFinish
}

# 
Entrance_SysBench_CPU_Fast() {
    Global_TestMode="sysbench-cpu-fast"
    Global_TestModeTips="仅CPU性能测试 (快速模式)"
    Check_SysBench
    Function_BenchStart
    SystemInfo_GetCPUInfo
    Function_SysBench_CPU_Fast
    Function_BenchFinish
}

Entrance_SysBench_CPU_Full() {
    Global_TestMode="sysbench-cpu-full"
    Global_TestModeTips="仅CPU性能测试 (标准模式)"
    Check_SysBench
    Function_BenchStart
    SystemInfo_GetCPUInfo
    Function_SysBench_CPU_Full
    Function_BenchFinish
}

#
Entrance_SysBench_Memory_Fast() {
    Global_TestMode="sysbench-memory-fast"
    Global_TestModeTips="仅内存性能测试 (快速模式)"
    Check_SysBench
    Function_BenchStart
    SystemInfo_GetCPUInfo
    Function_SysBench_Memory_Fast
    Function_BenchFinish
}

Entrance_SysBench_Memory_Full() {
    Global_TestMode="sysbench-memory-full"
    Global_TestModeTips="仅内存性能测试 (标准模式)"
    Check_SysBench
    Function_BenchStart
    SystemInfo_GetCPUInfo
    Function_SysBench_Memory_Full
    Function_BenchFinish
}

# =============== 入口 - 帮助文档 (help) ===============
Entrance_HelpDocument() {
    echo -e "\n ${Font_Blue}LBench${Font_Suffix} ${Font_Yellow}服务器测试工具${Font_Suffix}  ${Font_SkyBlue}LemonBench${Font_Suffix} ${Font_Yellow}Server Test Toolkit${Font_Suffix} ${BuildTime}" 
    echo -e "
 > ${Font_Green}帮助文档${Font_Suffix} ${Font_SkyBlue}HelpDocument${Font_Suffix}

 使用方法 Usage ：

 (1) ${Font_SkyBlue}wget -qO- https://ilemonrain.com/download/shell/LemonBench.sh | bash -s${Font_Suffix} ${Font_Yellow}[TestMode]${Font_Suffix}
 (2) ${Font_SkyBlue}curl -fsSL https://ilemonrain.com/download/shell/LemonBench.sh | bash -s${Font_Suffix} ${Font_Yellow}[TestMode]${Font_Suffix}

 可选测试参数 Available Parameters :

   ${Font_SkyBlue}-f${Font_Suffix}, ${Font_SkyBlue}--fast${Font_Suffix}, ${Font_SkyBlue}fast${Font_Suffix} \t\t 执行快速测试
   ${Font_SkyBlue}-F${Font_Suffix}, ${Font_SkyBlue}--full${Font_Suffix}, ${Font_SkyBlue}full${Font_Suffix} \t\t 执行完整测试
   ${Font_SkyBlue}spfast${Font_Suffix}, ${Font_SkyBlue}--speedtest-fast${Font_Suffix} \t 仅执行Speedtest网速测试 (快速测试)
   ${Font_SkyBlue}spfast${Font_Suffix}, ${Font_SkyBlue}--speedtest-fast${Font_Suffix} \t 仅执行Speedtest网速测试 (完整测试)
   ${Font_SkyBlue}dtfast${Font_Suffix}, ${Font_SkyBlue}--disktest-fast${Font_Suffix} \t 仅执行磁盘性能测试 (快速测试)
   ${Font_SkyBlue}dtfast${Font_Suffix}, ${Font_SkyBlue}--disktest-fast${Font_Suffix} \t 仅执行磁盘性能测试 (完整测试)
   ${Font_SkyBlue}btfast${Font_Suffix}, ${Font_SkyBlue}--besttrace-fast${Font_Suffix} \t 仅执行路由追踪测试 (快速测试)
   ${Font_SkyBlue}btfast${Font_Suffix}, ${Font_SkyBlue}--besttrace-full${Font_Suffix} \t 仅执行路由追踪测试 (完整测试)
   ${Font_SkyBlue}spf${Font_Suffix}, ${Font_SkyBlue}--spoofer${Font_Suffix} \t\t 仅执行Spoofer测试
   ${Font_SkyBlue}sbcfast${Font_Suffix}, ${Font_SkyBlue}--sbcfast${Font_Suffix} \t\t 仅执行CPU性能测试 (快速模式)
   ${Font_SkyBlue}sbcfull${Font_Suffix}, ${Font_SkyBlue}--sbcfast${Font_Suffix} \t\t 仅执行CPU性能测试 (标准模式)

    "
    exit 0
}

# =============== 命令行参数 ===============
case "$1" in
    -f|fast|-fast|--fast)
        Entrance_FastBench
        exit 0
        ;;    
    -F|full|-full|--full)
        Entrance_FullBench
        exit 0
        ;;
    spfast|-spfast|--spfast|speedtest-fast|-speedtest-fast|--speedtest-fast)
        Entrance_Speedtest_Fast
        exit 0
        ;;
    spfull|-spfull|--spfull|speedtest-full|-speedtest-full|--speedtest-full)
        Entrance_Speedtest_Full
        exit 0
        ;;
    dtfast|-dtfast|--dtfast|disktest-fast|-disktest-fast|--disktest-fast)
        Entrance_DiskTest_Fast
        exit 0
        ;;
    dtfull|-dtfull|--dtfull|disktest-full|-disktest-full|--disktest-full)
        Entrance_DiskTest_Full
        exit 0
        ;;
    btfast|-btfast|--btfast|besttrace-fast|-besttrace-fast|--besttrace-fast)
        Entrance_BestTrace_Fast
        exit 0
        ;;
    btfull|-btfull|--btfull|besttrace-full|-besttrace-full|--besttrace-full)
        Entrance_BestTrace_Full
        exit 0
        ;;
    spf|-spf|--spf|spoof|-spoof|--spoof|spoofer|-spoofer|--spoofer)
        Entrance_Spoofer
        exit 0
        ;;
    sbcfast|-sbcfast|--sbcfast|sysbench-cpu-fast|-sysbench-cpu-fast|--sysbench-cpu-fast)
        Entrance_SysBench_CPU_Fast
        exit 0
        ;;
    sbcfull|-sbcfull|--sbcfull|sysbench-cpu-full|-sysbench-cpu-full|--sysbench-cpu-full)
        Entrance_SysBench_CPU_Full
        exit 0
        ;;
    sbmfast|-sbmfast|--sbmfast|sysbench-memory-fast|-sysbench-memory-fast|--sysbench-memory-fast)
        Entrance_SysBench_Memory_Fast
        exit 0
        ;;
    sbmfull|-sbmfull|--sbmfull|sysbench-memory-full|-sysbench-memory-full|--sysbench-memory-full)
        Entrance_SysBench_Memory_Full
        exit 0
        ;;
    -h|-H|help|-help|--help)
        Entrance_HelpDocument
        exit 0
        ;;
    *)
        Entrance_HelpDocument
        exit 0
        ;;
esac