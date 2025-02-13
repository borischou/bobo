//
//  BBHomelistTableViewCell.m
//  Bobo
//
//  Created by Zhouboli on 15/6/12.
//  Copyright (c) 2015年 Zhouboli. All rights reserved.
//

#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <AFNetworking.h>
#import <WebKit/WebKit.h>
#import <YYWebImage.h>

#import "BBStatusTableViewCell.h"
#import "NSString+Convert.h"
#import "UIColor+Custom.h"

#import "Utils.h"
#import "AppDelegate.h"
#import "BBUpdateStatusView.h"
#import "BBImageBrowserView.h"

#import "BBStatusDetailViewController.h"
#import "BBMainStatusTableViewController.h"
#import "BBProfileTableViewController.h"
#import "BBFavoritesTableViewController.h"

@interface BBStatusTableViewCell ()

//status
@property (strong, nonatomic) UILabel *nicknameLbl;
@property (strong, nonatomic) UILabel *postTimeLbl;
@property (strong, nonatomic) UILabel *sourceLbl;
@property (strong, nonatomic) UIImageView *avatarView;
@property (strong, nonatomic) UIImageView *vipView;
@property (strong, nonatomic) NSMutableArray *statusImgViews;
@property (strong, nonatomic) NSMutableArray *gifStatusViews;

//repost status
@property (strong, nonatomic) UIView *repostView;
@property (strong, nonatomic) NSMutableArray *imgViews;
@property (strong, nonatomic) NSMutableArray *gifRepostViews;

//barbuttons
@property (strong, nonatomic) UIImageView *retweetImageView;
@property (strong, nonatomic) UIImageView *commentImageView;
@property (strong, nonatomic) UIImageView *likeImageView;
@property (strong, nonatomic) UIImageView *favoritesImageView;

@property (strong, nonatomic) UILabel *retweetCountLabel;
@property (strong, nonatomic) UILabel *commentCountLabel;
@property (strong, nonatomic) UILabel *likeCountLabel;

//delete buttons
@property (strong, nonatomic) UIButton *deleteButton;

@end

static inline NSRegularExpression * HotwordRegularExpression() {
    static NSRegularExpression *_hotwordRegularExpression = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _hotwordRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"(@([\\w-]+[\\w-]*))|((https?://([\\w]+).([\\w]+))+/[\\w]+)|(#[^#]+#)" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    
    return _hotwordRegularExpression;
}

@implementation BBStatusTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    if (self.highlighted)
    {
        self.contentView.alpha = 0.9;
    }
    else
    {
        self.contentView.alpha = 1.0;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self initCellLayout];
        [self setupBarButtonsLayout];
    }
    return self;
}

-(void)initCellLayout
{
    self.contentView.backgroundColor = bCellBGColor;
    
    //profile image
    _avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, bAvatarWidth, bAvatarHeight)];
    _avatarView.userInteractionEnabled = YES;
    _avatarView.clipsToBounds = YES;
    _avatarView.layer.masksToBounds = YES;
    _avatarView.layer.cornerRadius = _avatarView.bounds.size.width*0.5;
    [_avatarView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarViewTapped)]];
    [self.contentView addSubview:_avatarView];
    
    //nickname
    _nicknameLbl = [[UILabel alloc] initWithFrame:CGRectMake(10+bAvatarWidth+10, 10+5, bNicknameWidth, bNicknameHeight)];
    [self.contentView addSubview:_nicknameLbl];
    
    //vip
    _vipView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_vipView];
    
    //post time
    _postTimeLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    _postTimeLbl.textColor = [UIColor lightTextColor];
    _postTimeLbl.font = [UIFont systemFontOfSize:10.f];
    [self.contentView addSubview:_postTimeLbl];
    
    //source
    _sourceLbl = [[UILabel alloc] initWithFrame:CGRectZero];
    _sourceLbl.textColor = [UIColor lightTextColor];
    [_sourceLbl setFont:[UIFont systemFontOfSize:10.f]];
    [self.contentView addSubview:_sourceLbl];
    
    //delete
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_deleteButton setFrame:CGRectZero];
    _deleteButton.enabled = YES;
    [_deleteButton setBackgroundImage:[UIImage imageNamed:@"delete_icon"] forState:UIControlStateNormal];
    [_deleteButton setBackgroundImage:[UIImage imageNamed:@"delete-disable"] forState:UIControlStateDisabled];
    [_deleteButton setBackgroundImage:[UIImage imageNamed:@"delete-selected"] forState:UIControlStateHighlighted];
    [_deleteButton addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_deleteButton];
    
    CGFloat fontSize = [Utils fontSizeForStatus];
    //text
    _tweetTextLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    [_tweetTextLabel setNumberOfLines:0];
    [_tweetTextLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [_tweetTextLabel setFont:[UIFont systemFontOfSize:fontSize]];
    [_tweetTextLabel setTextColor:[UIColor customGray]];
    [_tweetTextLabel setLineSpacing:2.0];
    [_tweetTextLabel setLinkAttributes:@{(__bridge NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO],
                                         (NSString *)kCTForegroundColorAttributeName: (__bridge id)tLinkColor.CGColor}];
    [_tweetTextLabel setActiveLinkAttributes:@{(__bridge NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO],
                                               (NSString *)kCTForegroundColorAttributeName: (__bridge id)tActiveLinkColor.CGColor}];
    [self.contentView addSubview:_tweetTextLabel];
    
    //img views for status
    _statusImgViews = [[NSMutableArray alloc] init];
    _gifStatusViews = [[NSMutableArray alloc] init];
    for (int i = 0; i < 9; i ++)
    {
        UIImageView *sImgView = [[UIImageView alloc] initWithFrame:CGRectZero];
        sImgView.clipsToBounds = YES;
        sImgView.tag = i;
        sImgView.contentMode = UIViewContentModeScaleAspectFill;
        [sImgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(statusImageTapped:)]];
        sImgView.userInteractionEnabled = YES;
        [_statusImgViews addObject:sImgView];
        [self.contentView addSubview:sImgView];
        
        UIImageView *gifView = [[UIImageView alloc] initWithFrame:CGRectZero];
        gifView.clipsToBounds = YES;
        gifView.contentMode = UIViewContentModeScaleAspectFill;
        [gifView setImage:[UIImage imageNamed:@"gif_icon"]];
        [_gifStatusViews addObject:gifView];
        [sImgView addSubview:gifView];
    }
    
    //retweet view
    _repostView = [[UIView alloc] initWithFrame:CGRectZero];
    _repostView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(repostViewTapped:)];
    [_repostView addGestureRecognizer:tap];
    _repostView.backgroundColor = bRetweetBGColor;
    
    //repost text
    _retweetTextLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    [_retweetTextLabel setNumberOfLines:0];
    [_retweetTextLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [_retweetTextLabel setFont:[UIFont systemFontOfSize:fontSize]];
    [_retweetTextLabel setTextColor:[UIColor lightTextColor]];
    [_retweetTextLabel setLineSpacing:2.0];
    [_retweetTextLabel setLinkAttributes:@{(__bridge NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO],
                                         (NSString *)kCTForegroundColorAttributeName: (__bridge id)tLinkColor.CGColor}];
    [_retweetTextLabel setActiveLinkAttributes:@{(__bridge NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO],
                                               (NSString *)kCTForegroundColorAttributeName: (__bridge id)tActiveLinkColor.CGColor}];
    [_repostView addSubview:_retweetTextLabel];
    
    //img views for retweeted_status
    _imgViews = [[NSMutableArray alloc] init];
    _gifRepostViews = [[NSMutableArray alloc] init];
    for (int i = 0; i < 9; i ++)
    {
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imgView.clipsToBounds = YES;
        imgView.tag = i;
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        [imgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(repostImageTapped:)]];
        imgView.userInteractionEnabled = YES;
        [_imgViews addObject:imgView];
        [_repostView addSubview:imgView];
        
        UIImageView *gifView = [[UIImageView alloc] initWithFrame:CGRectZero];
        gifView.clipsToBounds = YES;
        gifView.contentMode = UIViewContentModeScaleAspectFill;
        [gifView setImage:[UIImage imageNamed:@"gif_icon"]];
        [_gifRepostViews addObject:gifView];
        [imgView addSubview:gifView];
    }
    [self.contentView addSubview:_repostView];
}

-(void)setupBarButtonsLayout
{
    self.contentView.backgroundColor = bCellBGColor;
    
    _retweetImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _retweetImageView.image = [UIImage imageNamed:@"retwt_icon"];
    _retweetImageView.userInteractionEnabled = YES;
    [_retweetImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retweetImageViewTapped)]];
    [self.contentView addSubview:_retweetImageView];
    
    _retweetCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _retweetCountLabel.textColor = [UIColor lightTextColor];
    _retweetCountLabel.font = [UIFont systemFontOfSize:bFontSize];
    [self.contentView addSubview:_retweetCountLabel];
    
    _commentImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _commentImageView.image = [UIImage imageNamed:@"cmt_icon"];
    _commentImageView.clipsToBounds = YES;
    _commentImageView.userInteractionEnabled = YES;
    [_commentImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commentImageViewTapped)]];
    [self.contentView addSubview:_commentImageView];
    
    _commentCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _commentCountLabel.textColor = [UIColor lightTextColor];
    _commentCountLabel.font = [UIFont systemFontOfSize:bFontSize];
    [self.contentView addSubview:_commentCountLabel];
    
    _likeImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _likeImageView.image = [UIImage imageNamed:@"like_icon_2"];
    _likeImageView.clipsToBounds = YES;
    _likeImageView.userInteractionEnabled = YES;
    [_likeImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(likeImageViewTapped)]];
    [self.contentView addSubview:_likeImageView];
    
    _likeCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _likeCountLabel.textColor = [UIColor lightTextColor];
    _likeCountLabel.font = [UIFont systemFontOfSize:bFontSize];
    [self.contentView addSubview:_likeCountLabel];
    
    _favoritesImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _favoritesImageView.image = [UIImage imageNamed:@"fav_icon_3"];
    _favoritesImageView.clipsToBounds = YES;
    _favoritesImageView.userInteractionEnabled = YES;
    [_favoritesImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(favoritesImageViewTapped)]];
    [self.contentView addSubview:_favoritesImageView];
}

#pragma mark - Icon action support

-(void)retweetImageViewTapped
{
    [self.delegate tableViewCell:self didTapRetweetIcon:_retweetImageView];
}

-(void)commentImageViewTapped
{
    [self.delegate tableViewCell:self didTapCommentIcon:_commentImageView];
}

-(void)likeImageViewTapped
{
    NSLog(@"likeImageViewTapped");
}

-(void)favoritesImageViewTapped
{
    [self.delegate tableViewCell:self didTapFavoriteIcon:_favoritesImageView];
}

-(void)statusImageTapped:(UITapGestureRecognizer *)tap
{
    [self.delegate tableViewCell:self didTapStatusPicture:tap];
}

-(void)repostImageTapped:(UITapGestureRecognizer *)tap
{
    [self.delegate tableViewCell:self didTapRetweetPicture:tap];
}

-(void)repostViewTapped:(UITapGestureRecognizer *)tap
{
    [self.delegate tableViewCell:self didTapRetweetView:_repostView];
}

-(void)avatarViewTapped
{
    [self.delegate tableViewCell:self didTapAvatar:_avatarView];
}

-(void)deleteButtonPressed:(UIButton *)sender
{
    [self.delegate tableViewCell:self didPressDeleteButton:sender];
}

#pragma mark - Cell configure support

//override this method to load views dynamically
-(void)layoutSubviews
{
    [super layoutSubviews];
    [self loadData];
    [self loadLayout];
}

-(void)prepareForReuse
{
    [super prepareForReuse];
}

-(void)loadData
{
    NSRegularExpression *regex = HotwordRegularExpression();
    
    //status
    [_avatarView yy_setImageWithURL:[NSURL URLWithString:_status.user.avatar_large] placeholder:[UIImage imageNamed:@"bb_holder_profile_image"] options:YYWebImageOptionProgressiveBlur|YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error)
    {
        //nothing
    }];
    
    _nicknameLbl.text = _status.user.screen_name;
    if ([_status.user.gender isEqualToString:@"m"])
    {
        [_nicknameLbl setTextColor:bMaleColor];
    }
    if ([_status.user.gender isEqualToString:@"f"])
    {
        [_nicknameLbl setTextColor:bFemaleColor];
    }
    if ([_status.user.gender isEqualToString:@"n"])
    {
        [_nicknameLbl setTextColor:[UIColor lightTextColor]];
    }
    
    _postTimeLbl.text = [NSString formatPostTime:_status.created_at];
    _sourceLbl.text = [NSString trim:_status.source];

    if (_status.text)
    {
        [_tweetTextLabel setText:_status.text];
        NSArray *tweetLinkRanges = [regex matchesInString:_status.text options:0 range:NSMakeRange(0, _status.text.length)];
        for (NSTextCheckingResult *result in tweetLinkRanges)
        {
            [_tweetTextLabel addLinkWithTextCheckingResult:result];
        }
    }
    
    //status
    if (_status.pic_urls.count > 0)
    {
        for (int i = 0; i < [_status.pic_urls count]; i ++)
        {
            UIImageView *imageView = (UIImageView *)_statusImgViews[i];
            if ([_status.pic_urls[i] hasSuffix:@"gif"])
            {
                [imageView yy_setImageWithURL:[NSURL URLWithString:_status.pic_urls[i]] placeholder:[UIImage imageNamed:@"pic_placeholder"] options:YYWebImageOptionProgressiveBlur|YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error)
                {
                    //gif
                }];
            }
            else
            {
                [imageView yy_setImageWithURL:[NSURL URLWithString:[NSString middlePictureUrlConvertedFromThumbUrl:_status.pic_urls[i]]] placeholder:[UIImage imageNamed:@"pic_placeholder"] options:YYWebImageOptionProgressiveBlur|YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error)
                 {
                     
                 }];
            }
        }
    }
    
    //repost status
    if (_status.retweeted_status.text)
    {
        [_retweetTextLabel setText:[NSString stringWithFormat:@"@%@:%@", _status.retweeted_status.user.screen_name, _status.retweeted_status.text]];
        NSArray *retweetLinkRanges = [regex matchesInString:[NSString stringWithFormat:@"@%@:%@", _status.retweeted_status.user.screen_name, _status.retweeted_status.text] options:0 range:NSMakeRange(0, [[NSString stringWithFormat:@"@%@:%@", _status.retweeted_status.user.screen_name, _status.retweeted_status.text] length])];
        for (NSTextCheckingResult *result in retweetLinkRanges)
        {
            [_retweetTextLabel addLinkWithTextCheckingResult:result];
        }
    }
    
    if (_status.retweeted_status.pic_urls.count > 0)
    {
        for (int i = 0; i < [_status.retweeted_status.pic_urls count]; i ++)
        {
            UIImageView *imageView = (UIImageView *)_imgViews[i];
            if ([_status.retweeted_status.pic_urls[i] hasSuffix:@"gif"])
            {
                [imageView yy_setImageWithURL:[NSURL URLWithString:_status.retweeted_status.pic_urls[i]] placeholder:[UIImage imageNamed:@"pic_placeholder"] options:YYWebImageOptionProgressiveBlur|YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error)
                 {
                     //gif
                 }];
            }
            else
            {
                [imageView yy_setImageWithURL:[NSURL URLWithString:[NSString middlePictureUrlConvertedFromThumbUrl:_status.retweeted_status.pic_urls[i]]] placeholder:[UIImage imageNamed:@"pic_placeholder"] options:YYWebImageOptionProgressiveBlur|YYWebImageOptionSetImageWithFadeAnimation completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error)
                 {
                     
                 }];
            }
        }
    }
    
    //barbuttons
    _retweetCountLabel.text = [NSString formatNum:_status.reposts_count];
    _commentCountLabel.text = [NSString formatNum:_status.comments_count];
    _likeCountLabel.text = [NSString formatNum:_status.attitudes_count];
    
    if (_status.favorited)
    {
        _favoritesImageView.image = [UIImage imageNamed:@"faved_icon"];
    }
    else
    {
        _favoritesImageView.image = [UIImage imageNamed:@"fav_icon_3"];
    }
}

-(void)loadLayout
{
    //reset gifs
    [self resetGifViews:_gifStatusViews];
    [self resetGifViews:_gifRepostViews];
    
    //vip
    if (_status.user.verified)
    {
        CGSize nameSize = [_nicknameLbl sizeThatFits:CGSizeMake(MAXFLOAT, bNicknameHeight)];
        [_vipView setFrame:CGRectMake(bBigGap*2+bAvatarWidth+nameSize.width, sbGap, 15, 15)];
        [_vipView setImage:[UIImage imageNamed:@"icon_vip"]];
    }
    else
    {
        [_vipView setFrame:CGRectZero];
        [_vipView setImage:nil];
    }
    
    //时间
    CGSize timeSize = [_postTimeLbl sizeThatFits:CGSizeMake(MAXFLOAT, bPostTimeHeight)];
    [_postTimeLbl setFrame:CGRectMake(bBigGap*2+bAvatarWidth, sbGap+bNicknameHeight+3, timeSize.width, bPostTimeHeight)];
    
    //来源
    CGSize sourceSize = [_sourceLbl sizeThatFits:CGSizeMake(MAXFLOAT, bPostTimeHeight)];
    [_sourceLbl setFrame:CGRectMake(bBigGap*3+bAvatarWidth+timeSize.width,
                                    sbGap+bNicknameHeight+3,
                                    sourceSize.width,
                                    bPostTimeHeight)];
    
    //删除
    AppDelegate *delegate = [AppDelegate delegate];
    [_deleteButton setFrame:CGRectMake(bWidth-bBigGap-bDeleteBtnWidth, 10+5, bDeleteBtnWidth, bDeleteBtnWidth)];
    if ([_status.user.idstr isEqualToString:delegate.user.idstr])
    {
        [_deleteButton setHidden:NO];
        [_deleteButton setEnabled:YES];
    }
    else
    {
        [_deleteButton setHidden:YES];
    }
    
    //微博正文
    CGSize postSize = [_tweetTextLabel sizeThatFits:CGSizeMake(bWidth-2*bBigGap, MAXFLOAT)];
    [_tweetTextLabel setFrame:CGRectMake(bBigGap, bBigGap*2+bAvatarHeight, bWidth-bBigGap*2, postSize.height)];
    
    _repostView.hidden = YES;
    if (_status.retweeted_status)
    {
        //转发微博
        _repostView.hidden = NO;
        [self resetImageViews:_statusImgViews];
        CGSize repostSize = [_retweetTextLabel sizeThatFits:CGSizeMake(bWidth-2*bBigGap, MAXFLOAT)];
        [_retweetTextLabel setFrame:CGRectMake(bBigGap, 0, bWidth-2*bBigGap, repostSize.height)];
        [_repostView setFrame:CGRectMake(0,
                                         bBigGap*3+bAvatarHeight+postSize.height,
                                         bWidth,
                                         repostSize.height+bSmallGap+heightForImgsWithCount([_status.retweeted_status.pic_urls count]))];
        
        //[Utils layoutImgViews:_imgViews withImageCount:[_status.retweeted_status.pic_urls count] fromTopHeight:repostSize.height];
        layoutImgViews(_imgViews, _status.retweeted_status.pic_urls.count, repostSize.height);
        [self layoutGifsWithUrls:_status.retweeted_status.pic_urls imageViews:_imgViews gifViews:_gifRepostViews];
    }
    else
    {
        //微博配图
        _repostView.hidden = YES;
        //[Utils layoutImgViews:_statusImgViews withImageCount:[_status.pic_urls count] fromTopHeight:bBigGap*2+bAvatarHeight+postSize.height];
        layoutImgViews(_statusImgViews, _status.pic_urls.count, bBigGap*2+bAvatarHeight+postSize.height);
        [self layoutGifsWithUrls:_status.pic_urls imageViews:_statusImgViews gifViews:_gifStatusViews];
    }
    [self layoutBarButtonsWithTop:_status.height-bBarHeight];
}

-(void)resetGifViews:(NSMutableArray *)gifViews
{
    for (UIImageView *view in gifViews)
    {
        [view setFrame:CGRectZero];
    }
}

-(void)layoutGifsWithUrls:(NSMutableArray *)imageUrls imageViews:(NSMutableArray *)imageViews gifViews:(NSMutableArray *)gifViews
{
    if (imageUrls.count > 0)
    {
        NSInteger urlCount = imageUrls.count;
        for (int i = 0; i < urlCount; i ++)
        {
            UIImageView *imageView = imageViews[i];
            UIImageView *gif = gifViews[i];
            if ([imageUrls[i] hasSuffix:@"gif"]) //是gif类型
            {
                [gif setFrame:CGRectMake(imageView.frame.size.width*5/6,
                                         imageView.frame.size.height*5/6,
                                         imageView.frame.size.width/6,
                                         imageView.frame.size.height/6)];
            }
            else
            {
                [gif setFrame:CGRectZero];
            }
        }
    }
}

-(void)layoutBarButtonsWithTop:(CGFloat)top
{
    float bImageHeight = [UIScreen mainScreen].bounds.size.height/25-2*bBarSmallGap;
    float bImageWidth = bImageHeight;
    
    [_retweetImageView setFrame:CGRectMake(bBigGap, top+bBarSmallGap, bImageWidth, bImageHeight)];
    
    CGSize rsize = [_retweetCountLabel sizeThatFits:CGSizeMake(MAXFLOAT, bImageHeight)];
    [_retweetCountLabel setFrame:CGRectMake(sbGap+bImageWidth, top+bBarSmallGap, rsize.width, bImageHeight)];
    
    [_commentImageView setFrame:CGRectMake(sbGap+bImageWidth+_retweetCountLabel.frame.size.width+bBigGap, top+bBarSmallGap, bImageWidth, bImageHeight)];
    
    CGSize csize = [_commentCountLabel sizeThatFits:CGSizeMake(MAXFLOAT, bImageHeight)];
    [_commentCountLabel setFrame:CGRectMake(sbGap*2+bImageWidth+_retweetCountLabel.frame.size.width+bImageWidth, top+bBarSmallGap, csize.width, bImageHeight)];
    
    [_likeImageView setFrame:CGRectMake(sbGap*2+bImageWidth+_retweetCountLabel.frame.size.width+bImageWidth+_commentCountLabel.frame.size.width+bBigGap, top+bBarSmallGap, bImageWidth, bImageHeight)];
    
    CGSize lsize = [_likeCountLabel sizeThatFits:CGSizeMake(MAXFLOAT, bImageHeight)];
    [_likeCountLabel setFrame:CGRectMake(sbGap*3+bImageWidth+_retweetCountLabel.frame.size.width+bImageWidth+_commentCountLabel.frame.size.width+bImageWidth, top+bBarSmallGap, lsize.width, bImageHeight)];
    
    [_favoritesImageView setFrame:CGRectMake(sbGap*3+bImageWidth+_retweetCountLabel.frame.size.width+bImageWidth+_commentCountLabel.frame.size.width+bImageWidth+_likeCountLabel.frame.size.width+bBigGap, top+bBarSmallGap, bImageWidth, bImageHeight)];
}

-(void)resetImageViews:(NSMutableArray *)views
{
    for (int i = 0; i < [views count]; i ++)
    {
        [views[i] setFrame:CGRectZero];
    }
}

@end
