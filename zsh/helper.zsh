# 彩色终端日志
log_message() {
  local message="$1"
  local color="${2:-default}"
  print -P -- "%F{$color}${message}%f"
}

ERROR()   { log_message "$1" red; }
WARNING() { log_message "$1" yellow; }
INFO()    { log_message "$1" cyan; }
SUCCESS() { log_message "$1" green; }

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
        if [[ $lib_type == "dynamic" && ! -z $CANGJIE_STDX_PATH ]]; then
          export LD_LIBRARY_PATH=$CANGJIE_STDX_PATH:$LD_LIBRARY_PATH
          if [[ -z $CANGJIE_PATH ]]; then
            export CANGJIE_PATH=$CANGJIE_STDX_PATH
          else
            export CANGJIE_PATH=$CANGJIE_STDX_PATH:$CANGJIE_PATH
          fi
        fi
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

cccj() {
    setopt local_options no_xtrace
    local param=$1

    local sdk_dirs=(~/cangjie_sdk $HOME/code/dev/cangjie $HOME/code/br_main/cangjie)
    list_folders "${sdk_dirs[@]}"

    if (( ${#folders_list[@]} == 0 )); then
        echo "未找到可用的 Cangjie SDK 目录"
        return 1
    fi

    local latest_folder=""
    local latest_date=0
    local dir date_str date_num

    for dir in "${folders_list[@]}"; do
        if [[ $dir =~ '([0-9]{8})' ]]; then
            date_str=$match[1]
            date_num=$((10#$date_str))
            if (( date_num > latest_date )); then
                latest_date=$date_num
                latest_folder=$dir
            fi
        fi
    done

    if [[ -z $latest_folder ]]; then
        local latest_ts=0
        local envsetup ts
        for dir in "${folders_list[@]}"; do
            envsetup="$dir/envsetup.sh"
            if [[ -f $envsetup ]]; then
                ts=$(stat -c %Y -- "$envsetup" 2>/dev/null)
            else
                ts=$(stat -c %Y -- "$dir" 2>/dev/null)
            fi
            [[ -z $ts ]] && ts=0
            if (( ts > latest_ts )); then
                latest_ts=$ts
                latest_folder=$dir
            fi
        done
        [[ -n $latest_folder ]] && echo "未找到带日期的 SDK 目录，改用文件时间: $latest_folder"
    fi

    if [[ -z $latest_folder ]]; then
        echo "未找到可用的 Cangjie SDK 目录"
        return 1
    fi

    echo "自动选择最新: $latest_folder"
    source_envsetup "$latest_folder"

    local lib_type="dynamic"
    if [[ $param == "static" ]]; then
      lib_type="static"
    fi
    local matches=( "$latest_folder"/**/$lib_type/stdx(N/) )
    local base=${latest_folder:t}
    if [[ $base == cangjie ]]; then
      matches=( $(realpath $latest_folder/..)/**/$lib_type/stdx(N/) )
    fi
    (( ${#matches[@]} )) && export CANGJIE_STDX_PATH=$matches[1] && echo "set CANGJIE_STDX_PATH to ${matches[1]}"

    export CANGJIE_SDK_PATH=$latest_folder
    which cjc 2>/dev/null || echo "cjc 未在 PATH 中"
    cjc --version 2>/dev/null || echo "cjc --version 执行失败"
    if [[ $param == "dynamic" && $CANGJIE_STDX_PATH ]]; then
      export LD_LIBRARY_PATH=$CANGJIE_STDX_PATH:$LD_LIBRARY_PATH
    fi
    local pcre2=( ${latest_folder}/**/libpcre2-*(.N) )
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
}

cdi() {  # cd-from-stdin
  local input target
  if (( $# > 0 )); then
    input=$1
  else
    IFS= read -r input || return 1
  fi
  [[ -z "$input" ]] && return 1

  target="$input"
  if [[ -d "$target" ]]; then
    cd -- "$target"
    return
  fi

  if [[ -e "$target" ]]; then
    cd -- "${target:h}"
    return
  fi

  if [[ "$target" == */* && -d "${target:h}" ]]; then
    cd -- "${target:h}"
    return
  fi

  print -u2 -- "cdi: no such path: $input"
  return 1
}

copypath() {
  local p
  p="$(realpath "${1:-.}")" || return 1

  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$p" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$p" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$p" | xsel --clipboard --input
  else
    print -u2 -- "no clipboard tool found"
    return 1
  fi

  print -r -- "$p"
}
