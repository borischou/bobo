//
//  BBCountCell.m
//  Bobo
//
//  Created by Zhouboli on 15/6/24.
//  Copyright (c) 2015年 Zhouboli. All rights reserved.
//

#import "BBCountTableViewCell.h"
#import "AppDelegate.h"
#import "NSString+Convert.h"

#define bWidth [UIScreen mainScreen].bounds.size.width
#define bHeight [UIScreen mainScreen].bounds.size.height

#define bCountCellHeight bHeight/10
#define bCountSmallCellWidth bWidth/4
#define bNumPartHeight bCountCellHeight*0.618 //golden ratio
#define bTextPartHeight bCountCellHeight*0.382

#define bAvatarWidth 45
#define bAvatarHeight bAvatarWidth
#define bNicknameWidth [UIScreen mainScreen].bounds.size.width/2
#define bNicknameHeight 20
#define bPostTimeWidth bNicknameWidth
#define bPostTimeHeight 20
#define bTopPadding 10.0
#define bPostImgHeight [UIScreen mainScreen].bounds.size.width/6
#define bPostImgWidth bPostImgHeight
#define bTextFontSize 14.f
#define bSmallGap 5
#define bBigGap 10

#define bCellBGColor [UIColor colorWithRed:59.f/255 green:59.f/255 blue:59.f/255 alpha:1.f]

@interface BBCountTableViewCell ()

@property (strong, nonatomic) UIImageView *todoImgView;
@property (strong, nonatomic) UILabel *wbcounts;
@property (strong, nonatomic) UILabel *friendcounts;
@property (strong, nonatomic) UILabel *followercounts;
@property (strong, nonatomic) AppDelegate *appDelegate;

@end

@implementation BBCountTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.contentView.backgroundColor = bCellBGColor;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = .2;
        self.layer.shadowOffset = CGSizeMake(0, -2);
        _appDelegate = [AppDelegate delegate];
        [self initCountLayout];
    }
    return self;
}

-(void)initCountLayout
{
    //number part
    _wbcounts = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, bCountSmallCellWidth, bNumPartHeight)];
    _friendcounts = [[UILabel alloc] initWithFrame:CGRectMake(bCountSmallCellWidth, 0, bCountSmallCellWidth, bNumPartHeight)];
    _followercounts = [[UILabel alloc] initWithFrame:CGRectMake(bCountSmallCellWidth*2, 0, bCountSmallCellWidth, bNumPartHeight)];
    [self initCellLabel:_wbcounts];
    [self initCellLabel:_friendcounts];
    [self initCellLabel:_followercounts];
    
    [_wbcounts addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wbcountsTapped:)]];
    [_friendcounts addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(friendcountsTapped:)]];
    [_followercounts addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(followercountsTapped:)]];
    
    //text part
    UILabel *wbTextLbl = nil;
    [self initCellLabel:wbTextLbl withFrame:CGRectMake(0, bNumPartHeight, bCountSmallCellWidth, bTextPartHeight) andTitle:@"Statuses" withFontSize:13.f];
    UILabel *followTextLbl = nil;
    [self initCellLabel:followTextLbl withFrame:CGRectMake(bCountSmallCellWidth, bNumPartHeight, bCountSmallCellWidth, bTextPartHeight) andTitle:@"Follows" withFontSize:13.f];
    
    UILabel *followerTextLbl = nil;
    [self initCellLabel:followerTextLbl withFrame:CGRectMake(bCountSmallCellWidth*2, bNumPartHeight, bCountSmallCellWidth, bTextPartHeight) andTitle:@"Followers" withFontSize:13.f];
    
    _todoImgView = [[UIImageView alloc] initWithFrame:CGRectMake(bCountSmallCellWidth*3+(bCountSmallCellWidth-bCountCellHeight*0.4)*.5, bCountCellHeight*0.3, bCountCellHeight*0.4, bCountCellHeight*0.4)];
    [_todoImgView setUserInteractionEnabled:YES];
    [_todoImgView setImage:nil];
    [_todoImgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(todoImgViewTapped:)]];
    [self.contentView addSubview:_todoImgView];
}

-(void)initCellLabel:(UILabel *)label
{
    label.text = @"0";
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    [label setUserInteractionEnabled:YES];
    [self.contentView addSubview:label];
}

-(void)initCellLabel:(UILabel *)label withFrame:(CGRect)frame andTitle:(NSString *)title withFontSize:(CGFloat)size
{
    label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.attributedText = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:size]}];
    label.textColor = [UIColor lightGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:label];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    _wbcounts.text = [NSString formatNum:_user.statuses_count];
    _followercounts.text = [NSString formatNum:_user.followers_count];
    _friendcounts.text = [NSString formatNum:_user.friends_count];
    
    if (!_appDelegate.user)
    {
        [_appDelegate fetchUserProfile];
    }
    
    if ([_user.idstr isEqualToString:_appDelegate.uid] || [_user.idstr isEqualToString:_appDelegate.user.idstr])
    {
        [_todoImgView setImage:[UIImage imageNamed:@"settings_icon"]];
    }
    else
    {
        if (_user.following && !_user.follow_me)
        {
            [_todoImgView setImage:[UIImage imageNamed:@"following_icon"]];
        }
        if (_user.following && _user.follow_me)
        {
            [_todoImgView setImage:[UIImage imageNamed:@"friend_icon"]];
        }
        if (!_user.following)
        {
            [_todoImgView setImage:[UIImage imageNamed:@"follow_icon"]];
        }
    }
}

#pragma mark - Actions

-(void)todoImgViewTapped:(UITapGestureRecognizer *)tap
{
    [self.delegate tableViewCell:self didTapTodoImageView:tap];
}

-(void)friendcountsTapped:(UITapGestureRecognizer *)tap
{
    [self.delegate tableViewCell:self didTapFollowingCountLabel:tap];
}

-(void)wbcountsTapped:(UITapGestureRecognizer *)tap
{
    [self.delegate tableViewCell:self didTapWeiboCountLabel:tap];
}

-(void)followercountsTapped:(UITapGestureRecognizer *)tap
{
    [self.delegate tableViewCell:self didTapFollowerCountLabel:tap];
}

@end
