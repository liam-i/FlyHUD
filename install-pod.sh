#!/bin/sh

echo "执行的脚本名：$0"

function pod_install() {
    case $1 in
    no)
        echo "\033[33m --> pod install --verbose --no-repo-update... \033[0m" # 黄色
        pod install --verbose --no-repo-update
        ;;
    *)
        echo "\033[33m --> pod install... \033[0m" # 黄色
        pod install
        ;;
    esac

    if [ $? -ne 0 ]
    then
        echo "\033[31m 🔴🔴🔴 --> pod install failed. \033[0m" # 红色
    else
        echo "\033[32m 🟢🟢🟢 --> pod install succeeded. \033[0m" # 绿色
    fi
}

pod_install $1;
