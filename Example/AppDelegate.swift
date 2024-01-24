//
//  AppDelegate.swift
//  HUD
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import LPHUD

#warning("keyboard")
#warning("进入后台就不转了")

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    final class Test {
        func put() {
            print("put hashTable.allObjects.count")
        }
        deinit {
            print("Deinited")
        }
    }
    let hashTable: NSHashTable<Test> = .weakObjects()
//    let hashTable: NSHashTable<Test> = .init(options: [.weakMemory, .objectPointerPersonality], capacity: 0)
    var ars: [Test] = [Test(),Test(),Test(),Test(),Test(),Test(),Test()]


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        ars.forEach { s in
            hashTable.add(s)
        }

        print("1 hashTable.allObjects.count=\(hashTable.allObjects.count), \(hashTable.count)")

        ars.removeAll()

        print("2 hashTable.allObjects.count1=\(hashTable.allObjects.count), \(hashTable.count)")
        hashTable.allObjects.forEach {
            $0.put()
        }
        let enu2 = hashTable.objectEnumerator()
        while let value = enu2.nextObject() {
            guard let observer = value as? Test else { continue }
            observer.put()
        }
        print("2 hashTable.allObjects.count2=\(hashTable.allObjects.count), \(hashTable.count)")

        DispatchQueue.main.async { [self] in
            print("3 hashTable.allObjects.count=\(hashTable.allObjects.count), \(hashTable.count)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            print("4 hashTable.allObjects.count=\(hashTable.allObjects.count), \(hashTable.count)")
        }
//


        KeyboardObserver.shared
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
