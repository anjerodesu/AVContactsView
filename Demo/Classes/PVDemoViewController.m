//
//  PVDemoViewController.m
//  SSCatalog
//
//  Created by Sam Soffes on 9/8/10.
//  Copyright 2010 Sam Soffes. All rights reserved.
//

#import "PVDemoViewController.h"
#import "AVContactsViewController.h"

@implementation PVDemoViewController

#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Person";
	self.view.backgroundColor = [UIColor whiteColor];
	
	UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake( 20.0 , 100.0 , 280.0 , 40.0 )];
	[button setTitleColor: [UIColor colorWithRed: 15.0f / 255.0f green: 118.0f / 255.0f blue: 223.0f / 255.0f alpha: 1] forState: UIControlStateNormal];
	[button setTitle: @"Pick Person" forState: UIControlStateNormal];
	[button addTarget: self action: @selector( pickPerson: ) forControlEvents: UIControlEventTouchUpInside];
	button.titleLabel.font = [UIFont systemFontOfSize: 30.0f];
	[self.view addSubview: button];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
	}
	return YES;
}


#pragma mark Actions

- (void)pickPerson:(id)sender
{
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController  alloc] init];
	picker.peoplePickerDelegate = self;
	[self.navigationController presentViewController: picker animated: YES completion: nil];
}


#pragma mark ABPeoplePickerNavigationControllerDelegate

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
	[self.navigationController dismissViewControllerAnimated: YES completion: nil];
	
	AVContactsViewController *personViewController = [[AVContactsViewController alloc] initWithPerson:person addressBook:peoplePicker.addressBook];
	[self.navigationController pushViewController:personViewController animated:YES];
	
	return NO;
}


- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
	return NO;
}


- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
	[self.navigationController dismissViewControllerAnimated: YES completion: nil];
}

@end
