//
//  AVContactsHeaderView.h
//  SSToolkit
//
//  Created by Sam Soffes on 9/8/10.
//  Copyright 2010 Sam Soffes. All rights reserved.
//

@interface AVContactsHeaderView : UIView

@property (nonatomic, assign, getter = isAlignImageToLeft) BOOL alignImageToLeft;
@property (nonatomic, assign, getter = isOrganization) BOOL organization;
@property (strong, nonatomic, readonly) UIImageView *imageView;

@property (strong, nonatomic) UIImage *image;
@property (nonatomic, copy) NSString *personName;
@property (nonatomic, copy) NSString *organizationName;

@end
