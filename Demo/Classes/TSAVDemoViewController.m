//
//  TSAVDemoViewController.m
//  TSAVDemo
//
//  Created by Nick Hodapp aka Tom Swift on 1/19/11.
//

#import "TSAVDemoViewController.h"
#import "UIPopupView.h"

@implementation TSAVDemoViewController {
    UIPopupView *_av;
    NSUserDefaults *_settings;
    __weak IBOutlet UILabel *_titledSwitchValue;
    __weak IBOutlet UILabel *_titledSliderValue;
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    _settings = [NSUserDefaults standardUserDefaults];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void) onAddMore:(id)sender
{
}

- (void) onShow:(id)sender {
	[_messageTextView resignFirstResponder];
	[_titleTextField resignFirstResponder];
	[_widthTextField resignFirstResponder];
	[_maxHeightTextField resignFirstResponder];

#if 0
    UIPopupView *av = [[UIPopupView alloc] init];
    av.title = _titleTextField.text;
    av.message = _messageTextView.text;
#else
    UIPopupView *av = [[UIPopupView alloc] initWithTitle:_titleTextField.text message:_messageTextView.text delegate:nil cancelButtonTitle:@"取消"];
#endif
    _av = av;

	for ( int i = 0 ; i < [_buttonCountTextField.text intValue] ; i++ ) {
        __weak typeof(av) weakAv = av;
		[av addButtonWithTitle: [NSString stringWithFormat: @"Button %d", i] action:^(id sender) {
            __strong typeof(av) strongAv = weakAv;
            [strongAv dismissWithAnimated:YES];
        }];
	}

	av.width = [_widthTextField.text floatValue];
	av.maxHeight = [_maxHeightTextField.text floatValue];

    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 60)];
    tv.layer.cornerRadius = 4.;
    tv.layer.borderWidth = .5;
    tv.layer.masksToBounds = YES;
    tv.layer.borderColor = [UIColor grayColor].CGColor;
    [av addWidget:tv];

    UISwitch *s = [[UISwitch alloc] init];
    [s addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [av addWidget:s];

    UISlider *slider = [[UISlider alloc] init];
    [slider addTarget:self action:@selector(sliderChange:) forControlEvents:UIControlEventValueChanged];
    [av addWidget:slider];

    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 34)];
    tf.layer.cornerRadius = 4.;
    tf.layer.borderWidth = .5;
    tf.layer.masksToBounds = YES;
    tf.layer.borderColor = [UIColor grayColor].CGColor;
    [av addWidget:tf];

    TitledSwitch *ts = [[TitledSwitch alloc] initWithTitle:@"Enabled" action:^(BOOL on) {
        NSLog(@"TitledSwitch value: %d\n", on);
        [_settings setBool:on forKey:@"titledSwitchValue"];
        _titledSwitchValue.text = [NSString stringWithFormat:@"%d", on];
    }];
    ts.frame = CGRectMake(0, 0, 200, 44);
    ts.textAlignment = NSTextAlignmentRight;
    ts.on = [_settings boolForKey:@"titledSwitchValue"];
    _titledSwitchValue.text = [NSString stringWithFormat:@"%d", ts.on];
    [av addWidget:ts];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.layer.cornerRadius = 4.;
    btn.layer.borderWidth = .5;
    btn.layer.masksToBounds = YES;
    btn.layer.borderColor = [UIColor grayColor].CGColor;
    btn.frame = CGRectMake(0, 0, 200, 32);
    [btn setTitle:@"holy shit" forState:(UIControlStateNormal)];
    [btn addTarget:self action:@selector(doExit:) forControlEvents:UIControlEventTouchUpInside];
    [av addWidget:btn];

    TitledSlider *titledSlider = [[TitledSlider alloc] initWithTitle:@"Value" action:^(CGFloat value) {
        NSLog(@"TitledSlider value: %f\n", value);
        [_settings setFloat:value forKey:@"titledSliderValue"];
        _titledSliderValue.text = [NSString stringWithFormat:@"%f", value];
    }];
    titledSlider.frame = CGRectMake(0, 0, 200, 44);
    titledSlider.value = [_settings floatForKey:@"titledSliderValue"];
    _titledSliderValue.text = [NSString stringWithFormat:@"%f", titledSlider.value];
    [av addWidget:titledSlider];

	[av show];
}

- (void) doExit:(id)sender {
    [_av dismissWithAnimated:YES];
}

- (void) valueChanged:(UISwitch *)sender {
    NSLog(@"==== %d ====\n", sender.on);
}

- (void) sliderChange:(UISlider *)slider {
    NSLog(@"---- %f ----\n", slider.value);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    //[super dealloc];
}


@end
