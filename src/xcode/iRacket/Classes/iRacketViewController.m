//
//  iRacketViewController.m
//  iRacket
//
//  Created by nevo on 10-10-24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "scheme.h"
#import "iGRacketViewController.h"
#import "iRacketViewController.h"

@implementation iRacketViewController


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


extern int test_main(int argc, char *argv[]);

- (IBAction)launchRacket
{
    char *argv[1] = {
        "(current-library-collection-paths)"
    };

    test_main(1, argv);
}

- (IBAction)launchGRacket
{
    iGRacketViewController *iGracket =
        [[iGRacketViewController alloc]
            initWithNibName:@"iGRacketViewController"
                     bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc]
                                      initWithRootViewController:iGracket];
    [self presentModalViewController:nav
                            animated:YES];
    [iGracket release];
    [nav release];
}


@end