# LPProgressHUD

LPProgressHUD is a Swift version of the HUD that mimics [MBProgressHUD](https://github.com/jdg/MBProgressHUD).


![](ScreenShots/ScreenShot1.png)
![](ScreenShots/ScreenShot2.png)
![](ScreenShots/ScreenShot3.png)
![](ScreenShots/ScreenShot4.png)
![](ScreenShots/ScreenShot5.png)
![](ScreenShots/ScreenShot6.png)


## Requirements

* iOS 9.0+ 
* Xcode 8.1+
* Swift 3.0+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```
$ gem install cocoapods
```


To integrate LPProgressHUD into your Xcode project using CocoaPods, specify it in your `Podfile `:

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>'  do
    pod 'LPProgressHUD', '~> 1.0.1’
end
```

Then, run the following command:

```
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate LPProgressHUD into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "leo-lp/LPProgressHUD"
```

Run `carthage update` to build the framework and drag the built `LPProgressHUD.framework` into your Xcode project.

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate LPProgressHUD into your project manually.

---

## Usage
Use MBProgressHUD to set up on the main thread and then switch the task to be performed to the new thread.

```
let hud = LPProgressHUD.show(to: view, animated: true)
DispatchQueue.global().async {
    // Do something...
    DispatchQueue.main.sync {
        hud.hide(animated: true)
    }
}
```

For more examples, including how to use LPProgressHUD with asynchronous operations, take a look at the bundled [Example](Example) project.

## License

This code is distributed under the terms and conditions of the [MIT license](LICENSE).
