//
//  AVContactsViewController.m
//  SSToolkit
//
//  Created by Sam Soffes on 9/8/10.
//  Copyright 2010 Sam Soffes. All rights reserved.
//

#import "AVContactsViewController.h"
#import "AVContactsHeaderView.h"
#import "AVContactsFooterView.h"
#import "AVContactsAddressTableViewCell.h"
#import <AddressBookUI/AddressBookUI.h>

NSInteger kAVContactsViewControllerDeleteActionSheetTag = 987;

@interface AVContactsViewController (PrivateMethods)

+ (NSString *)_formatLabel:(NSString *)rawLabel;

@end

@implementation AVContactsViewController

#pragma mark Class Methods

+ (NSString *)_formatLabel:(NSString *)rawLabel {
	NSString *label = nil;
	
	// Strip weird wrapper
	if ([rawLabel length] > 9 && [[rawLabel substringWithRange:NSMakeRange(0, 4)] isEqual:@"_$!<"]) {
		label = [rawLabel substringWithRange:NSMakeRange(4, [rawLabel length] - 8)];
	} else {
		label = [rawLabel copy];
	}
	
	// Lowercase unless iPhone
	if ([label isEqual:(NSString *)kABPersonPhoneIPhoneLabel] == NO) {
		label = [label lowercaseString];
	}
	
	// if label is custom, make sure to return a "custom" label instead of nil or null
	if ( label == (id)[NSNull null] || label.length == 0 )
	{
		label = @"custom";
	}
	
	return label;
}


#pragma mark NSObject

- (id)init {
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		_headerView = [[AVContactsHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 84.0)];
		_numberOfSections = 1;
		_rowCounts = [[NSMutableArray alloc] init];
		_cellData = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (void)dealloc
{
	if ( _personsAddressBook )
	{
		CFRelease( _personsAddressBook );
		_personsAddressBook = nil;
	}
	
	if ( _displayedPerson )
	{
		CFRelease( _displayedPerson );
		_displayedPerson = nil;
	}
	
}


#pragma mark Initializers

- (id)initWithPerson:(ABRecordRef)aPerson {
	self = [self initWithPerson:aPerson addressBook:nil];
	return self;
}


- (id)initWithPerson:(ABRecordRef)aPerson addressBook:(ABAddressBookRef)anAddressBook {
	if ((self = [self init])) {		
		if (aPerson) {
			self.displayedPerson = aPerson;
			
			if (anAddressBook) {
				self.addressBook = anAddressBook;
			}
		}
	}
	return self;
}


#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = @"Info";
	self.tableView.tableHeaderView = _headerView;
	
	_footerView = [[AVContactsFooterView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 74.0)];
	self.tableView.tableFooterView = _footerView;
}

#pragma mark Getters

- (ABAddressBookRef)addressBook {
	if (_personsAddressBook) {
		return _personsAddressBook;
	}
	
	// Create one if none exists	
	_personsAddressBook = ABAddressBookCreateWithOptions( nil , nil );
	return _personsAddressBook;
}


#pragma mark Setters

- (void)setAddressBook:(ABAddressBookRef)book {
	if (_personsAddressBook) {
		CFRelease(_personsAddressBook);
		_personsAddressBook = nil;
	}
	
	if (!book) {
		return;
	}
	
	_personsAddressBook = CFRetain(book);
}


- (void)setDisplayedPerson:(ABRecordRef)person {
	if (_displayedPerson) {
		CFRelease(_displayedPerson);
		_displayedPerson = nil;
	}
	
	if (!person) {
		return;
	}
	_displayedPerson = CFRetain(person);
	
	// Image
	if (ABPersonHasImageData(_displayedPerson)) {
		NSData *imageData = (NSData *)CFBridgingRelease(ABPersonCopyImageData(_displayedPerson));
		UIImage *image = [UIImage imageWithData:imageData];
		_headerView.image = image;
	} else {
		_headerView.image = nil;
	}
	
	// Name
	ABPropertyID nameProperties[] = {
		kABPersonPrefixProperty,
		kABPersonFirstNameProperty,
		kABPersonMiddleNameProperty,
		kABPersonLastNameProperty,
		kABPersonSuffixProperty
	};
	
	NSMutableArray *namePieces = [[NSMutableArray alloc] init];
	NSInteger namePiecesTotal = sizeof(nameProperties) / sizeof(ABPropertyID);
	for (NSInteger i = 0; i < namePiecesTotal; i++) {
		NSString *piece = (NSString *)CFBridgingRelease(ABRecordCopyValue(_displayedPerson, nameProperties[i]));
		if (piece) {
			[namePieces addObject:piece];
		}
	}
	
	_headerView.personName = [namePieces componentsJoinedByString:@" "];
	
	// Organization
	NSString *organizationName = (NSString *)CFBridgingRelease(ABRecordCopyValue(_displayedPerson, kABPersonOrganizationProperty));
	_headerView.organizationName = organizationName;
	
	// Multivalues
	_numberOfSections = 0;
	[_rowCounts removeAllObjects];
	ABPropertyID multiProperties[] = {
		kABPersonPhoneProperty,
		kABPersonEmailProperty,
		kABPersonURLProperty,
		kABPersonAddressProperty
	};
	
	NSInteger multiPropertiesTotal = sizeof(multiProperties) / sizeof(ABPropertyID);
	for (NSInteger i = 0; i < multiPropertiesTotal; i++) {
		// Get values count
		ABPropertyID property = multiProperties[i];
		ABMultiValueRef valuesRef = ABRecordCopyValue(_displayedPerson, property);
		NSInteger valuesCount = 0;
		if (valuesRef != nil) valuesCount = ABMultiValueGetCount(valuesRef);
		
		if (valuesCount > 0) {
			_numberOfSections++;
			[_rowCounts addObject:@(valuesCount)];
		} else {
			//CFRelease(valuesRef);
			continue;
		}
		
		// Loop through values
		for (NSInteger k = 0; k < valuesCount; k++) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:k inSection:_numberOfSections - 1];
			
			// Get label
			NSString *rawLabel = (NSString *)CFBridgingRelease(ABMultiValueCopyLabelAtIndex(valuesRef, k));
			NSString *label = [[self class] _formatLabel:rawLabel];
			
			// Get value
			NSString *value = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(valuesRef, k));
			
			// Merge address dictionary
			if (i == 3 && [value isKindOfClass:[NSDictionary class]]) {
				NSDictionary *addressDictionary = (NSDictionary *)value;
				
				NSMutableString *addressString = [[NSMutableString alloc] init];
				
				NSString *street = addressDictionary[(NSString *)kABPersonAddressStreetKey];
				NSString *city = addressDictionary[(NSString *)kABPersonAddressCityKey];
				NSString *state = addressDictionary[(NSString *)kABPersonAddressStateKey];
				NSString *zip = addressDictionary[(NSString *)kABPersonAddressZIPKey];
				NSString *country = addressDictionary[(NSString *)kABPersonAddressCountryKey];
				
				// Street
				if (street) {
					[addressString appendString:street];
				}
				
				// City
				if (city) {
					if ([addressString length] > 0) {
						[addressString appendString:@"\n"];
					}
					[addressString appendString:city];
				}
				
				// State
				if (state) {
					if ([addressString length] > 0) {
						[addressString appendString:(city ? @" " : @"\n")];
					}
					[addressString appendString:state];
				}
				
				// Zip
				if (zip) {
					if ([addressString length] > 0) {
						[addressString appendString:(state || city ? @" " : @"\n")];
					}
					[addressString appendString:zip];
				}
				
				// Country
				if (country) {
					if ([addressString length] > 0) {
						[addressString appendString:@"\n"];
					}
					[addressString appendString:country];
				}
				
				value = addressString;
			}
			
			// Get url
			NSURL *urlString = nil;
			switch (i) {
					// Phone number
				case 0: {
					NSString *cleanedValue = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
					cleanedValue = [cleanedValue stringByReplacingOccurrencesOfString:@"-" withString:@""];
					cleanedValue = [cleanedValue stringByReplacingOccurrencesOfString:@"(" withString:@""];
					cleanedValue = [cleanedValue stringByReplacingOccurrencesOfString:@")" withString:@""];
					urlString = [NSURL URLWithString: [NSString stringWithFormat:@"tel://%@", cleanedValue]];
					break;
				}
					
					// Email
				case 1: {
					urlString = [NSURL URLWithString: [NSString stringWithFormat:@"mailto:%@", value]];
					break;
				}
					
					// URL
				case 2: {
					urlString = [NSURL URLWithString: value];
					break;
				}
					
					// Address
				case 3: {
					// This functionality is in SSToolkit's NSString category, but I wanted to remove and external
					// dependencies, so it's implemention is copied here.
					NSString *urlEncodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)value,
																									 NULL, CFSTR("!*'();:@&=+$,/?%#[]"),
																									 kCFStringEncodingUTF8));
					urlString = [NSURL URLWithString: [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", urlEncodedString]];
					break;
				}
			}
			
			// should check first if object is nil
			// if it is nil, inserting it to the dictionary will result to an error
			// so make sure to insert a non-nil object
			if ( urlString == nil )
				urlString = [NSURL URLWithString: @""];
			
			// Add dictionary to cell data
			NSDictionary *dictionary = @{@"label": label,
										@"value": value,
										@"url": urlString,
										@"property": @(property)};
			_cellData[indexPath] = dictionary;
		}
		
		CFRelease(valuesRef);
	}
	
	// Note
	NSString *note = (NSString *)CFBridgingRelease(ABRecordCopyValue(_displayedPerson, kABPersonNoteProperty));
	if (note) {
		_numberOfSections++;
		[_rowCounts addObject:@1];
		
		NSDictionary *noteDictionary = @{@"label": @"notes",
										@"value": note,
										@"property": @(kABPersonNoteProperty)};
		_cellData[[NSIndexPath indexPathForRow:0 inSection:_numberOfSections - 1]] = noteDictionary;
	}
	
	// Reload table
	if (_numberOfSections < 1) {
		_numberOfSections = 1;
	}
	[self.tableView reloadData];
}


#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return _numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if ([_rowCounts count] == 0) {
		return 0;
	}
	return [_rowCounts[section] integerValue];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *valueCellIdentifier = @"valueCellIdentifier";
	static NSString *addressValueCellIdentifier = @"addressValueCellIdentifier";
	
	NSDictionary *cellDictionary = _cellData[indexPath];
	UITableViewCell *cell = nil;
	
	if ([cellDictionary[@"property"] integerValue] == kABPersonAddressProperty) {
		cell = [tableView dequeueReusableCellWithIdentifier:addressValueCellIdentifier];
		if (!cell) {
			cell = [[AVContactsAddressTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:addressValueCellIdentifier];
		}
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:valueCellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:valueCellIdentifier];
		}
	}
	
	cell.textLabel.text = cellDictionary[@"label"];
	cell.detailTextLabel.text = cellDictionary[@"value"];
	cell.selectionStyle = [[UIApplication sharedApplication] canOpenURL:cellDictionary[@"url"]] ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
	
	return cell;
}


#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *cellDictionary = _cellData[indexPath];
	if ([cellDictionary[@"property"] integerValue] == kABPersonAddressProperty) {
		return [AVContactsAddressTableViewCell heightForDetailText:cellDictionary[@"value"] tableWidth:self.tableView.frame.size.width];
	}
	return 44.0;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary *cellDictionary = _cellData[indexPath];
	[[UIApplication sharedApplication] openURL:cellDictionary[@"url"]];
}


#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (actionSheet.tag != kAVContactsViewControllerDeleteActionSheetTag) {
		return;
	}
	
	// Delete person
	ABAddressBookRemoveRecord(self.addressBook, self.displayedPerson, nil);
	ABAddressBookSave(self.addressBook, nil);
	[self.navigationController popViewControllerAnimated:YES];	
}

@end
