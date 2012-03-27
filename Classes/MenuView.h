//
//  MenuView.h
//  Free42
//
//  Created by Byron Foster on 5/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CalcViewController;
@interface MenuView : UIView {
	IBOutlet CalcViewController* calcViewController;
	IBOutlet UILabel* label1;
	IBOutlet UILabel* label2;
	IBOutlet UILabel* label3;
	IBOutlet UILabel* label4;
	IBOutlet UILabel* label5;
	IBOutlet UILabel* label6;
}
@property (nonatomic, retain) CalcViewController* calcViewController;
@property (nonatomic, retain) UILabel* label1;
@property (nonatomic, retain) UILabel* label2;
@property (nonatomic, retain) UILabel* label3;
@property (nonatomic, retain) UILabel* label4;
@property (nonatomic, retain) UILabel* label5;
@property (nonatomic, retain) UILabel* label6;
@end
