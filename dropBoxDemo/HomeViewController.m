//
//  HomeViewController.m
//  dropBoxDemo
//
//  Created by Jagruti Valera on 21/01/16.
//  Copyright © 2016 Jagruti Valera. All rights reserved.
//

#import "HomeViewController.h"
#import "ViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (![[DBSession sharedSession] isLinked]) {
        [self.btnGetStarted setTitle:@"Dropbox Login" forState:UIControlStateNormal];// will redirect to Dropbox app/page
    }else{
        [self.btnGetStarted setTitle:@"Let's Begin" forState:UIControlStateNormal]; // Will redirect to NOTES LIST
    }
    
}
-(IBAction)getStartedClicked:(id)sender{
    
    // Check Internet Connection before authentication
    Reachability *reachability	= [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"No Internet"
                                      message:@"Please Check Your Internet Connection"
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"Ok"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
        
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];    }
    else
    {
        if (![[DBSession sharedSession] isLinked]) {
            
            [[DBSession sharedSession] linkFromController:self];// will redirect to Dropbox app/page
        }else{
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ViewController* obj = [sb instantiateViewControllerWithIdentifier:@"ViewController"];
            [self.navigationController pushViewController:obj animated:YES];// Will redirect to NOTES LIST
        }
    }
    
}


@end
