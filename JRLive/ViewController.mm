//
//  ViewController.m
//  JRLive
//
//  Created by fan on 2020/9/25.
//

#import "ViewController.h"
#import "JRLivePreview.h"



@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:[[JRLivePreview alloc] initWithFrame:self.view.bounds]];
    });
}


@end
