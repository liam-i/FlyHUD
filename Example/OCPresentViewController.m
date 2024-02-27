//
//  OCPresentViewController.m
//  Example iOS
//
//  Created by liam on 2024/2/27.
//  Copyright © 2024 Liam. All rights reserved.
//

#import "OCPresentViewController.h"
#import "Example_iOS-Swift.h"

@interface OCPresentViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@end

@implementation OCPresentViewController

- (IBAction)showHUDClicked:(UIButton *)sender {
    [HUDBridgingOC showMultipleHUDsTo:self.view containerView:self.containerView];
}

- (IBAction)hideTopHUDClicked:(UIButton *)sender {
    [HUDBridgingOC hideFor:self.view containerView:self.containerView];
}

- (IBAction)hideAllHUDClicked:(UIButton *)sender {
    [HUDBridgingOC hideAllFor:self.view containerView:self.containerView];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self.view endEditing:YES];
}

@end
