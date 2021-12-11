#!/bin/sh

echo "执行的脚本名：$0"

function pod_update() {
    case $1 in
    no)
        echo "\033[33m --> pod update --verbose --no-repo-update... \033[0m" # 黄色
        pod update --verbose --no-repo-update
        ;;
    *)
        echo "\033[33m --> pod update... \033[0m" # 黄色
        pod update
        ;;
    esac

    if [ $? -ne 0 ]
    then
        echo "\033[31m 🔴🔴🔴 --> pod update failed. \033[0m" # 红色
    else
        echo "\033[32m 🟢🟢🟢 --> pod update succeeded. \033[0m" # 绿色
    fi
}

pod_update $1;
