//
//  UIPopupView.m
//
//  Created by Nick Hodapp aka Tom Swift on 1/19/11.
//  Modified by onesecure on 1/12/17.
//

#import "UIPopupView.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark UIPopupOverlayWindow

@interface UIPopupOverlayWindow : UIWindow
@end

@implementation  UIPopupOverlayWindow {
    UIWindow *_oldKeyWindow;
}

- (void) makeKeyAndVisible {
    _oldKeyWindow = [[UIApplication sharedApplication] keyWindow];
    self.windowLevel = UIWindowLevelAlert;
    [super makeKeyAndVisible];
}

- (void) resignKeyWindow {
    [super resignKeyWindow];
    [_oldKeyWindow makeKeyWindow];
}

- (void) drawRect: (CGRect) rect {
    // render the radial gradient behind the alertview

    CGFloat width			= self.frame.size.width;
    CGFloat height			= self.frame.size.height;
    CGFloat locations[3]	= { 0.0, 0.5, 1.0 	};
    CGFloat components[12]	= {	1, 1, 1, 0.5,   0, 0, 0, 0.5,   0, 0, 0, 0.7 };

    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef backgroundGradient = CGGradientCreateWithColorComponents(colorspace, components, locations, 3);
    CGColorSpaceRelease(colorspace);

    CGPoint startCenter = CGPointMake(width/2, height/2);
    CGPoint endCenter = CGPointMake(width/2, height/2);
    CGFloat startRadius = 0.0f;
    CGFloat endRadius = sqrt(width*width + height*height) / 2.0f;
    CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), backgroundGradient, startCenter, startRadius, endCenter, endRadius, 0);

    CGGradientRelease(backgroundGradient);
}

- (void) dealloc {
    //NSLog( @"UIPopupOverlayWindow dealloc" );
}

@end


#pragma mark UIPopupViewController

@interface UIPopupViewController : UIViewController
@end

@implementation UIPopupViewController

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    UIPopupView *av = [self.view.subviews lastObject];
    if (!av || ![av isKindOfClass:[UIPopupView class]]) {
        return;
    }
    // resize the alertview if it wants to make use of any extra space (or needs to contract)
    [UIView animateWithDuration:duration animations:^{
        [av sizeToFit];
        av.center = CGPointMake( CGRectGetMidX( self.view.bounds ), CGRectGetMidY( self.view.bounds ) );;
        av.frame = CGRectIntegral( av.frame );
    }];
}

- (void) dealloc {
    //NSLog( @"UIPopupViewController dealloc" );
}

@end


#pragma mark UIPopupView

@interface UIPopupView (private)
@end

@implementation UIPopupView {
    UILabel*				_titleLabel;
    UILabel*				_messageLabel;

    NSMutableArray<UIView *> *_widgets;
    SimpleButton *_cancelButton;
    BOOL _usingCancelButton;

    UIPopupViewController *_avc;
    UIPopupOverlayWindow *_ow;

    CGFloat _width;
    CGFloat _maxHeight;
    CGFloat _maxHeightInternalChanged;
}

const CGFloat kUIPopupView_LeftMargin	= 10.0;
const CGFloat kUIPopupView_TopMargin	= 16.0;
const CGFloat kUIPopupView_BottomMargin = 15.0;
const CGFloat kUIPopupView_RowMargin	= 5.0;
const CGFloat kUIPopupView_ColumnMargin = 10.0;
const CGFloat kUIPopupView_MinWidth = 284;
const CGFloat kUIPopupView_MinHeight = 358;

- (instancetype) initWithFrame:(CGRect)frame {
    if ( ( self = [super initWithFrame: frame] ) ) {
        [self internalCommonInit];

        if ( !CGRectIsEmpty( frame ) ) {
            self.width = frame.size.width;
            _maxHeight = frame.size.height;
        }
    }
    return self;
}

- (instancetype) initWithTitle:(NSString *)t message:(NSString *)m delegate:(id<UIPopupViewDelegate>)delegate cancelButtonTitle:(NSString *)cancel // otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    if ( (self = [super init]) ) { // will call into initWithFrame, thus internalCommonInit is called
        self.title = t;
        self.message = m;
        _delegate = delegate;

        if ( nil != cancel ) {
            [_cancelButton setTitle:cancel forState:UIControlStateNormal];
            _usingCancelButton = YES;
        }

        /*
        if ( nil != otherButtonTitles ) {
            [self addButtonWithTitle: otherButtonTitles action:nil];

            va_list args;
            va_start(args, otherButtonTitles);

            id arg;
            while ( nil != ( arg = va_arg( args, id ) ) ) {
                if ( ![arg isKindOfClass:[NSString class]] ) {
                    return nil;
                }
                [self addButtonWithTitle:(NSString*)arg action:nil];
            }
        }
         */
    }
    return self;
}

- (CGSize) sizeThatFits: (CGSize) unused {
    return [self recalcSize];
}

- (void) sizeToFit {
    [super sizeToFit];
}

- (void) layoutSubviews {
    [self doLayoutSubviews];
}

- (void) dealloc {
    //NSLog( @"UIPopupView: dealloc" );
}

- (void) setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.layer.borderColor = backgroundColor.CGColor;
}

- (void) internalCommonInit {
    self.layer.cornerRadius = 7.;
    self.layer.borderWidth = .5;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];

    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    // defaults:
    _width = kUIPopupView_MinWidth;
    self.maxHeight = 0; // set to default

    _widgets = [NSMutableArray arrayWithCapacity:4];

    __weak typeof(self) weakSelf = self;
    _cancelButton = [SimpleButton simpleButtonWithAction:^(id sender) {
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf->_delegate respondsToSelector: @selector(alertViewCancel:)]) {
            [strongSelf->_delegate alertViewCancel:strongSelf];
        }
        [strongSelf dismissWithAnimated:YES];
    }];
    [_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];

    // need to watch for keyboard
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) setWidth:(CGFloat)width {
    if ( width <= 0 ) {
        width = kUIPopupView_MinWidth;
    }
    _width = MAX( width, kUIPopupView_MinWidth );
}

- (CGFloat) width {
    if ( nil == self.superview ) {
        return _width;
    }
    CGFloat maxWidth = self.superview.bounds.size.width - 20;
    return MIN( _width, maxWidth );
}

- (void) setMaxHeight:(CGFloat)maxHeight {
    _maxHeight = MAX(maxHeight, kUIPopupView_MinHeight);
    _maxHeightInternalChanged = _maxHeight;
}

- (CGFloat) maxHeight {
    if ( nil == self.superview ) {
        return _maxHeightInternalChanged;
    }
    return MIN( _maxHeightInternalChanged, self.superview.bounds.size.height - 20 );
}

- (void) onKeyboardWillShow:(NSNotification *)note {
    NSValue* v = [note.userInfo objectForKey: UIKeyboardFrameEndUserInfoKey];
    CGRect kbframe = [v CGRectValue];
    kbframe = [self.superview convertRect: kbframe fromView: nil];

    if ( CGRectIntersectsRect( self.frame, kbframe) ) {
        CGPoint c = self.center;

        if ( self.frame.size.height > kbframe.origin.y - 20 ) {
            _maxHeightInternalChanged = kbframe.origin.y - 20;
            [self sizeToFit];
            [self layoutSubviews];
        }

        c.y = kbframe.origin.y / 2;

        [UIView animateWithDuration: 0.2 animations: ^{
            self.center = c;
            self.frame = CGRectIntegral(self.frame);
        }];
    }
}

- (void) onKeyboardWillHide:(NSNotification *)note {
    _maxHeightInternalChanged = _maxHeight;
    [self sizeToFit];
    [self layoutSubviews];
    [UIView animateWithDuration: 0.2 animations: ^{
        self.center = CGPointMake( CGRectGetMidX( self.superview.bounds ), CGRectGetMidY( self.superview.bounds ));
        self.frame = CGRectIntegral(self.frame);
    }];
}

- (UILabel*) titleLabel {
    if ( _titleLabel == nil ) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize: 18];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UILabel*) messageLabel {
    if ( _messageLabel == nil ) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.font = [UIFont systemFontOfSize: 16];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _messageLabel.numberOfLines = 0;
    }
    return _messageLabel;
}

- (void) setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (NSString*) title {
    return self.titleLabel.text;
}

- (void) setMessage:(NSString *)message {
    self.messageLabel.text = message;
}

- (NSString*) message {
    return self.messageLabel.text;
}

- (BOOL) isVisible {
    return self.superview != nil;
}

- (id) addButtonWithTitle:(NSString *)title  action:(void(^)(id sender))action {
    SimpleButton *button = [SimpleButton simpleButtonWithAction:action];
    [button setTitle:title forState:UIControlStateNormal];
    [self addWidget:button];
    return button;
}

- (void) addWidget:(UIView *)widget {
    if ([widget isKindOfClass:[UIView class]]) {
        [_widgets addObject:widget];
        [self setNeedsLayout];
    }
}

- (void) dismissWithAnimated:(BOOL)animated {
    if ( animated ) {
        self.window.alpha = 1;
        [UIView animateWithDuration:0.5
                         animations:^{
                             [self.window resignKeyWindow];
                             self.window.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             [self releaseWindow];
                         }];
        [UIView commitAnimations];
    } else {
        [self.window resignKeyWindow];
        self.window.alpha = 0;
        [self releaseWindow];
    }
}

- (void) releaseWindow {
    // the one place we release the window we allocated in "show"
    // this will propogate releases to us (UIPopupView), and our UIPopupViewController
    _ow = nil;
    _avc = nil;
    _cancelButton = nil;
    [_widgets removeAllObjects];
    [self.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    [self removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) show {
    if (_usingCancelButton) {
        [_widgets addObject:_cancelButton];
    }

    [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:[NSDate date]];

    UIPopupViewController *avc = [[UIPopupViewController alloc] init];

    // $important - the window is released only when the user clicks an alert view button
    UIPopupOverlayWindow *ow = [[UIPopupOverlayWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
    ow.alpha = 0.0;
    ow.backgroundColor = [UIColor clearColor];
    ow.rootViewController = avc;
    [ow makeKeyAndVisible];

    // fade in the window
    [UIView animateWithDuration: 0.2 animations: ^{
        ow.alpha = 1;
    }];

    // add and pulse the alertview
    [avc.view addSubview: self];
    [self sizeToFit];
    self.center = CGPointMake( CGRectGetMidX( avc.view.bounds ), CGRectGetMidY( avc.view.bounds ) );;
    self.frame = CGRectIntegral( self.frame );
    [self pulse];

    _ow = ow;
    _avc = avc;
}

- (void) pulse {
    // pulse animation thanks to:  http://delackner.com/blog/2009/12/mimicking-uialertviews-animated-transition/
    self.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [UIView animateWithDuration:0.2
                     animations:^{ self.transform = CGAffineTransformMakeScale(1.1, 1.1); }
                     completion:^(BOOL finished)
     {
         [UIView animateWithDuration:1.0/15.0
                          animations:^{ self.transform = CGAffineTransformMakeScale(0.9, 0.9); }
                          completion:^(BOOL finished)
          {
              [UIView animateWithDuration:1.0/7.5 animations:^{
                  self.transform = CGAffineTransformIdentity;
              }];
          }];
     }];
}

- (BOOL) stacked {
    NSUInteger count = 0;
    for (UIView *obj in _widgets) {
        if ([obj isKindOfClass:[UIButton class]] || [obj isKindOfClass:[SimpleButton class]]) {
            count += 1;
        }
    }
    return (_widgets.count != count) || (count != 2);
}

- (CGSize) recalcSize {
    CGSize  titleLabelSize = [self calcSizeOfLabel:self.titleLabel];
    CGSize  messageViewSize = [self calcSizeOfLabel:self.messageLabel];
    CGSize  buttonsAreaSize = self.stacked ? [self buttonsAreaSize_Stacked] : [self buttonsAreaSize_SideBySide];

    BOOL msgExist = (self.message.length > 0);

    CGFloat totalHeight =
    kUIPopupView_TopMargin + titleLabelSize.height +
    (msgExist ? (kUIPopupView_RowMargin + messageViewSize.height) : 0) +
    kUIPopupView_RowMargin + buttonsAreaSize.height +
    kUIPopupView_BottomMargin;

    CGFloat maxHeight = self.maxHeight;

    if ( totalHeight > maxHeight ) {
        // too tall - we'll condense by using a textView (with scrolling) for the message
        if (msgExist) {
            messageViewSize.height = maxHeight - (totalHeight - messageViewSize.height);
        }
        totalHeight = maxHeight;
    }
    return CGSizeMake( self.width, totalHeight );
}

- (void) doLayoutSubviews {
    CGSize  titleLabelSize = [self calcSizeOfLabel:self.titleLabel];
    CGSize  messageViewSize = [self calcSizeOfLabel:self.messageLabel];

    CGFloat maxWidth = self.width - (kUIPopupView_LeftMargin * 2);

    // title
    CGFloat y = kUIPopupView_TopMargin;
    if ( self.title != nil ) {
        self.titleLabel.frame = CGRectMake( kUIPopupView_LeftMargin, y, titleLabelSize.width, titleLabelSize.height );
        [self addSubview: self.titleLabel];
        y += titleLabelSize.height + kUIPopupView_RowMargin;
    }

    // message
    if ( self.message.length > 0 ) {
        self.messageLabel.frame = CGRectMake( kUIPopupView_LeftMargin, y, messageViewSize.width, messageViewSize.height );
        [self addSubview: self.messageLabel];
        y += messageViewSize.height + kUIPopupView_RowMargin;
    }

    // buttons
    if ( self.stacked ) {
        for ( UIView *b in _widgets ) {
            CGFloat buttonHeight = b.frame.size.height; // [b sizeThatFits: CGSizeZero].height;
            b.frame = CGRectMake( kUIPopupView_LeftMargin, y, maxWidth, buttonHeight );
            [self addSubview: b];
            y += buttonHeight + kUIPopupView_RowMargin;
        }
    } else {
        CGFloat buttonWidth = (maxWidth - kUIPopupView_ColumnMargin) / 2.0;
        CGFloat x = kUIPopupView_LeftMargin;
        for ( UIView *b in _widgets ) {
            CGFloat buttonHeight = [b sizeThatFits: CGSizeZero].height;
            b.frame = CGRectMake( x, y, buttonWidth, buttonHeight );
            [self addSubview: b];
            x += buttonWidth + kUIPopupView_ColumnMargin;
        }
    }
}

- (CGSize) calcSizeOfLabel:(UILabel *)label {
    CGFloat maxWidth = self.width - (kUIPopupView_LeftMargin * 2);
    CGSize s = [label.text boundingRectWithSize:CGSizeMake(maxWidth, 1000)
                                        options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                     attributes:@{NSFontAttributeName:label.font}
                                        context:nil].size;
    if (s.width < maxWidth) {
        s.width = maxWidth;
    }
    return s;
}

- (CGSize) buttonsAreaSize_SideBySide {
    CGFloat maxWidth = self.width - (kUIPopupView_LeftMargin * 2);
    CGFloat height = [_cancelButton sizeThatFits: CGSizeZero].height;
    return CGSizeMake(maxWidth, height);
}

- (CGSize) buttonsAreaSize_Stacked {
    CGFloat maxWidth = self.width - (kUIPopupView_LeftMargin * 2);
    CGFloat height = 0;
    for (UIView *obj in _widgets) {
        height += obj.frame.size.height; // [obj sizeThatFits:CGSizeZero].height;
    }
    height += (kUIPopupView_RowMargin * (_widgets.count-1));
    return CGSizeMake(maxWidth, height);
}

@end


@implementation SimpleButton

NSMapTable<UIButton *, void (^)(id sender)> *actions = nil;

+ (instancetype) simpleButtonWithAction:(void (^)(id sender))action {
    if (actions == nil) {
        actions = [NSMapTable weakToStrongObjectsMapTable];
    }

    UIButton *btn = [super buttonWithType:UIButtonTypeSystem];
    [btn addTarget:self action:@selector(runButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    btn.layer.cornerRadius = 4.;
    btn.layer.borderWidth = .5;
    btn.layer.masksToBounds = YES;
    btn.layer.borderColor = [UIColor grayColor].CGColor;
    btn.frame = CGRectMake(0, 0, 200, 32);

    if (action) {
        [actions setObject:action forKey:btn];
    }

    return (SimpleButton *)btn;
}

- (void(^)(id sender)) action {
    return [actions objectForKey:self];
}

- (void) setAction:(void (^)(id))action {
    [actions setObject:action forKey:self];
}


- (void) dealloc {
    NSLog(@"SimpleButton: dealloc");
    [actions removeObjectForKey:self];
}

+ (void) runButtonAction:(UIButton *)sender {
    void (^action)(id sender) = [actions objectForKey:sender];
    if (action) {
        action(self);
    }
}

@end


@implementation TitledSwitch {
    __weak UILabel *_titleLabel;
    __weak UISwitch *_switch;
}

- (instancetype) initWithTitle:(NSString *)title action:(void (^)(BOOL on))action {
    if (self = [super init]) {
        _action = action;

        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.text = title;
        textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        textLabel.numberOfLines = 0;
        [self addSubview:textLabel];
        _titleLabel = textLabel;

        UISwitch *s = [[UISwitch alloc] init];
        [s addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:s];
        _switch = s;
    }
    return self;
}

- (void) valueChanged:(UISwitch *)sender {
    if (_action) {
        _action(sender.on);
    }
}

- (NSString *) title {
    return _titleLabel.text;
}

- (void) setTitle:(NSString *)title {
    _titleLabel.text = title;;
}

- (UIFont *) font {
    return _titleLabel.font;
}

- (void) setFont:(UIFont *)font {
    _titleLabel.font = font;
}

- (NSTextAlignment) textAlignment {
    return _titleLabel.textAlignment;
}

- (void) setTextAlignment:(NSTextAlignment)textAlignment {
    _titleLabel.textAlignment = textAlignment;
}

- (BOOL) on {
    return _switch.on;
}

- (void) setOn:(BOOL)on {
    _switch.on = on;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.frame.size;

    CGSize ss = _switch.frame.size;

    _switch.frame = CGRectMake(size.width-kUIPopupView_RowMargin-ss.width, (size.height-ss.height)/2, ss.width, ss.height);
    _titleLabel.frame = CGRectMake(kUIPopupView_RowMargin, kUIPopupView_RowMargin, size.width-3*kUIPopupView_RowMargin-ss.width, size.height-2*kUIPopupView_RowMargin);
}

@end


@implementation TitledSlider {
    __weak UISlider *_slider;
    __weak UILabel *_titleLabel;
}

- (instancetype) initWithTitle:(NSString *)title action:(void (^)(CGFloat))action {
    if (self = [super init]) {
        _action = action;

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = title;
        [self addSubview:titleLabel];
        _titleLabel = titleLabel;

        UISlider *slider = [[UISlider alloc] init];
        [slider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:slider];
        _slider = slider;
    }
    return self;
}

- (void) valueChanged:(UISlider *)sender {
    if (_action) {
        _action( (CGFloat) _slider.value);
    }
}

- (NSString *) title {
    return _titleLabel.text;
}

- (void) setTitle:(NSString *)title {
    _titleLabel.text = title;;
}

- (UIFont *) font {
    return _titleLabel.font;
}

- (void) setFont:(UIFont *)font {
    _titleLabel.font = font;
}

- (CGFloat) value {
    return _slider.value;
}

- (void) setValue:(CGFloat)value {
    _slider.value = value;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.frame.size;

    CGSize ts = [_titleLabel.text sizeWithAttributes:@{NSFontAttributeName:_titleLabel.font}];
    CGSize ss = _slider.frame.size;

    _titleLabel.frame = CGRectMake(kUIPopupView_RowMargin, kUIPopupView_RowMargin, ts.width, size.height-2*kUIPopupView_RowMargin);
    _slider.frame = CGRectMake(kUIPopupView_RowMargin*2+ts.width, (size.height-ss.height)/2, size.width-kUIPopupView_RowMargin*3-ts.width, ss.height);
}

@end


