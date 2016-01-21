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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    if (![[DBSession sharedSession] isLinked]) {
//        [[DBSession sharedSession] linkFromController:self];
//    }
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([[DBSession sharedSession] isLinked]) {
        [self.restClient loadMetadata:@"/"];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)makeNoteClicked:(id)sender {

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MakeNoteViewController* obj = [sb instantiateViewControllerWithIdentifier:@"MakeNoteViewController"];
    
    obj.isEditing = NO;
    
    [self.navigationController pushViewController:obj animated:YES];
}

#pragma mark -
#pragma mark - Delegates for DBSession
-(void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{
    NSLog(@"Session fail");
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
            NSLog(@"	%@", file.filename);
            
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
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
        cell.textLabel.textColor = [UIColor whiteColor];
        
        UIImageView* separatorImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, cell.contentView.frame.size.height-1, self.tblNotes.frame.size.width, 1)];
        separatorImage.backgroundColor = [UIColor lightGrayColor];
        [cell.contentView addSubview:separatorImage];
    }
    
    DBMetadata* file = [self.arrayNotes objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
    NSString * filename = [file.filename substringToIndex:[file.filename length]-4];
    cell.textLabel.text=filename;//[self.arrayNotes objectAtIndex:indexPath.row];
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    DBMetadata* file = [self.arrayNotes objectAtIndex:indexPath.row];

    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [localDir stringByAppendingPathComponent:file.filename];

    [self.restClient loadFile:file.path intoPath:localPath];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    [tableView beginUpdates];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Do whatever data deletion you need to do...
        // Delete the row from the data source
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
                                     [self.restClient deletePath:file.path];
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                     [tableView endUpdates];
                                     [self.restClient loadMetadata:@"/"];
                                     [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//                                     [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];

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
