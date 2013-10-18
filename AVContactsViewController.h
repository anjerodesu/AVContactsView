//
//  AVContactsViewController.h
//  SSToolkit
//
//  Created by Sam Soffes on 9/8/10.
//  Copyright 2010 Sam Soffes. All rights reserved.
//

#import <AddressBook/AddressBook.h>

@class AVContactsHeaderView;
@class AVContactsFooterView;

extern NSInteger kAVContactsViewControllerDeleteActionSheetTag;

@interface AVContactsViewController : UITableViewController <UIActionSheetDelegate>

@property (nonatomic, assign) ABRecordRef displayedPerson;
@property (nonatomic, assign) ABAddressBookRef personsAddressBook;

@property (strong, nonatomic) AVContactsHeaderView *headerView;
@property (strong, nonatomic) AVContactsFooterView *footerView;
@property (nonatomic, assign) NSInteger numberOfSections;
@property (strong, nonatomic) NSMutableArray *rowCounts;
@property (strong, nonatomic) NSMutableDictionary *cellData;

- (id)initWithPerson:(ABRecordRef)aPerson;
- (id)initWithPerson:(ABRecordRef)aPerson addressBook:(ABAddressBookRef)anAddressBook;

@end
