    //
//  ViewController.m
//  dropBoxDemo
//
//  Created by Jagruti Valera on 21/01/16.
//  Copyright © 2016 Jagruti Valera. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD.h"
#import "MakeNoteViewController.h"
#import "Reachability.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];// iniate rest
    self.restClient.delegate = self;

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self loadDBMetadata];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark -
#pragma mark - Click Actions and Other methods
- (IBAction)makeNoteClicked:(id)sender {

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MakeNoteViewController* obj = [sb instantiateViewControllerWithIdentifier:@"MakeNoteViewController"];
    obj.isEditing = NO;
    [self.navigationController pushViewController:obj animated:YES];
}

-(void)loadDBMetadata{
    Reachability *reachability	= [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        [self showAlertWithTitle:@"No Internet" AndMessage:@"To continue this process you need internet connection. Please check your internet connectivity"];
    }
    else
    {
        [self.restClient loadMetadata:@"/"];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

// utility method to show alert
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



#pragma mark -
#pragma mark - Delegates for DropBox
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    [MBProgressHUD hideHUDForView:self.view animated:YES];

}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);
    [MBProgressHUD hideHUDForView:self.view animated:YES];

}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        self.arrayNotes = [NSMutableArray arrayWithCapacity:0];

        for (DBMetadata *file in metadata.contents) {
            if ([file.filename hasSuffix:@".txt"]) {
                [self.arrayNotes addObject:file];
            }
        }
        [self.tblNotes reloadData];
    }
    [MBProgressHUD hideHUDForView:self.view animated:YES];

}

- (void)restClient:(DBRestClient *)client
loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}
- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath
       contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    NSString* content = [NSString stringWithContentsOfFile:localPath
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MakeNoteViewController* obj = [sb instantiateViewControllerWithIdentifier:@"MakeNoteViewController"];
    
    obj.file = metadata;
    obj.isEditing = YES;
    obj.strContent = content;
    obj.strLocalPath = localPath;
    
    [self.navigationController pushViewController:obj animated:YES];

}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    NSLog(@"There was an error loading the file: %@", error);
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

#pragma mark -
#pragma mark - Delegate and Datasource for Tableview
-(NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    return [self.arrayNotes count];
    
}
-(UITableViewCell *)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        // Cell UI
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
        cell.textLabel.textColor = [UIColor whiteColor];
        
        // ADDED separator image into the cell
        UIImageView* separatorImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, cell.contentView.frame.size.height-1, self.tblNotes.frame.size.width, 1)];
        [separatorImage setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        separatorImage.backgroundColor = [UIColor lightGrayColor];
        [cell.contentView addSubview:separatorImage];
    }
    
    DBMetadata* file = [self.arrayNotes objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
    NSString * filename = [file.filename substringToIndex:[file.filename length]-4];// removed extension ".txt"
    cell.textLabel.text=filename;
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    DBMetadata* file = [self.arrayNotes objectAtIndex:indexPath.row];

    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [localDir stringByAppendingPathComponent:file.filename];

    Reachability *reachability	= [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
    {
        [self showAlertWithTitle:@"No Internet" AndMessage:@"To continue this process you need internet connection. Please check your internet connectivity"];
    }
    else
    {
        [self.restClient loadFile:file.path intoPath:localPath];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }

}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    [tableView beginUpdates];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        DBMetadata* file = [self.arrayNotes objectAtIndex:indexPath.row];
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
                                         [self.restClient deletePath:file.path];// will delete file from Dropbox
                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                         [tableView endUpdates];
                                         [self loadDBMetadata];
                                     }

                                 }];
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [tableView endUpdates];
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
        
        [alert addAction:delete];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
