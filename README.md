# LPProgressHUD

LPProgressHUD is a Swift version of the HUD that mimics [MBProgressHUD](https://github.com/jdg/MBProgressHUD).


![](ScreenShots/ScreenShot1.png)
![](ScreenShots/ScreenShot2.png)
![](ScreenShots/ScreenShot3.png)
![](ScreenShots/ScreenShot4.png)
![](ScreenShots/ScreenShot5.png)
![](ScreenShots/ScreenShot6.png)


## Requirements

* iOS 8.0+ 
* Xcode 8.1+
* Swift 3.0+


## Usage
Use MBProgressHUD to set up on the main thread and then switch the task to be performed to the new thread.

````
let hud = LPProgressHUD.show(to: view, animated: true)
DispatchQueue.global().async {
	// Do something...
	DispatchQueue.main.sync {
		hud.hide(animated: true)
	}
}
````

For more examples, including how to use LPProgressHUD with asynchronous operations, take a look at the bundled [Example](Example) project.

## License

This code is distributed under the terms and conditions of the [MIT license](LICENSE).
