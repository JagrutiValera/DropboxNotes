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
    // Do any additional setup after loading the view.
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
    self.textContent.layer.borderWidth = 1.0;
    self.textContent.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);
    if (self.isEditing) {
        [self setData];
        self.btnSave.enabled = NO;
    }else{
        self.btnDelete.hidden = YES;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Other Actions
-(void)setData{
    self.textContent.text = self.strContent;
    NSString * filename = [self.file.filename substringToIndex:[self.file.filename length]-4];
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
    
    // Upload file to Dropbox
    NSString *destDir = @"/";
    Reachability *reachability	= [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        [self showAlertWithTitle:@"No Internet" AndMessage:@"To continue this process you need internet connection. Please check your internet connectivity"];
    }
    else
    {
        if (self.isEditing) {
            [self.restClient uploadFile:filename toPath:destDir withParentRev:self.file.rev fromPath:localPath];
        }else{
            [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
        }
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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

    [self uploadFileWithTitle:title andContent:self.textContent.text];
}
-(IBAction)cancelClicked:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
-(IBAction)dismissTextClicked:(id)sender{
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
    NSLog(@"%f", self.kbHeight);
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
    if ([text isEqualToString:@"\n"]) {
//        [textView resignFirstResponder];
    } else {
    }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
