//
//  ProjectArchiveViewController.m
//  Coding_iOS
//
//  Created by Easeeeeeeeee on 2018/4/26.
//  Copyright © 2018年 Coding. All rights reserved.
//

#import "ProjectArchiveViewController.h"
#import "Coding_NetAPIManager.h"

#import <SDCAlertController.h>
#import <SDCAlertView.h>
#import <UIView+SDCAutoLayout.h>
#import "ProjectDeleteAlertControllerVisualStyle.h"

#import "Ease_2FA.h"

@interface ProjectArchiveViewController ()<UITextFieldDelegate>
@property (strong, nonatomic) SDCAlertController *alert;

@end

@implementation ProjectArchiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"归档项目";
    
    for (NSLayoutConstraint *cons in self.lines) {
        cons.constant = 0.5;
    }
    
    self.tableView.tableFooterView = [UIView new];
    [self.tableView setSeparatorColor:[UIColor colorWithRGBHex:0xe5e5e5]];
    self.tableView.backgroundColor = kColorTableSectionBg;
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [UIView new];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kPaddingLeftWidth];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 1) {
        return;
    }
    [[Coding_NetAPIManager sharedManager] request_VerifyTypeWithBlock:^(VerifyType type, NSError *error) {
        if (!error) {
            [self showArchiveAlertWithType:type];
        }
    }];
}

- (void)showArchiveAlertWithType:(VerifyType)type{
    
    if (self.alert) {//正在显示
        return;
    }
    
    NSString *title, *message, *placeHolder;
    if (type == VerifyTypePassword) {
        title = @"需要验证密码";
        message = @"这是一个危险的操作，请提供登录密码确认！";
        placeHolder = @"请输入密码";
    }else if (type == VerifyTypeTotp){
        title = @"需要动态验证码";
        message = @"这是一个危险操作，需要进行身份验证！";
        placeHolder = @"请输入动态验证码";
    }else{//不知道啥类型，不处理
        return;
    }
    
    _alert = [SDCAlertController alertControllerWithTitle:title message:message preferredStyle:SDCAlertControllerStyleAlert];
    
    UITextField *passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 0, 240.0, 30.0)];
    passwordTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 30)];
    passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    passwordTextField.layer.borderColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.6].CGColor;
    passwordTextField.layer.borderWidth = 1;
    passwordTextField.secureTextEntry = (type == VerifyTypePassword);
    passwordTextField.backgroundColor = [UIColor whiteColor];
    passwordTextField.placeholder = placeHolder;
    if (type == VerifyTypeTotp) {
        passwordTextField.text = [OTPListViewController otpCodeWithGK:[Login curLoginUser].global_key];
    }
    passwordTextField.delegate = self;
    
    [_alert.contentView addSubview:passwordTextField];
    
    NSDictionary* passwordViews = NSDictionaryOfVariableBindings(passwordTextField);
    
    [_alert.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[passwordTextField]-(>=14)-|" options:0 metrics:nil views:passwordViews]];
    
    // Style
    _alert.visualStyle = [ProjectDeleteAlertControllerVisualStyle new];
    
    // 添加密码框
    //    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    //        textField.secureTextEntry = YES;
    //    }];
    
    // 添加按钮
    @weakify(self);
    _alert.actionLayout = SDCAlertControllerActionLayoutHorizontal;
    [_alert addAction:[SDCAlertAction actionWithTitle:@"取消" style:SDCAlertActionStyleDefault handler:^(SDCAlertAction *action) {
        @strongify(self);
        self.alert = nil;
    }]];
    [_alert addAction:[SDCAlertAction actionWithTitle:@"确定" style:SDCAlertActionStyleDefault handler:^(SDCAlertAction *action) {
        @strongify(self);
        self.alert = nil;
        NSString *passCode = passwordTextField.text;
        if ([passCode length] > 0) {
            // 归档项目
            [[Coding_NetAPIManager sharedManager] request_ArchiveProject_WithObj:self.project passCode:passCode type:type andBlock:^(Project *data, NSError *error) {
                if (!error) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }];
        }
    }]];
    
    [_alert presentWithCompletion:^{
        [passwordTextField becomeFirstResponder];
    }];
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Orientations
- (BOOL)shouldAutorotate{
    return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation);
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
@end
