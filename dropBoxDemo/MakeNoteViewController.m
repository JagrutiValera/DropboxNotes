//
//  MakeNoteViewController.m
//  dropBoxDemo
//
//  Created by Jagruti Valera on 21/01/16.
//  Copyright © 2016 Jagruti Valera. All rights reserved.
//

#import "MakeNoteViewController.h"
#import "MBProgressHUD.h"
#import "Reachability.h"

@interface MakeNoteViewController ()

@end

@implementation MakeNoteViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;

    if (self.isEditing) {
        [self setData];
        self.btnSave.enabled = NO;
    }else{
        self.btnDelete.hidden = YES;
    }
    // add observer to get keyboard height
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];

}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self deleteLocalFiles];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Other Actions
-(void)setData{
    self.textContent.text = self.strContent;
    NSString * filename = [self.file.filename substringToIndex:[self.file.filename length]-4];// removed extension ".txt"
    self.lblTitle.text = filename;
}
-(void)uploadFileWithTitle: (NSString*) title andContent: (NSString*)content
{
    // Write a file to the local documents directory
    NSString *text = content;
    NSString *filename = title;
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [localDir stringByAppendingPathComponent:filename];
    [text writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    

    NSString *destDir = @"/";
    Reachability *reachability	= [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        [self showAlertWithTitle:@"No Internet" AndMessage:@"To continue this process you need internet connection. Please check your internet connectivity"];
    }
    else
    {
        // Upload file to Dropbox
        if (self.isEditing) {
            [self.restClient uploadFile:filename toPath:destDir withParentRev:self.file.rev fromPath:localPath];
        }else{
            [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
        }
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
}
// Delete localy saved files
-(void)deleteLocalFiles
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:localDir error:nil];
    for (NSString *filename in fileArray)  {
        [fileMgr removeItemAtPath:[localDir stringByAppendingPathComponent:filename] error:NULL];
    }
}
#pragma mark - Button Actions
-(IBAction)deleteClicked:(id)sender{
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Delete?"
                                  message:@"Are you sure, you want to delete this file?"
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* delete = [UIAlertAction
                             actionWithTitle:@"Delete"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 Reachability *reachability	= [Reachability reachabilityForInternetConnection];
                                 NetworkStatus networkStatus = [reachability currentReachabilityStatus];
                                 if (networkStatus == NotReachable)
                                 {
                                     [self showAlertWithTitle:@"No Internet" AndMessage:@"To continue this process you need internet connection. Please check your internet connectivity"];
                                 }
                                 else
                                 {
                                     // Delete file in dropbox
                                     [self.restClient deletePath:self.file.path];
                                     [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                 }
                                 
                             }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    [alert addAction:delete];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}
-(IBAction)saveClicked:(id)sender{
    NSString* title ;
    if (self.isEditing) {
        title = self.file.filename;
    }else{
        NSInteger maxWords = 4;
        NSInteger maxChar = 20;
        NSArray *theWords = [self.textContent.text componentsSeparatedByString:@" "];
        if ([theWords count] < maxWords) {
            maxWords = [theWords count];
        }
        NSRange wordRange = NSMakeRange(0, maxWords);
        NSArray *firstWords = [theWords subarrayWithRange:wordRange];
        NSString* result= [firstWords componentsJoinedByString:@" "];
        if ([result length]>maxChar) {
            result = [result substringToIndex:maxChar];
        }
        title = [NSString  stringWithFormat:@"%@.txt",result];
    }
//save file
    [self uploadFileWithTitle:title andContent:self.textContent.text];
}
-(IBAction)cancelClicked:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
-(IBAction)dismissTextClicked:(id)sender{// for dismissing keyboard for textView
    [self.textContent resignFirstResponder];
    [self setTextViewFrame];

}
-(void)showAlertWithTitle:(NSString*)title AndMessage:(NSString*)message{
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:title
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"Ok"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    self.kbHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    [self setTextViewFrame];
}
-(void)setTextViewFrame{
    if ([self.textContent isFirstResponder]) {
        CGRect frm = self.textContent.frame;
        self.textContent.frame = CGRectMake(frm.origin.x, frm.origin.y, frm.size.width, self.view.bounds.size.height-(10 + frm.origin.y + self.kbHeight));
    }else{
        CGRect frm = self.textContent.frame;
        self.textContent.frame = CGRectMake(frm.origin.x, frm.origin.y, frm.size.width, self.view.bounds.size.height-(10 + frm.origin.y));
    }
}

#pragma mark - Textview Delegate
-(void)textViewDidBeginEditing:(UITextView *)textView{
    self.btnSave.enabled=YES;
}
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{

    return YES;
}

#pragma mark -
#pragma mark - Delegates for DropBox
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Uploading Fail"
                                          message:error.description
                                          preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertController animated:YES completion:nil];

    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
}
-(void)restClient:(DBRestClient *)client deletedPath:(NSString *)path{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.navigationController popViewControllerAnimated:YES];

}
-(void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Deleting Fail"
                                                                             message:error.description
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertController animated:YES completion:nil];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];

}


@end
