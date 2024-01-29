# HUD

<!-- [![CI Status](https://img.shields.io/travis/Liam/HUD.svg?style=flat)](https://travis-ci.org/Liam/HUD) -->
[![Version](https://img.shields.io/cocoapods/v/LPHUD.svg?style=flat)](https://cocoapods.org/pods/LPHUD)
[![License](https://img.shields.io/cocoapods/l/LPHUD.svg?style=flat)](https://cocoapods.org/pods/LPHUD)
[![Platform](https://img.shields.io/cocoapods/p/LPHUD.svg?style=flat)](https://cocoapods.org/pods/LPHUD)

This is a lightweight and easy-to-use HUD designed to display the progress and status of ongoing tasks on iOS and tvOS.

## ScreenShots

[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/2-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/2.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/3-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/3.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/4-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/4.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/5-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/5.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/6-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/6.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/7-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/7.png)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* iOS 11.0+ 
* Xcode 14.0+
* Swift 5.0+

## Installation

#### Swift Package Manager

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/liam-i/HUD.git`
- Select "Up to Next Minor" with "1.4.0"

#### CocoaPods

HUD is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target 'MyApp' do
  pod 'LPHUD', '~> 1.4.0'
  # or
  pod 'LPHUD', '~> 1.4.0', :subspecs => ['HUDIndicator']
  # or
  pod 'LPHUD', '~> 1.4.0', :subspecs => ['HUDProgress']
end
```

## ## Documentation

[Complete API Documentation](https://liam-i.github.io/HUD/documentation/lphud)

## Author

Liam, liam_i@163.com

## License

HUD is available under the MIT license. See the LICENSE file for more info.
