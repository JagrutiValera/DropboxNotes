//
//  ViewController.h
//  dropBoxDemo
//
//  Created by Jagruti Valera on 21/01/16.
//  Copyright © 2016 Jagruti Valera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

@interface ViewController : UIViewController
<DBRestClientDelegate, DBSessionDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) NSMutableArray *arrayNotes;
@property (weak, nonatomic) IBOutlet UITableView *tblNotes;

- (IBAction)makeNoteClicked:(id)sender;
@end

