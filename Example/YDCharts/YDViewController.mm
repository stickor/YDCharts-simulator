//
//  YDViewController.m
//  YDCharts
//
//  Created by 895148635@qq.com on 12/15/2020.
//  Copyright (c) 2020 895148635@qq.com. All rights reserved.
//

#import "YDViewController.h"
#import "YdKLineView.h"



@interface YDViewController ()

@end

@implementation YDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSString *jsonPath = [[NSBundle mainBundle ]pathForResource:@"ChartData.json" ofType:nil];
    NSString *jsonStriing = [[NSString alloc]initWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil];
    
    YdKLineView *cView = [[YdKLineView alloc] init];
    cView.frame = CGRectMake(0, 200, self.view.frame.size.width, 500);
    [cView setChartData:jsonStriing];
    [cView setMainName:@"MA"];
    [cView setViceName:@"操盘提醒"];
    [cView setChartLoc:@"底部出击"];
    [cView setIsLand:0];
    
    
    [self.view addSubview:cView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
