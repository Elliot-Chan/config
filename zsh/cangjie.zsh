#!/usr/bin/env zsh

# Cangjie Build System Functions with Isolated Single-Component Builds
# Version: 2.1.0

# 配置变量 (主Shell中定义，子Shell会继承拷贝)
typeset -gA CANGJIE_CONFIG=(
    [workspace]="$HOME/Code/working"
    [build_type]="relwithdebinfo"
    [kernel]="linux"
    [cmake_arch]="x86_64"
    [mingw_path]="${MINGW_PATH}"
    [build_compiler]="true"
    [build_runtime]="true"
    [build_std]="true"
    [build_stdx]="true"
    [build_tools]="true"
    [build_cjdb]="false"
    [clean_build]="false"
    [build_version]="1.0.0"
    [set_rpath]="true"
    [compiler_path]="/usr/lib/llvm15/bin"
    [output]="$HOME/cangjie_sdk"
)

function cangjie::_is_windows() {
    [[ "${kernel}" == "windows" ]]
}

function cangjie::_require_mingw() {
    if [[ -z "${MINGW_PATH:-}" ]]; then
        echo "❌ MINGW_PATH not set"
        return 1
    fi
}

function cangjie::_cpu_jobs() {
    local jobs=""
    if command -v nproc >/dev/null 2>&1; then
        jobs=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        jobs=$(sysctl -n hw.ncpu 2>/dev/null)
    fi
    if [[ -z "${jobs}" || "${jobs}" -lt 1 ]]; then
        jobs=1
    fi
    echo "${jobs}"
}

function cangjie::_run_in_subshell() {
   local task=$1
    (
        set -e
        cangjie::_init  # 初始化子Shell环境
        
        case $task in
            compiler)     cangjie::_build_compiler ;;
            runtime)      cangjie::_build_runtime ;;
            std)          cangjie::_build_std $2 ;;
            stdx)         cangjie::_build_stdx $2 ;;
            basic)        cangjie::_build_basic ;;
            tool_lsp)     cangjie::_build_tool_lsp ;;
            tool_cjpm)    cangjie::_build_tool_cjpm ;;
            tool_cjfmt)   cangjie::_build_tool_cjfmt ;;
            tool_hle)     cangjie::_build_tool_hle ;;
            tools)        cangjie::_build_tools ;;
            ninja)        cangjie::_build_ninja $2 ;;
            *)            echo "❌ Unknown build target"; return 1 ;;
        esac
        
        echo "✅ $task built successfully in isolated environment"
    )
}

# 初始化构建环境 (在子Shell中运行)
function cangjie::_init() {
    # 这些变量仅在子Shell中有效
    export WORKSPACE=${CANGJIE_CONFIG[workspace]}
    export build_type=${CANGJIE_CONFIG[build_type]}
    export build_version=${CANGJIE_CONFIG[build_version]}
    export kernel=${CANGJIE_CONFIG[kernel]}
    export cmake_arch=${CANGJIE_CONFIG[cmake_arch]}
    export OPENSSL_PATH=${CANGJIE_CONFIG[openssl_path]}
    export AddOptsBuildpy=${CANGJIE_CONFIG[build_cjdb]:+"--build-cjdb"}
    export RPATH=${CANGJIE_CONFIG[set_rpath]:+"--set-rpath \$RPATH"}
    export PATH=${CANGJIE_CONFIG[compiler_path]}:$PATH
    export cangjie_sdk_path=${CANGJIE_CONFIG[output]}
    if [[ -n "${CANGJIE_CONFIG[mingw_path]}" ]]; then
        export MINGW_PATH="${CANGJIE_CONFIG[mingw_path]}"
    fi
    local clang_bin="/usr/lib/llvm15/bin/clang"
    local clangxx_bin="/usr/lib/llvm15/bin/clang++"
    if command -v ccache >/dev/null 2>&1; then
        export CC="ccache ${clang_bin}"
        export CXX="ccache ${clangxx_bin}"
    else
        export CC="${clang_bin}"
        export CXX="${clangxx_bin}"
    fi
}

function cangjie::_prepare_compiler_tree() {
    cd ${WORKSPACE}/cangjie_compiler || return 1
    mkdir -p build/build/utils_dep && cd build/build/utils_dep && rm -rf third_party_llvm-project || sleep 1
    ln -s $HOME/Code/CJ/third_party_llvm-project || sleep 1
    # git pull --rebase || return 1

    cd ${WORKSPACE}/cangjie_compiler || return 1

    mkdir -p third_party && cd third_party && rm -rf llvm-project
    ln -s $HOME/Code/CJ/llvm-project || sleep 1
    cd llvm-project || return 1
    # git pull --rebase || return 1

    cd ${WORKSPACE}/cangjie_compiler || return 1
}

# 构建编译器 (子Shell中运行)
function cangjie::_build_compiler() {
    [[ ${CANGJIE_CONFIG[build_compiler]} != "true" ]] && return

    echo "🚀 Building Cangjie Compiler..."

    if cangjie::_is_windows; then
        cangjie::_build_compiler_windows
    else
        cangjie::_build_compiler_linux
    fi
}

function cangjie::_build_compiler_linux() {
    cangjie::_prepare_compiler_tree || return 1

    local install_dir="${cangjie_sdk_path}/${kernel}_${build_type}_${cmake_arch}"
    local jobs
    jobs="$(cangjie::_cpu_jobs)"
    [[ ${CANGJIE_CONFIG[clean_build]} == "true" ]] && python3 build.py clean
    python3 build.py build -t ${build_type} ${AddOptsBuildpy} --no-tests --jobs ${jobs} \
    && python3 build.py install --prefix ${install_dir} \
    && echo "🎉 Install cjc to ${install_dir}"
}

function cangjie::_build_compiler_windows() {
    cangjie::_require_mingw || return 1
    cangjie::_prepare_compiler_tree || return 1

    local win_target="windows-x86_64"
    local install_dir="${cangjie_sdk_path}/${kernel}_${build_type}_${cmake_arch}"
    export CMAKE_PREFIX_PATH="${MINGW_PATH}/x86_64-w64-mingw32"
    [[ ${CANGJIE_CONFIG[clean_build]} == "true" ]] && python3 build.py clean
    python3 build.py build -t ${build_type} --product cjc --no-tests \
      --target ${win_target} --target-sysroot ${MINGW_PATH}/ \
      --target-toolchain ${MINGW_PATH}/bin ${AddOptsBuildpy} \
    && python3 build.py build -t ${build_type} --product libs \
      --target ${win_target} --target-sysroot ${MINGW_PATH}/ \
      --target-toolchain ${MINGW_PATH}/bin \
    && python3 build.py install --host ${win_target} --prefix ${install_dir} \
    && python3 build.py install --prefix ${install_dir} \
    && cp -rf output-x86_64-w64-mingw32/* output
}

# 构建运行时 (子Shell中运行)
function cangjie::_build_runtime() {
    [[ ${CANGJIE_CONFIG[build_runtime]} != "true" ]] && return

    echo "🚀 Building Cangjie Runtime..."

    if cangjie::_is_windows; then
        cangjie::_build_runtime_windows
    else
        cangjie::_build_runtime_linux
    fi
}

function cangjie::_build_runtime_linux() {
    cd ${WORKSPACE}/cangjie_runtime/runtime || return 1
    mkdir -p target

    local install_dir="${cangjie_sdk_path}/${kernel}_${build_type}_${cmake_arch}"

    [[ ${CANGJIE_CONFIG[clean_build]} == "true" ]] && python3 build.py clean
    python3 build.py build -t ${build_type} -v ${build_version} \
    && python3 build.py install

    local runtime_output_dir="${WORKSPACE}/cangjie_runtime/runtime/output/common/${kernel}_${build_type}_${cmake_arch}"

    [[ -d "${runtime_output_dir}" ]] || { echo "❌ Runtime dir missing"; return 1 }
    invoke_exec "cp -rf ${WORKSPACE}/cangjie_runtime/runtime/output/* target"
    invoke_exec "cp -rf ${runtime_output_dir}/{lib,runtime} ${install_dir}"
}

function cangjie::_build_runtime_linux_for_windows() {
    local saved_kernel="${kernel}"
    kernel="linux"
    cangjie::_build_runtime_linux
    local rc=$?
    kernel="${saved_kernel}"
    return ${rc}
}

function cangjie::_build_runtime_windows() {
    cangjie::_require_mingw || return 1
    cangjie::_build_runtime_linux_for_windows || return 1
    cd ${WORKSPACE}/cangjie_runtime/runtime || return 1
    mkdir -p target

    [[ ${CANGJIE_CONFIG[clean_build]} == "true" ]] && python3 build.py clean
    python3 build.py build -t ${build_type} --target windows-x86_64 \
      --target-toolchain ${MINGW_PATH}/bin -v ${build_version} \
    && python3 build.py install

    local runtime_output_dir="${WORKSPACE}/cangjie_runtime/runtime/output/common/windows_${build_type}_${cmake_arch}"
    [[ -d "${runtime_output_dir}" ]] || { echo "❌ Runtime dir missing"; return 1 }
    cp -rf ${WORKSPACE}/cangjie_runtime/runtime/output/* target
    cp -rf "${runtime_output_dir}"/{lib,runtime} "${WORKSPACE}/cangjie_compiler/output"
    cp -rf "${runtime_output_dir}"/{lib,runtime} "${WORKSPACE}/cangjie_compiler/output-x86_64-w64-mingw32"
}

# 构建标准库 (子Shell中运行) 
function cangjie::_build_std() {
    [[ ${CANGJIE_CONFIG[build_std]} != "true" ]] && return

    if [[ -z $(command -v cjc) ]]; then
      ERROR "cjc not found"
      return
    fi

    echo "🚀 Building Cangjie Standard Library..."

    if cangjie::_is_windows; then
      cangjie::_build_std_windows
    else
      cangjie::_build_std_linux
    fi
}

function cangjie::_build_std_linux() {
    cd ${WORKSPACE}/cangjie_runtime/stdlib || return 1
    local jobs
    jobs="$(cangjie::_cpu_jobs)"
    [[ ${CANGJIE_CONFIG[clean_build]} == "true" ]] && python3 build.py clean
    invoke_exec "python3 build.py build -j ${jobs} -t ${build_type} --target-lib ${WORKSPACE}/cangjie_runtime/runtime/output/ --build-args='-Woff=all' && python3 build.py install"

    local install_dir="${cangjie_sdk_path}/${kernel}_${build_type}_${cmake_arch}"
    invoke_exec "cp -rf ${WORKSPACE}/cangjie_runtime/stdlib/output/* ${install_dir}"
    echo "🎉 Install std to ${install_dir}"
}

function cangjie::_build_std_windows() {
    cangjie::_require_mingw || return 1
    cd ${WORKSPACE}/cangjie_runtime/stdlib || return 1
    local jobs
    jobs="$(cangjie::_cpu_jobs)"
    [[ ${CANGJIE_CONFIG[clean_build]} == "true" ]] && python3 build.py clean
    invoke_exec "python3 build.py build -j ${jobs} -t ${build_type} --target windows-x86_64 --target-lib=${WORKSPACE}/cangjie_runtime/runtime/target --target-lib=${MINGW_PATH}/x86_64-w64-mingw32/lib --target-sysroot ${MINGW_PATH}/ --target-toolchain ${MINGW_PATH}/bin && python3 build.py install"

    invoke_exec "cp -rf ${WORKSPACE}/cangjie_runtime/stdlib/output/* ${WORKSPACE}/cangjie_compiler/output/"
    invoke_exec "cp -rf ${WORKSPACE}/cangjie_runtime/stdlib/output/* ${WORKSPACE}/cangjie_compiler/output-x86_64-w64-mingw32/"
}

# 构建STDX扩展库 (子Shell中运行)
function cangjie::_build_stdx() {
    [[ ${CANGJIE_CONFIG[build_stdx]} != "true" ]] && return

    if [[ -z $(command -v cjc) ]]; then
      ERROR "cjc not found"
      source /home/elliot/cangjie_sdk/linux_relwithdebinfo_x86_64/envsetup.sh
    fi

    if cangjie::_is_windows; then
      cangjie::_build_stdx_windows
    else
      cangjie::_build_stdx_linux "$@"
    fi
}

function cangjie::_build_stdx_linux() {
    local package=$1
    local install_dir="${cangjie_sdk_path}/${kernel}_${build_type}_${cmake_arch}"
    local modules_dir=${install_dir}/modules/linux_x86_64_cjnative/stdx
    if [[ -n "$package" ]]; then
      cd ${WORKSPACE}/cangjie_stdx/build_temp/build || return 1
      ninja $package && ninja install 
    else
      echo "🚀 Building Cangjie STDX Extension..."
      cd ${WORKSPACE}/cangjie_stdx || return 1
      [[ ${CANGJIE_CONFIG[clean_build]} == "true" ]] && python3 build.py clean
      invoke_exec "python3 build.py build -t ${build_type} --include=${WORKSPACE}/cangjie_compiler/include && python3 build.py install --prefix ${install_dir}" || return -1
      echo "🎉 Install stdx to ${install_dir}/${kernel}_${cmake_arch}_cjnative/{dynamic/static}/stdx"
      # cp -rf ${install_dir}/${kernel}_${cmake_arch}_cjnative/**/dynamic/**/**.{cjo,bc} $modules_dir
      # mv -f $modules_dir/{libstdx.bc,stdx.cjo} $modules_dir/../
    fi
    set CANGJIE_STDX_DYNAMIC_PATH = ${install_dir}/${kernel}_${cmake_arch}_cjnative/dynamic/stdx
    set CANGJIE_STDX_DYNAMIC_PATH = ${install_dir}/${kernel}_${cmake_arch}_cjnative/static/stdx
    set CANGJIE_STDX_PATH = ${install_dir}/${kernel}_${cmake_arch}_cjnative/\{dynamic/static\}/stdx
}

function cangjie::_build_stdx_windows() {
    cangjie::_require_mingw || return 1
    echo "🚀 Building Cangjie STDX Extension (windows)..."
    cd ${WORKSPACE}/cangjie_stdx || return 1
    [[ ${CANGJIE_CONFIG[clean_build]} == "true" ]] && python3 build.py clean
    invoke_exec "python3 build.py build -t ${build_type} --include=${WORKSPACE}/cangjie_compiler/include --target-lib=${MINGW_PATH}/x86_64-w64-mingw32/lib --target windows-x86_64 --target-sysroot ${MINGW_PATH}/ --target-toolchain ${MINGW_PATH}/bin && python3 build.py install" || return -1
    export CANGJIE_STDX_PATH="${WORKSPACE}/cangjie_stdx/target/windows_x86_64_cjnative/static/stdx"
}

# 构建工具集 (子Shell中运行)
function cangjie::_build_tool_lsp() {
    [[ ${CANGJIE_CONFIG[build_tools]} != "true" ]] && return
    while [[ -z $(command -v cjc) ]]; do
      echo "cjc not found"
      return
    done

    echo "🚀 Building Cangjie Tool: lsp..."
    if cangjie::_is_windows; then
      cangjie::_build_tool_lsp_windows
    else
      cangjie::_build_tool_lsp_linux
    fi
}

function cangjie::_build_tool_lsp_linux() {
    local install_dir="${cangjie_sdk_path}/${kernel}_${build_type}_${cmake_arch}/tools/bin"
    ( cd ${WORKSPACE}/cangjie_tools/cangjie-language-server/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} && \
      python3 build.py install --prefix ${install_dir} )
}

function cangjie::_build_tool_lsp_windows() {
    cangjie::_require_mingw || return 1
    ( cd ${WORKSPACE}/cangjie_tools/cangjie-language-server/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --target windows-x86_64 && \
      python3 build.py install )
}

function cangjie::_build_tool_cjpm() {
    [[ ${CANGJIE_CONFIG[build_tools]} != "true" ]] && return
    while [[ -z $(command -v cjc) ]]; do
      echo "cjc not found"
      return
    done

    echo "🚀 Building Cangjie Tool: cjpm..."
    if cangjie::_is_windows; then
      cangjie::_build_tool_cjpm_windows
    else
      cangjie::_build_tool_cjpm_linux
    fi
}

function cangjie::_build_tool_cjpm_linux() {
    local install_dir="${cangjie_sdk_path}/${kernel}_${build_type}_${cmake_arch}"
    ( cd ${WORKSPACE}/cangjie_tools/cjpm/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --set-rpath ${RPATH} --prefix ${install_dir} && \
      python3 build.py install )
}

function cangjie::_build_tool_cjpm_windows() {
    cangjie::_require_mingw || return 1
    ( cd ${WORKSPACE}/cangjie_tools/cjpm/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --target windows-x86_64 && \
      python3 build.py install )
}


function cangjie::_build_tool_cjfmt() {
    [[ ${CANGJIE_CONFIG[build_tools]} != "true" ]] && return
    while [[ -z $(command -v cjc) ]]; do
      echo "cjc not found"
      return
    done

    echo "🚀 Building Cangjie Tool: cjfmt..."
    if cangjie::_is_windows; then
      cangjie::_build_tool_cjfmt_windows
    else
      cangjie::_build_tool_cjfmt_linux
    fi
}

function cangjie::_build_tool_cjfmt_linux() {
    local install_dir="${cangjie_sdk_path}/${kernel}_${build_type}_${cmake_arch}"
    ( cd ${WORKSPACE}/cangjie_tools/cjfmt/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --prefix ${install_dir} && \
      python3 build.py install )
}

function cangjie::_build_tool_cjfmt_windows() {
    cangjie::_require_mingw || return 1
    ( cd ${WORKSPACE}/cangjie_tools/cjfmt/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --target windows-x86_64 && \
      python3 build.py install )
}


function cangjie::_build_tool_hle() {
    [[ ${CANGJIE_CONFIG[build_tools]} != "true" ]] && return
    while [[ -z $(command -v cjc) ]]; do
      echo "cjc not found"
      return
    done
    echo "🚀 Building Cangjie Tool: hle..."
    if cangjie::_is_windows; then
      cangjie::_build_tool_hle_windows
    else
      cangjie::_build_tool_hle_linux
    fi
}

function cangjie::_build_tool_hle_linux() {
    ( cd ${WORKSPACE}/cangjie_tools/hyperlangExtension/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --prefix ${cangjie_sdk_path} && \
      python3 build.py install )
}

function cangjie::_build_tool_hle_windows() {
    cangjie::_require_mingw || return 1
    ( cd ${WORKSPACE}/cangjie_tools/hyperlangExtension/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --target windows-x86_64 && \
      python3 build.py install )
}

function cangjie::_build_basic() {
    cangjie::_build_compiler
    cangjie::_build_runtime
    cangjie::_build_std
}

function cangjie::_build_tools() {
    cangjie::_build_tool_lsp
    cangjie::_build_tool_cjpm
    cangjie::_build_tool_cjfmt
    cangjie::_build_tool_hle
}

# 公开构建命令（主Shell接口）
function cangjie::build() {
    local target=$1
    shift 1
    if [[ -z "$target" ]]; then
        cangjie::build_all
        return
    fi

    case $target in
        all)      cangjie::build_all ;;
        compiler) cangjie::_run_in_subshell compiler ;;
        runtime)  cangjie::_run_in_subshell runtime ;;
        std)      cangjie::_run_in_subshell std $@ ;;
        stdx)     cangjie::_run_in_subshell stdx $@ ;;
	      lsp)	  cangjie::_run_in_subshell tool_lsp ;;
        tools)    cangjie::_run_in_subshell tools ;;
        ninja)    cangjie::_run_in_subshell ninja $@ ;;
        *)
            echo "Available build targets:"
            echo "  all       - Build all components (default)"
            echo "  compiler  - Build only compiler"
            echo "  runtime   - Build only runtime"
            echo "  std       - Build only standard library"
            echo "  stdx      - Build only stdx extensions"
            echo "  tools     - Build all tools (cjpm/cjfmt/lsp etc.)"
            echo "  ninja     - Build package in stdlib" 

            return 1
            ;;
    esac
}

# 配置函数（主Shell中运行）
function cangjie::config() {
    local key=$1
    local value=$2
    
    if [[ -z "$key" ]]; then
        echo "Current Cangjie build configuration:"
        for k in ${(k)CANGJIE_CONFIG}; do
            printf "  %-20s = %s\n" "$k" "${CANGJIE_CONFIG[$k]}"
        done
        return
    fi
    
    [[ -z "$value" ]] && { echo "${CANGJIE_CONFIG[$key]}"; return }
    
    # 验证配置值
    case "$key" in
        build_type) [[ "$value" =~ ^(debug|release|relwithdebinfo)$ ]] || { echo "Invalid build_type"; return 1 } ;;
        kernel) [[ "$value" =~ ^(linux|darwin|windows)$ ]] || { echo "Invalid kernel"; return 1 } ;;
        build_*) [[ "$value" =~ ^(true|false)$ ]] || { echo "Value must be true/false"; return 1 } ;;
    esac
    
    CANGJIE_CONFIG[$key]=$value
    echo "Set $key = $value"
}

# 更新帮助信息
function cangjie::help() {
    cat <<EOF
Cangjie Isolated Build System (Zsh)

Usage:
  cangjie::config [key] [value]  - View/set configuration
  cangjie::build [target]        - Build specific component or all
  cangjie::build_all             - Alias for 'build all'

Available Targets:
  compiler  - Cangjie compiler + cjdb
  runtime   - Runtime libraries
  std       - Standard library
  stdx      - STDX extensions
  tools     - All tools (cjpm/cjfmt/lsp/hle)
  all       - Full build chain (default)

Examples:
  # Build compiler only
  cangjie::build compiler

  # Build runtime and std together
  cangjie::build runtime
  cangjie::build std

  # Build all tools
  cangjie::build tools

  # Cross-compile for Windows
  cangjie::config kernel windows
  cangjie::config mingw_path /path/to/mingw
  cangjie::build runtime
EOF
}

# 更新自动补全
function _cangjie::comp() {
    local -a subcommands build_targets
    subcommands=(
        'config:Configure build settings'
        'build:Build specific component'
        'build_all:Build all components'
        'help:Show help information'
    )
    
    build_targets=(
        'all:Full build chain'
        'compiler:Cangjie compiler + cjdb'
        'runtime:Runtime libraries'
        'std:Standard library'
        'stdx:STDX extensions'
        'tools:All tools'
    )
    
    _arguments \
        '1: :->command' \
        '2: :->target' && return 0
    
    case $state in
        command)
            _describe 'command' subcommands
            ;;
        target)
            if [[ $words[2] == "build" ]]; then
                _describe 'target' build_targets
            fi
            ;;
    esac
}

function cangjie::clean() {
  local task=$1
    (
        set -e
        cangjie::_init  # 初始化子Shell环境
        
        case $task in
            compiler)    cangjie::_clean_compiler ;;
            runtime)     cangjie::_clean_runtime ;;
            std)         cangjie::_clean_std ;;
            stdx)        cangjie::_clean_stdx ;;
            # tools)       cangjie::_clean_tools ;;
            *)           echo "❌ Unknown clean target"; return 1 ;;
        esac
        
        echo "✅ $task clean successfully in isolated environment"
    )   
}

function cangjie::_clean_compiler() {
    echo "🚀 Cleaning Cangjie Compiler..."
    cd ${WORKSPACE}/cangjie_compiler || return 1
    python3 build.py clean
}

function cangjie::_clean_runtime() {
    echo "🚀 Cleaning Cangjie Compiler..."
    cd ${WORKSPACE}/cangjie_runtime/runtime || return 1
    python3 build.py clean
}

function cangjie::_clean_std() {
    echo "🚀 Cleaning Cangjie Compiler..."
    cd ${WORKSPACE}/cangjie_runtime/stdlib || return 1
    python3 build.py clean
}

function cangjie::_clean_stdx() {
    echo "🚀 Cleaning Cangjie Compiler..."
    cd ${WORKSPACE}/cangjie_stdx || return 1
    python3 build.py clean
}

function cjr() {
  local filename="main.cj"
  local test=false
  local noClean=false
  local verbose=false
  local extra_options=""
  while getopts ":f:t:n:v:e:x" opt; do
    case $opt in
      f) filename="$OPTARG" ;;
      t) test="$OPTARG" ;;
      n) noClean="true" ;;
      v) verbose="true" ;;
      e) extra_options="$OPTARG" ;;
      x)
        if [[ -z $CANGJIE_STDX_PATH ]]; then
          echo \$CANGJIE_STDX_PATH not found.
          return
        fi
        extra_options="-L $CANGJIE_STDX_PATH -lstdx.encoding.json -lstdx.serialization.serialization -lstdx.serialization -lstdx.net.http -lstdx.net.tls -lstdx.net -lstdx.logger -lstdx.log -lstdx.encoding.url -lstdx.encoding.json.stream -lstdx.crypto.keys -lstdx.crypto.x509 -lstdx.encoding.hex -lstdx.encoding.base64 -lstdx.encoding -lstdx.crypto.crypto -lstdx.crypto.digest -lstdx.crypto -lstdx.compress.zlib -lstdx.compress -lstdx --import-path $CANGJIE_STDX_PATH"
        ;;
      \?) ERROR "Invalid option: -$OPTARG" ;;
    esac
  done
  shift $((OPTIND - 1))

  local cmd="cjc -g --error-count-limit all -Woff all $extra_options $filename"
  if [[ "$test" == "true" ]]; then
    cmd += " --test"
  fi
  
  local initial_files=($(ls))
  invoke_exec $cmd $verbose || return -1
  if [[ "$noClean" != "true" ]]; then
    local current_files=($(ls))
    for file in "${current_files[@]}"; do
      if [[ "$file" == "main" && "$noClean" == "main" ]]; then
        continue
      fi
      if [[ ! " ${initial_files[@]} " =~ " ${file} " ]]; then
        invoke_exec "rm -r \"$files\"" "false"
      fi
    done
  fi
}

function cjh {
  emulate -L zsh
  setopt pipefail
  setopt no_unset

  local -a libNames libDirs linkExtra runArgs
  local needRun=true
  local needTest=false
  local filename="main.cj"
  local output="main"
  local lang="cj"
  local useStdx=false
  local keepWarnings=false   # -w: 不添加 -Woff all
  local useStatic=false 

  # stdx libs：保持你确认过的 cjc 写法
  local -a stdxLibs=(
    --link-option --start-group
    -lstdx.encoding.json
    -lstdx.serialization.serialization
    -lstdx.serialization
    -lstdx.net.http
    -lstdx.net.tls
    -lstdx.net.tls.common
    -lstdx.net
    -lstdx.logger
    -lstdx.log
    -lstdx.encoding.url
    -lstdx.encoding.json.stream
    -lstdx.crypto.keys
    -lstdx.crypto.x509
    -lstdx.encoding.hex
    -lstdx.encoding.base64
    -lstdx.encoding
    -lstdx.crypto.common
    -lstdx.crypto.crypto
    -lstdx.crypto.digest
    -lstdx.crypto
    -lstdx.compress.zlib
    -lstdx.compress
    -lstdx
    --link-option --end-group
  )

  local usage
  usage=$'Usage: cjh [options] [file] [-- args...]\n\n'\
$'Options:\n'\
$'  -h                Show help\n'\
$'  -b                Build only (do not run)\n'\
$'  -t                Build with test (do not run)\n'\
$'  -x                Enable stdx profile\n'\
$'  -w                Keep warnings (do NOT add -Woff all)\n'\
$'  -f <file>          Source file (default: main.cj)\n'\
$'  -o <out>           Output name (default: main)\n'\
$'  -l <name>          Extra library name (repeatable)\n'\
$'  -L <dir>           Add library search dir (repeatable)\n'\
$' -s                 enable `--static` option\n'\
$'\nEnv:\n'\
$'  CANGJIE_STDX_PATH: required when using -x\n'\
$'  CJ_SDK_LIBPATH: extra runtime lib path injected into LD_LIBRARY_PATH when running\n'

  # --- parse args ---
  local -a argv=("$@")
  local i=1
  while (( i <= $#argv )); do
    case "${argv[i]}" in
      -h) INFO "$usage"; return 0 ;;
      -b) needRun=false ;;
      -x) useStdx=true ;;
      -w) keepWarnings=true ;;
      -t) needTest=true ;;
      -s) useStatic=true ;;
      -f) (( i++ )); filename="${argv[i]:-}" ;;
      -o) (( i++ )); output="${argv[i]:-}" ;;
      -l) (( i++ )); libNames+=("${argv[i]:-}") ;;
      -L) (( i++ )); libDirs+=("${argv[i]:-}") ;;
      --)
        runArgs=("${argv[@]:i+1}")
        break
        ;;
      -*)
        linkExtra+=("${argv[i]}")
        ;;
      *)
        if [[ -f "${argv[i]}" ]]; then
          filename="${argv[i]}"
        else
          runArgs+=("${argv[i]}")
        fi
        ;;
    esac
    (( i++ ))
  done

  case "$filename" in
    *.cj) lang="cj" ;;
    *.c)  lang="c"  ;;
    *)    lang="cj" ;;
  esac

  # --- build ---
  if [[ "$lang" == "cj" ]]; then
    local -a cmd=(cjc)

    # 基础参数
    cmd+=(-g --error-count-limit all)
    if [[ "$keepWarnings" != true ]]; then
      cmd+=(-Woff all)
    fi

    if [[ "$needTest" == true ]]; then
      cmd+=(--test)
    fi

    if [[ "$useStatic" == true ]]; then
      cmd+=(--static)
    fi

    # 用户自定义 -L
    for d in "${libDirs[@]}"; do
      cmd+=(-L "$d")
    done

    # stdx profile：--import-path + -L + libs
    if [[ "$useStdx" == true ]]; then
      if [[ -z "${CANGJIE_STDX_PATH:-}" ]]; then
        ERROR "[cjh] -x 需要先设置 CANGJIE_STDX_PATH"
        return 2
      fi
      cmd+=(--import-path "$CANGJIE_STDX_PATH" -L "$CANGJIE_STDX_PATH")
      cmd+=("${stdxLibs[@]}")
    fi

    # 额外 -l
    for n in "${libNames[@]}"; do
      [[ "$n" == -l* ]] && cmd+=("$n") || cmd+=("-l$n")
    done

    # 透传选项
    cmd+=("${linkExtra[@]}")
    cmd+=("$filename" -o "$output")

    INFO "[cjh] ${cmd[*]}"
    if ! "${cmd[@]}"; then
      ERROR "[cjh] 编译失败：$filename"
      return 1
    fi
    SUCCESS "[cjh] 编译成功：./$output"
  else
    local CC=${CC:-gcc}
    local -a cmd=("$CC" -g)

    for d in "${libDirs[@]}"; do cmd+=(-L "$d"); done
    for n in "${libNames[@]}"; do [[ "$n" == -l* ]] && cmd+=("$n") || cmd+=("-l$n"); done
    cmd+=("${linkExtra[@]}")
    cmd+=("$filename" -o "$output")

    INFO "[cjh] ${cmd[*]}"
    if ! "${cmd[@]}"; then
      ERROR "[cjh] 编译失败：$filename"
      return 1
    fi
    SUCCESS "[cjh] 编译成功：./$output"
  fi

  # --- run ---
  if [[ "$needRun" == true ]]; then
    local bin="./$output"
    if [[ ! -x "$bin" ]]; then
      ERROR "[cjh] 输出不可执行：$bin"
      return 3
    fi

    local old_ld="${LD_LIBRARY_PATH:-}"
    if [[ -n "${CJ_SDK_LIBPATH:-}" ]]; then
      export LD_LIBRARY_PATH="${CJ_SDK_LIBPATH}${old_ld:+:$old_ld}"
      WARNING "[cjh] LD_LIBRARY_PATH 注入：$CJ_SDK_LIBPATH"
    fi

    INFO "[cjh] run: $bin ${runArgs[*]}"
    "$bin" "${runArgs[@]}"
  fi
}

function cangjie::_build_ninja {
    [[ ${CANGJIE_CONFIG[build_std]} != "true" ]] && return
    while [[ -z $(command -v cjc) ]]; do
      echo "cjc not found"
      return
    done

    local package=$2

    export cjc="$(command -v cjc) -Woff all"
    echo "🚀 Building Cangjie Standard Librar by ninja"
    cd ${WORKSPACE}/cangjie_runtime/stdlib || return 1

    if [ -d "build/build" ]; then
      cd build/build
    else
      echo "Error: Directory build/build does not exist."
      exit 1
    fi
    ninja $1
    python3 ${WORKSPACE}/cangjie_runtime/stdlib/build.py install

    local install_dir="${cangjie_sdk_path}/${kernel}_${build_type}_${cmake_arch}"
    cp -rf ${WORKSPACE}/cangjie_runtime/stdlib/output/* ${install_dir}
    echo "🎉 Install std to ${install_dir}"
}


function cjcclip() {
  local tmp out
  tmp=$(mktemp --suffix=.cj /tmp/clip-XXXXXX) || return 1
  out=${tmp%.cj}.out

  wl-paste > "$tmp" || return 1
  cjc -o "$out" "$tmp" || return $?
  echo "[cjcclip] src: $tmp" >&2
  echo "[cjcclip] out: $out" >&2
  invoke_exec "$out"
}
