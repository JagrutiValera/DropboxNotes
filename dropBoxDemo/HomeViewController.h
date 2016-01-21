//
//  HomeViewController.h
//  dropBoxDemo
//
//  Created by Jagruti Valera on 21/01/16.
//  Copyright © 2016 Jagruti Valera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "Reachability.h"


@interface HomeViewController : UIViewController

-(IBAction)getStartedClicked:(id)sender;

@property (nonatomic, weak) IBOutlet UIButton *btnGetStarted;

@end
