//
//  PageViewControllerWrapper.m
//  Baker
//
//  Created by James Campbell on 04/11/2012.
//
//

#import "PageViewControllerWrapper.h"

@interface PageViewControllerWrapper ()

@end

@implementation PageViewControllerWrapper

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        
        // ***** PAGEVIEWCONTROLLER INIT
        
        _pageViewController = [[[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil] retain];
        _pageViewController.dataSource = self;
        _pageViewController.delegate = self;
        
        self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    }
    return self;
}

- (void)viewDidLoad{
    //Setup Page View Controller
    [self.view addSubview: _pageViewController.view];
    [self addChildViewController:_pageViewController];
    [_pageViewController isMovingToParentViewController];
}

- (void)setViewControllers:(NSArray *)viewControllers direction:(BakerWrapperNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion{
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        NSLog(@"Page View Controller Setup");
    }];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    
    if (!_pageViewInTransition){
        id newPage = [self.dataSource wrapperViewController:self viewControllerBeforeViewController:(PageViewController*)viewController];
   
        if (newPage){
            _pageViewInTransition = [newPage retain];
        }
    }
    
    return _pageViewInTransition;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{

    
    if (!_pageViewInTransition){
        id newPage = [self.dataSource wrapperViewController:self viewControllerAfterViewController:(PageViewController*)viewController];
        
        if (newPage){
            _pageViewInTransition = [newPage retain];
        }
    }
    
    return _pageViewInTransition;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{
    
    [self.delegate wrapperViewController:self didFinishAnimating:finished previousViewControllers:previousViewControllers transitionCompleted:completed];

    if (_pageViewInTransition){
        [_pageViewInTransition release];
        _pageViewInTransition = nil;
    }
    
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController{
    return [self.dataSource presentationCountForWrapperViewController:self];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController{
    return [self.dataSource presentationIndexForWrapperViewController:self];
}

- (NSArray *)viewControllers{
    return _pageViewController.viewControllers;
}

@end
