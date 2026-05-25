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
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITextField *textField;
@end

@implementation OCPresentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OC Present VC";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSelf)];
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithTitle:@"Hide All" style:UIBarButtonItemStylePlain target:self action:@selector(hideAllHUDClicked)],
        [[UIBarButtonItem alloc] initWithTitle:@"Hide Top" style:UIBarButtonItemStylePlain target:self action:@selector(hideTopHUDClicked)],
        [[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStylePlain target:self action:@selector(showHUDClicked)]
    ];
    [self setupUI];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToDismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)setupUI {
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.containerView.layer.cornerRadius = 8;
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.containerView];

    self.textField = [[UITextField alloc] init];
    self.textField.placeholder = @"Tap here to show keyboard";
    self.textField.borderStyle = UITextBorderStyleRoundedRect;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textField];

    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.text = @"\U0001F446 Tap screen to dismiss keyboard";
    hintLabel.font = [UIFont systemFontOfSize:13];
    hintLabel.textColor = UIColor.secondaryLabelColor;
    hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:hintLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.containerView.widthAnchor constraintEqualToConstant:300],
        [self.containerView.heightAnchor constraintEqualToConstant:300],

        [self.textField.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.textField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.textField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.textField.heightAnchor constraintEqualToConstant:36],

        [hintLabel.topAnchor constraintEqualToAnchor:self.textField.bottomAnchor constant:8],
        [hintLabel.leadingAnchor constraintEqualToAnchor:self.textField.leadingAnchor]
    ]];
}

- (void)showHUDClicked {
    [HUDBridgingOC showMultipleHUDsTo:self.view containerView:self.containerView];
}

- (void)hideTopHUDClicked {
    [HUDBridgingOC hideFor:self.view containerView:self.containerView];
}

- (void)hideAllHUDClicked {
    [HUDBridgingOC hideAllFor:self.view containerView:self.containerView];
}

- (void)dismissSelf {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tapToDismissKeyboard {
    [self.view endEditing:YES];
}

@end
