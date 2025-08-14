# 彩色终端日志
log_message() {
    local message="$1"
    local color="$2"
    case "$color" in
        "red") color_code="\033[31m" ;;
        "green") color_code="\033[32m" ;;
        "yellow") color_code="\033[33m" ;;
        "blue") color_code="\033[34m" ;;
        "magenta") color_code="\033[35m" ;;
        "cyan") color_code="\033[36m" ;;
        "white") color_code="\033[37m" ;;
        *) color_code="\033[0m" ;;  # 默认颜色
    esac
    echo -e "${color_code}${message}\033[0m"
}

ERROR() {
    log_message "$1" "red"
}

WARNING() {
    log_message "$1" "yellow"
}

INFO() {
    log_message "$1" "cyan"
}

SUCCESS() {
    log_message "$1" "green"
}

invoke_exec() {
    local expr="$1"
    local verbose="$2"

    if  [[ -z $verbose ]]; then
        verbose="true"
    fi

    local cur_dir=$(pwd)

    if [[ $expr =~ "cd " ]]; then
        INFO "Fom dir: $cur_dir"
    fi

    INFO "\n$expr"
    eval $expr

    local ret=$?
    if [[ "$verbose" == "true" || "$verbose" == "line" ]]; then
        printf '%*s' "${COLUMNS:-$(tput cols)}" '' | tr ' ' '-'
    fi
    
    if [[ $ret -ne 0 ]]; then
        ERROR "\n[EXITCODE: $ret] 执行 $expr 失败\n"
        if [[ $expr =~ "cd " ]]; then
            cd $cur_dir
        fi
        return 1
    fi

    if [[ $expr =~ "cd " ]]; then
        cd $cur_dir
    fi

    if [[ "$verbose" == "true" ]]; then
        SUCCESS "$expr 执行成功"
    fi
    return 0
}

source_envsetup() {
    local folder=$1
    local envsetup_path="$folder/envsetup.sh"

    if [[ -f $envsetup_path ]]; then
        invoke_exec "source $envsetup_path"
    else
        echo "未找到 envsetup.sh 文件: $envsetup_path"
    fi
}

list_folders() {
    local directories=("$@")
    local idx=1
    folders_list=()
    for directory in "${directories[@]}"; do
        if [[ -d $directory ]]; then
            echo ---------------------- $directory -------------------------------    
            for folder in "$directory"/*(/); do
                if [[ -f "$folder/envsetup.sh" ]]; then
                    echo "$idx) $folder"
                    folders_list+=("$folder")
                    ((idx++))
                fi
            done
        else
            echo "目录不存在: $directory"
        fi
    done
}

ccj() {
    local sdk_dirs=(~/cangjie_sdk $HOME/code/dev/cangjie $HOME/code/br_main/cangjie)
    list_folders "${sdk_dirs[@]}"

    local choice
    echo "请输入序号选择版本："

    read -r choice

    if [[ $choice =~ ^d([0-9]+)$ ]]; then
        local n=${match[1]}
        if ((n >=1 && n <= ${#folders_list[@]})); then
            local selected_dir="${folders_list[$(n)]}"
            echo -n "确认删除 '$target_folder'? [y/N]"
            read -r confirm
            if [[ $confirm == "y" || $confirm == "Y" ]]; then
                rm -rf "$selected_dir"
                echo "已删除目录: $selected_dir"
            else
                echo "操作已取消"
            fi
        else
            echo "无效的选择"
        fi
        return
    fi

    if ((choice < 1 || choice > ${#folders_list[@]})); then
            echo "无效的选择"
            return
    fi

    local selected_folder=${folders_list[$((choice))]}
    if [[ -n $selected_folder ]]; then
        source_envsetup $selected_folder
        which cjc
        cjc --version
    else
        echo "未找到选择的目录"
    fi
}
