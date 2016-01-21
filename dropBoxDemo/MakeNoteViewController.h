//
//  MakeNoteViewController.h
//  dropBoxDemo
//
//  Created by Jagruti Valera on 21/01/16.
//  Copyright © 2016 Jagruti Valera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

@interface MakeNoteViewController : UIViewController
<UITextViewDelegate, DBRestClientDelegate>
{
    
}
@property (nonatomic, strong) DBRestClient *restClient;

@property(nonatomic, strong) DBMetadata* file;
@property(nonatomic, weak) IBOutlet UITextView *textContent;
@property(nonatomic, weak) IBOutlet UIButton *btnSave;
@property(nonatomic, weak) IBOutlet UIButton *btnDelete;
@property(nonatomic, weak) IBOutlet UILabel *lblTitle;
@property BOOL isEditing;
@property CGFloat kbHeight;
@property (nonatomic, strong) NSString* strContent;
@property (nonatomic, strong) NSString* strLocalPath;

-(IBAction)saveClicked:(id)sender;
-(IBAction)cancelClicked:(id)sender;
-(IBAction)deleteClicked:(id)sender;
-(IBAction)dismissTextClicked:(id)sender;
@end
