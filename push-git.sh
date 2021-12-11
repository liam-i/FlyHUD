#!/bin/sh

echo "执行的脚本名：$0"

function git_push() {
    msg=$1

    case $1 in
    d)
        msg="Minor Updates"
        ;;
    esac


    if [ -z "$msg" ]; then
        echo "\033[33m --> 请输入提交信息[d. Minor Updates]: \033[0m" # 黄色
        read -p " " msg;

        git_push $msg;
        return
    fi

    echo "\033[33m --> 输入的提交信息: ${msg} \033[0m" # 黄色

    git add -A
    git commit -m "${msg}"
    git push

    if [ $? -eq 0 ]; then
        echo "\033[32m 🟢🟢🟢 --> Push 成功. \033[0m" # 绿色
    else
        echo "\033[31m 🔴🔴🔴 --> Push 失败. \033[0m" # 红色
    fi
}

git_push $1;
