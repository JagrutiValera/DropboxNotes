//
//  CustomNavigationController.h
//  dropBoxDemo
//
//  Created by Jagruti Valera on 21/01/16.
//  Copyright © 2016 Jagruti Valera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

@interface CustomNavigationController : UINavigationController
<DBRestClientDelegate>

@property (nonatomic, strong) DBRestClient *restClient;


@end
