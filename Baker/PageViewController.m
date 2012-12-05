
//
//  PageViewController.m
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//

#import "PageViewController.h"

@interface PageViewController ()

@end

@implementation PageViewController

- (id)initWithFrame:(CGRect)frame andPageURL:(NSString*)pageURL;
{
    self = [super init];
    if (self) {
        //Setup View Size for Page
        self.view.frame = frame;
        self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
        
        //Load the Page
        [self loadPage:pageURL];
    }
    
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // ****** INIT PROPERTIES
    _properties = [[Properties properties] retain];
    
    //Get Page Number Alpha
    _pageNumberAlpha = [[_properties get:@"-baker-page-numbers-alpha", nil] retain];
    
    //Get Page Number Color
    _pageNumberColor = [[Utils colorWithHexString:[_properties get:@"-baker-page-numbers-color", nil]] retain];
    
    // ****** Background Image
    _backgroundImageView = [[[UIImageView alloc] initWithFrame:self.view.bounds] retain];
    _backgroundImageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    
    [self.view addSubview:_backgroundImageView];
    
    // ****** Activity Indicator
    _activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] retain];
    _activityIndicatorView.backgroundColor = [UIColor clearColor];
    _activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);
    
    [_activityIndicatorView sizeToFit];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
            _activityIndicatorView.color = _pageNumberColor;
            _activityIndicatorView.alpha = [_pageNumberAlpha floatValue];
    };
    
    [self.view addSubview:_activityIndicatorView];
    
    [_activityIndicatorView startAnimating];
    [_activityIndicatorView setHidden:NO];
    
    // ****** Numbers
    _numberLabel = [[[UILabel alloc] init] retain];
    _numberLabel.backgroundColor = [UIColor clearColor];
    _numberLabel.font = [UIFont fontWithName:@"Helvetica" size:40.0];
    _numberLabel.text = @"0";
    _numberLabel.textColor = _pageNumberColor;
    _numberLabel.textAlignment = UITextAlignmentCenter;
    _numberLabel.alpha = [_pageNumberAlpha floatValue];
    _numberLabel.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);
    [self.view addSubview:_numberLabel];
}

- (void)viewWillAppear:(BOOL)animated{
    //Make Sure Number Label is updated to show relevant page number
    _numberLabel.text = [NSString stringWithFormat:@"%d", self.tag];
    
    [self updateLayout];
    [self updateBackgroundImageToOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void)updateLayout{
    // ****** Activity Indicator
    CGSize pageSize = self.view.bounds.size;
    CGRect frame = _activityIndicatorView.frame;
    
    frame.origin.x = (pageSize.width - frame.size.width) / 2;
    frame.origin.y = (pageSize.height - frame.size.height) / 2;
    
    _activityIndicatorView.frame = frame;
    
    // ****** Numbers
    _numberLabel.frame = CGRectMake((pageSize.width - 115) / 2, pageSize.height / 2 - 55, 115, 30);
    
    // ****** Title
    [_titleLabel setX:((pageSize.width - _titleLabel.frame.size.width) / 2) Y:(pageSize.height / 2 + 20)];

}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setWebViewCorrectOrientation:toInterfaceOrientation];
    [self updateBackgroundImageToOrientation:toInterfaceOrientation];
}

- (void)updateBackgroundImageToOrientation:(UIInterfaceOrientation)orientation{
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        NSLog(@"Page View Using Landscape Image");
        _backgroundImageView.image = _backgroundImageLandscape;
    } else {
        NSLog(@"Page View Using Potrait Image");
        _backgroundImageView.image = _backgroundImagePortrait;
    }
}

- (void)loadPage:(NSString*)pageURL{

    [self setLoadingUIHidden:NO];
    
    //Remove and Release Exsisting Title Label if it exsists already
    if (_titleLabel){
        [_titleLabel removeFromSuperview];
        [_titleLabel release];
        _titleLabel = nil;
    }
    
    _titleLabel = [[[PageTitleLabel alloc]initWithFile:pageURL] retain];
    _titleLabel.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);
    [self.view addSubview:_titleLabel];
    
    // ****** Webview
    
    //Remove and Release Exsisting Web View if it exsists already
    if (_webView){
        [_webView removeFromSuperview];
        [_webView release];
        _webView = nil;
    }
    
     NSLog(@"• Setup webView");
    
    _webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] retain];
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    _webView.delegate = self;
    _webView.alpha = 0.0f;
    _webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    
    _webView.mediaPlaybackRequiresUserAction = ![[_properties get:@"-baker-media-autoplay", nil] boolValue];
    _webView.scalesPageToFit = [[_properties get:@"zoomable", nil] boolValue];
    
    BOOL verticalBounce = [[_properties get:@"-baker-vertical-bounce", nil] boolValue];
        
        for (UIView *subview in _webView.subviews) {
            if ([subview isKindOfClass:[UIScrollView class]]) {
                ((UIScrollView *)subview).bounces = verticalBounce;
            }
        }
    
    NSString *path = [NSString stringWithString:pageURL];
    
    [self.delegate pageViewControllerWillLoadPage:self];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"• Loading: book/%@", [[NSFileManager defaultManager] displayNameAtPath:path]);
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    }
    
    [self.view addSubview:_webView];
}

- (void)setLoadingUIHidden:(bool)hidden{
    _backgroundImageView.hidden = hidden;
    _numberLabel.hidden = hidden;
    _activityIndicatorView.hidden = hidden;
    _titleLabel.hidden = hidden;
}

- (void)setTag:(int)tag{
    self.view.tag = tag;
}

- (int)tag{
    return self.view.tag;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"• Page did start load");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // Sent if a web view failed to load content.
    NSLog(@"• Failed to load content for Page %i with error: %@", self.tag, error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    [self.delegate pageViewControllerDidLoadPage:self];
    
    _webView.userInteractionEnabled = YES;
    
    //Get Size Of Page
    CGSize fittingSize = [_webView sizeThatFits:CGSizeZero];
    
    //Get Real Page Height (We need to work out the orientation of the Device)
    int pageHeight = ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown) ? fittingSize.height : fittingSize.width;
    
    _webView.frame = CGRectMake(0, 0, self.view.bounds.size.width, pageHeight);
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")){
        _webView.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, pageHeight);
    }
    
    if (_webView.alpha == 0.0f)
    {
        [UIView animateWithDuration:0.5
                         animations:^{ _webView.alpha = 1.0; }
                         completion:^(BOOL finished) {
                             [self setLoadingUIHidden:YES];
        }];
        
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return [self.delegate pageViewController:self shouldStartPageLoadWithRequest:request navigationType:navigationType];
}

- (void)setWebViewCorrectOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    // Since the UIWebView doesn't handle orientationchange events correctly we have to set the correct value for window.orientation property ourselves
    NSString *jsOrientationGetter;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return 0; });";
            break;
        case UIInterfaceOrientationLandscapeLeft:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return 90; });";
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return 180; });";
            break;
        case UIInterfaceOrientationLandscapeRight:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return -90; });";
            break;
        default:
            break;
    }
    
    [_webView stringByEvaluatingJavaScriptFromString:jsOrientationGetter];
}

/*
 
 - (void)webViewDidAppear:(UIWebView *)webView animating:(BOOL)animating {
 
 if ([webView isEqual:currPage])
 {
 [self webView:webView dispatchHTMLEvent:@"focus"];
 
 // If is the first time i load something in the currPage web view...
 if (currentPageFirstLoading)
 {
 // ... check if there is a saved starting scroll index and set it
 NSLog(@"   Handle last scroll index if necessary");
 NSString *currPageScrollIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastScrollIndex"];
 if (currPageScrollIndex != nil) {
 [self scrollDownCurrentPage:[currPageScrollIndex intValue] animating:YES];
 }
 currentPageFirstLoading = NO;
 }
 else
 {
 NSLog(@"   Handle saved hash reference if necessary");
 [self handleAnchor:YES];
 }
 }
 } */

- (void)dealloc {
    
    [self.delegate pageViewControllerWillUnloadPage:self];
    
    self.delegate = nil;
    
    if(_backgroundImageLandscape){
       [_backgroundImageLandscape release]; 
    }
    
    if(_backgroundImagePortrait){
        [_backgroundImagePortrait release];
    }
    
    [_pageNumberAlpha release];
    [_pageNumberColor release];
    [_backgroundImageView release];
    [_numberLabel release];
    [_activityIndicatorView release];
    [_titleLabel release];
    [_webView setDelegate:nil];
    [_webView stopLoading];
    [_webView release];
    
    [super dealloc];
}

@end
