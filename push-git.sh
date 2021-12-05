#!/bin/sh

echo "执行的脚本名：$0"

function git_push() {
    msg=$1

    case $1 in
    r|p)
        read -p "--> Please enter commit message (or press Enter to skip): " msg;
        ;;
    *)
        ;;
    esac

    if [ -z "$msg" ]; then
        msg="Minor Updates"
    fi

    echo "\033[33m --> entered message: ${msg} \033[0m" # 黄色

    git add -A
    git commit -m "${msg}"
    git push

    if [ $? -eq 0 ]; then
        echo "\033[32m 🟢🟢🟢 --> Push succeeded. \033[0m" # 绿色
    else
        echo "\033[31m 🔴🔴🔴 --> Push Failed. \033[0m" # 红色
    fi
}

git_push $1;
