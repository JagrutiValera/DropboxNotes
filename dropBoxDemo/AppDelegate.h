//
//  AppDelegate.h
//  dropBoxDemo
//
//  Created by Jagruti Valera on 21/01/16.
//  Copyright © 2016 Jagruti Valera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomNavigationController.h"
#import "ViewController.h"
#import "HomeViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, DBRestClientDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) CustomNavigationController* navigationController;
@property (nonatomic, strong) HomeViewController* homeViewControlelr;
@property (nonatomic, strong) ViewController* noteViewController;

@end

