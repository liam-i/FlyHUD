#!/bin/sh

echo "执行的脚本名：$0"

schemeName="HUD"
machOTypes=("mh_dylib")

shDir=$(cd "$(dirname "$0")";pwd)
buildout="${shDir}/build.out"
podfilePath=${shDir} # 默认podfile和aggregate.sh文件在同一路径下

function ask_macho_with_answers() {
    case $1 in
    1)
        machOTypes=("mh_dylib")
        ;;
    2)
        machOTypes=("staticlib")
        ;;
    3)
        machOTypes=("mh_dylib" "staticlib")
        ;;
    *)
        echo "\033[31m Unknown command: [$1]. \033[0m" # 红色
        echo "\033[33m Please select the Mach-O to be compiled for framework \033[0m" # 黄色
        echo "\033[33m       1. only dynamic framework \033[0m"
        echo "\033[33m       2. only static framework \033[0m"
        echo "\033[33m       3. both dynamic and static framework \033[0m"

        read -p "--> Please enter [1/2/3]: " _command;
        ask_macho_with_answers $_command;
        ;;
    esac
}

function echo_params() {
    echo "\033[33m 🟡 ----------------------- 🟡 \033[0m" # 黄色
    echo "\033[33m scheme   = ${schemeName} \033[0m" # 黄色
    echo "\033[33m buildout = ${buildout} \033[0m" # 黄色
    echo "\033[33m Mach-O   = (${machOTypes[*]}) \033[0m" # 黄色
    echo "\033[33m 🟡 ----------------------- 🟡 \033[0m" # 黄色
}

function pod_install() {
    echo "\033[33m --> pod install... \033[0m" # 黄色

    cd ${podfilePath}

    rm -rf "Podfile.lock"
    rm -rf "Pods/*"

    pod install

    if [ $? -ne 0 ]
    then
        echo "\033[31m 🔴🔴🔴 --> pod install failed. \033[0m" # 红色
        exit 1
    else
        echo "\033[32m 🟢🟢🟢 --> pod install succeeded. \033[0m" # 绿色
        cd ./Pods
    fi
}

function build_framework() {
    machOType=$1
    buildoutPath="${buildout}/${machOType}"
    archiveiOSPath="${buildoutPath}/iphoneos.xcarchive"
    archiveSimulatorPath="${buildoutPath}/iphonesimulator.xcarchive"

    echo "\033[33m --> build ${machOType} ${schemeName}.xcframework... \033[0m" # 黄色

    xcodebuild archive -scheme ${schemeName} \
                       -sdk iphoneos \
                       -archivePath ${archiveiOSPath} \
                       SKIP_INSTALL=NO \
                       BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
                       MACH_O_TYPE=${machOType} || exit 1

    xcodebuild archive -scheme ${schemeName} \
                       -sdk iphonesimulator \
                       -archivePath ${archiveSimulatorPath} \
                       SKIP_INSTALL=NO \
                       BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
                       MACH_O_TYPE=${machOType} || exit 1

    xcodebuild -create-xcframework \
               -framework "${archiveiOSPath}/Products/Library/Frameworks/${schemeName}.framework" \
               -framework "${archiveSimulatorPath}/Products/Library/Frameworks/${schemeName}.framework" \
               -output "${buildoutPath}/${schemeName}.xcframework" || exit 1

    echo "\033[32m 🟢🟢🟢 --> build ${machOType} ${schemeName}.xcframework succeeded. \033[0m" # 绿色
}

function build_frameworks() {
    rm -rf ${buildout}

    for machOType in ${machOTypes[*]}
    do
        build_framework ${machOType}
    done

    echo "\033[32m 🟢🟢🟢 --> build ${schemeName}.xcframework completed. \033[0m" # 绿色
    echo "\033[42;31m open ${buildout} \033[0m" # 绿色背景，红色字体
    open ${buildout}
}

ask_macho_with_answers $1;
echo_params
pod_install
build_frameworks
