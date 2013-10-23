# AVContactsView

Clone of Apple's `ABPerson` view controller in `AddressBookUI.framework` to allow for better customisation.

## Installing

1. Copy all of the classes and images to your project (except the contents of the *Demo* folder of course)
2. Add `AddressBook.framework` and `AddressBookUI.framework` to your target

## Usage

Simply initialise the view controller with the person and address book.

    AVContactsView *personViewController = [[AVContactsView alloc] initWithPerson: person addressBook: addressBook];
    [self.navigationController pushViewController: personViewController animated: YES];

See the demo project for further examples.

## History

`AVContactsView` was a forked project `SSPersonViewController` but the original developer stop updating the code.

## Updates

**2013/19/10**    
- Fixed known bugs and errors
- iOS 7 Support
- Removed Edit and Delete function

## Bugs

Please browse [Issues](https://github.com/anjerodesu/AVContactsView/issues) of the project page to view all known issues. If you find anything that is not yet submitted, please do so.
