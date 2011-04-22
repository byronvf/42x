//
//  ServerViewController.h
//  Free42
//
//  Created by Byron Foster on 3/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ServerViewController : UIViewController {
	IBOutlet UILabel* addressLabel;	
}

@property (nonatomic, retain) UILabel* addressLabel;

- (void)startServer;
- (void)stopServer;

@end
