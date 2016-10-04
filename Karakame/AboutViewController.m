//
//  AboutViewController.m
//  ArtCritic
//
//  Created by Douwe Osinga on 9/18/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

#import "AboutViewController.h"
#import <UIKit/UIKit.h>

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UITextView *acknowledgements;

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    NSArray *tuples = @[@[@"Cool-iOS-Camera", @"https://github.com/GabrielAlva/Cool-iOS-Camera",
                          @"OpenCV", @"http://opencv.org/"],
                        ];
    NSString *str = [self.acknowledgements.attributedText string];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.acknowledgements.attributedText];
    for (NSArray *tuple in tuples) {
        NSRange r = [str rangeOfString:tuple[0]];
        if (r.location != NSNotFound) {
            [attributedText addAttribute:NSLinkAttributeName value:tuple[1] range:r];
        }
    }
    
    self.acknowledgements.linkTextAttributes = @{NSForegroundColorAttributeName : [UIColor blueColor],
                                                 NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)};
    self.acknowledgements.attributedText = attributedText;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
