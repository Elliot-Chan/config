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
    setopt local_options null_glob extended_glob

    local directories=("$@")
    local idx=1

    # 全局数组，给 ccj 用
    folders_list=()

    # 用来去重（避免同一个目录里有多个 envsetup.sh 的情况）
    typeset -A seen

    for directory in "${directories[@]}"; do
        if [[ -d $directory ]]; then
            echo "---------------------- $directory -------------------------------"

            # 递归查找 envsetup.sh
            # **/envsetup.sh(.N)
            #   **  -> 递归子目录
            #   .   -> 普通文件
            #   N   -> 没匹配就忽略这个模式（不报错）
            local env_files=("$directory"/**/envsetup.sh(.N))

            for env in "${env_files[@]}"; do
                # :h = head，取目录部分
                local sdk_dir=${env:h}

                # 去重一下
                if [[ -n ${seen[$sdk_dir]} ]]; then
                    continue
                fi
                seen[$sdk_dir]=1

                printf '%2d) %s\n' "$idx" "$sdk_dir"
                folders_list+=("$sdk_dir")
                ((idx++))
            done
        else
            echo "目录不存在: $directory"
        fi
    done
}


ccj() {
    setopt local_options no_xtrace
    local param=$1

    local sdk_dirs=(~/cangjie_sdk $HOME/code/dev/cangjie $HOME/code/br_main/cangjie)
    list_folders "${sdk_dirs[@]}"

    if (( ${#folders_list[@]} == 0 )); then
        echo "未找到可用的 Cangjie SDK 目录"
        return 1
    fi

    local choice
    echo "请输入序号选择版本（或输入 dN 删除条目，如 d3 删除第 3 个）："
    read -r choice

    # 删除模式：dN
    if [[ $choice =~ '^d([0-9]+)$' ]]; then
        local n=${match[1]}
        if (( n >= 1 && n <= ${#folders_list[@]} )); then
            local selected_dir=${folders_list[n]}
            echo -n "确认删除目录 '$selected_dir'? [y/N] "
            local confirm
            read -r confirm
            if [[ $confirm == [yY] ]]; then
                rm -rf -- "$selected_dir"
                echo "已删除目录: $selected_dir"
            else
                echo "操作已取消"
            fi
        else
            echo "无效的选择"
        fi
        return
    fi

    # 普通选择：纯数字
    if [[ ! $choice == <-> ]]; then
        echo "无效的选择"
        return 1
    fi

    if (( choice < 1 || choice > ${#folders_list[@]} )); then
        echo "无效的选择"
        return 1
    fi

    local selected_folder=${folders_list[choice]}
    if [[ -n $selected_folder ]]; then
        # 加载环境
        source_envsetup "$selected_folder"

        # 自动探测 stdx
        local lib_type="dynamic"
        if [[ $param == "static" ]]; then
          lib_type="static"
        fi
        local matches=( "$selected_folder"/**/$lib_type/stdx(N/) )
        local base=${selected_folder:t}
        if [[ $base == cangjie ]]; then
          matches=( $(realpath $selected_folder/..)/**/$lib_type/stdx(N/) )
        fi
        (( ${#matches[@]} )) && export CANGJIE_STDX_PATH=$matches[1] && echo "set CANGJIE_STDX_PATH to ${matches[1]}"

        export CANGJIE_SDK_PATH=$selected_folder
        which cjc 2>/dev/null || echo "cjc 未在 PATH 中"
        cjc --version 2>/dev/null || echo "cjc --version 执行失败"
        local pcre2=( ${selected_folder}/**/libpcre2-*(.N) )
        for f in $pcre2; do 
          if [[ ${file:e} != so ]] ; then
              continue
          fi
          local confirm
          echo "是否删除 ${f} (y/N)"
          read -r confirm
          if [[ $confirm == [yY] ]]; then
            rm -- "$f" && echo "成功删除 ${f}"
          fi
        done
    else
        echo "未找到选择的目录"
        return 1
    fi
}
