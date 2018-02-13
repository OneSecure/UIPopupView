//
//  TSAVDemoViewController.h
//  TSAVDemo
//
//  Created by Nick Hodapp aka Tom Swift on 1/19/11.
//

#import <UIKit/UIKit.h>


@interface TSAVDemoViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
{
	IBOutlet UITextField*		_titleTextField;
	
	IBOutlet UITextView*		_messageTextView;
	
	IBOutlet UITextField*		_widthTextField;
	
	IBOutlet UITextField*		_maxHeightTextField;

	IBOutlet UITextField*		_buttonCountTextField;
}

- (void) onAddMore: (id) sender;

- (void) onShow: (id) sender;

@end
