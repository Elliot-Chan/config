#!/usr/bin/env zsh

# Cangjie Build System Functions with Isolated Single-Component Builds
# Version: 2.1.0

# 配置变量 (主Shell中定义，子Shell会继承拷贝)
typeset -gA CANGJIE_CONFIG=(
    [workspace]="$HOME/code/CJ"
    [build_type]="relwithdebinfo"
    [kernel]="linux"
    [cmake_arch]="x86_64"
    [build_compiler]="true"
    [build_runtime]="true"
    [build_std]="true"
    [build_stdx]="false"
    [build_tools]="false"
    [build_cjdb]="false"
    [build_version]="1.0.0"
    [set_rpath]="true"
    [compiler_path]="/usr/lib/llvm15/bin"
    [output]="$HOME/cangjie_sdk/"
)

# 私有构建函数（子Shell内执行）
function cangjie::_run_in_subshell() {
    local task=$1
    (
        set -e
        cangjie::_init  # 初始化子Shell环境
        
        case $task in
            compiler)    cangjie::_build_compiler ;;
            runtime)     cangjie::_build_runtime ;;
            std)         cangjie::_build_std ;;
            stdx)        cangjie::_build_stdx ;;
            tools)       cangjie::_build_tools ;;
            *)           echo "❌ Unknown build target"; return 1 ;;
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
    export cangjie_sdk_path=${CANGJIE_CONFIG[cangjie_sdk_path]}

    # 创建工作空间目录（实际物理操作）
    mkdir -p ${WORKSPACE}/{cangjie_compiler,cangjie_runtime,cangjie_stdx,cangjie_tools}
}

# 构建编译器 (子Shell中运行)
function cangjie::_build_compiler() {
    [[ ${CANGJIE_CONFIG[build_compiler]} != "true" ]] && return

    echo "🚀 Building Cangjie Compiler..."
    cd ${WORKSPACE}/cangjie_compiler || return 1
    
    python3 build.py clean
    python3 build.py build -t ${build_type} ${AddOptsBuildpy} --prefix ${cangjie_sdk_path}
    python3 build.py install
    
    source output/envsetup.sh
    cjc -v || { echo "❌ Compiler verification failed"; return 1 }
}

# 构建运行时 (子Shell中运行)
function cangjie::_build_runtime() {
    [[ ${CANGJIE_CONFIG[build_runtime]} != "true" ]] && return

    echo "🚀 Building Cangjie Runtime..."
    cd ${WORKSPACE}/cangjie_runtime/runtime || return 1
    
    python3 build.py clean
    python3 build.py build -t ${build_type} -v ${build_version} --prefix ${cangjie_sdk_path}
    python3 build.py install
    
    local runtime_dir="${WORKSPACE}/cangjie_runtime/runtime/output/common/${kernel}_${build_type}_${cmake_arch}"
    [[ -d "${runtime_dir}" ]] || { echo "❌ Runtime dir missing"; return 1 }
    cp -rf "${runtime_dir}"/{lib,runtime} "${WORKSPACE}/cangjie_compiler/output"
}

# 构建标准库 (子Shell中运行)
function cangjie::_build_std() {
    [[ ${CANGJIE_CONFIG[build_std]} != "true" ]] && return

    if [[ -z $(command -v cjc) ]]; then
      echo "cjc not found"
      return
    fi

    echo "🚀 Building Cangjie Standard Library..."
    cd ${WORKSPACE}/cangjie_runtime/std || return 1
    
    python3 build.py clean
    python3 build.py build -t ${build_type} \
        --target-lib=${WORKSPACE}/cangjie_runtime/runtime/output --prefix ${cangjie_sdk_path}
    python3 build.py install
    
    cp -rf ${WORKSPACE}/cangjie_runtime/std/output/* ${WORKSPACE}/cangjie_compiler/output/
}

# 构建STDX扩展库 (子Shell中运行)
function cangjie::_build_stdx() {
    [[ ${CANGJIE_CONFIG[build_stdx]} != "true" ]] && return

    if [[ -z $(command -v cjc) ]]; then
      echo "cjc not found"
      return
    fi

    echo "🚀 Building Cangjie STDX Extension..."
    cd ${WORKSPACE}/cangjie_stdx || return 1
    
    python3 build.py clean
    python3 build.py build -t ${build_type} \
        --include=${WORKSPACE}/cangjie_compiler/include --prefix ${cangjie_sdk_path}
    python3 build.py install
    
    export CANGJIE_STDX_PATH="${WORKSPACE}/cangjie_stdx/target/${kernel}_${cmake_arch}_cjnative/static/stdx"
}

# 构建工具集 (子Shell中运行)
function cangjie::_build_tools() {
    [[ ${CANGJIE_CONFIG[build_tools]} != "true" ]] && return

    if [[ -z $(command -v cjc) ]]; then
      echo "cjc not found"
      return
    fi
    echo "🚀 Building Cangjie Tools..."
    
    # cjpm
    ( cd ${WORKSPACE}/cangjie_tools/cjpm/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --set-rpath ${RPATH} --prefix ${cangjie_sdk_path} && \
      python3 build.py install )
    
    # cjfmt
    ( cd ${WORKSPACE}/cangjie_tools/cjfmt/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --prefix ${cangjie_sdk_path} && \
      python3 build.py install )
    
    # hle
    ( cd ${WORKSPACE}/cangjie_tools/hyperlangExtension/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --prefix ${cangjie_sdk_path} && \
      python3 build.py install )
    
    # lsp
    ( cd ${WORKSPACE}/cangjie_tools/cangjie-language-server/build && \
      python3 build.py clean && \
      python3 build.py build -t ${build_type} --prefix ${cangjie_sdk_path} && \
      python3 build.py install )
}

# 公开构建命令（主Shell接口）
function cangjie::build() {
    local target=$1
    if [[ -z "$target" ]]; then
        cangjie::build_all
        return
    fi

    case $target in
        all)      cangjie::build_all ;;
        compiler) cangjie::_run_in_subshell compiler ;;
        runtime)  cangjie::_run_in_subshell runtime ;;
        std)      cangjie::_run_in_subshell std ;;
        stdx)     cangjie::_run_in_subshell stdx ;;
        tools)    cangjie::_run_in_subshell tools ;;
        *)
            echo "Available build targets:"
            echo "  all       - Build all components (default)"
            echo "  compiler  - Build only compiler"
            echo "  runtime   - Build only runtime"
            echo "  std       - Build only standard library"
            echo "  stdx      - Build only stdx extensions"
            echo "  tools     - Build all tools (cjpm/cjfmt/lsp etc.)"
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
