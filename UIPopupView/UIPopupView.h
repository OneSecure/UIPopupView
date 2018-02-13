//
//  UIPopupView.h
//
//  Created by Nick Hodapp aka Tom Swift on 1/19/11.
//  Modified by onesecure on 1/12/17.
//


#import <UIKit/UIKit.h>

@class UIPopupView;

@protocol UIPopupViewDelegate <NSObject>
@optional

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void) alertView:(UIPopupView *)alertView clickedButton:(id)sender;

// Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
// If not defined in the delegate, we simulate a click in the cancel button
- (void) alertViewCancel:(UIPopupView *)alertView;

- (void) willPresentAlertView:(UIPopupView *)alertView;  // before animation and showing view
- (void) didPresentAlertView:(UIPopupView *)alertView;  // after animation

- (void) alertView:(UIPopupView *)alertView willDismissWithButton:(id)sender; // before animation and hiding view
- (void) alertView:(UIPopupView *)alertView didDismissWithButton:(id)sender;  // after animation

@end


@interface UIPopupView : UIView
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, assign) id<UIPopupViewDelegate> delegate;
@property(nonatomic, readonly, getter=isVisible) BOOL visible;

@property(nonatomic, assign) CGFloat width;
@property(nonatomic, assign) CGFloat maxHeight;

- (instancetype) initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<UIPopupViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle; // otherButtonTitles:(NSString *)otherButtonTitles, ...;
- (id) addButtonWithTitle:(NSString *)title action:(void(^)(id sender))action;
- (void) addWidget:(UIView *)widget;
- (void) dismissWithAnimated:(BOOL)animated;
- (void) show;
@end


@interface SimpleButton : UIButton
+ (instancetype) simpleButtonWithAction:(void (^)(id sender))action;
@property(nonatomic, strong) void (^action)(id sender);
@end

@interface TitledSwitch : UIView
- (instancetype) initWithTitle:(NSString *)title action:(void(^)(BOOL on))action;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) UIFont *font;
@property(nonatomic, assign) NSTextAlignment textAlignment;
@property(nonatomic, assign) BOOL on;
@property(nonatomic, strong) void (^action)(BOOL on);
@end

@interface TitledSlider : UIView
- (instancetype) initWithTitle:(NSString *)title action:(void(^)(CGFloat value))action;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) UIFont *font;
@property(nonatomic, assign) CGFloat value;
@property(nonatomic, strong) void (^action)(CGFloat value);
@end
