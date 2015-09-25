//
//  BBMessageTableViewCell.h
//  Bobo
//
//  Created by Zhouboli on 15/9/2.
//  Copyright (c) 2015年 Zhouboli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comment.h"

@class BBMessageTableViewCell;
@protocol BBMessageTableViewCellDelegate <NSObject>

-(void)tableViewCell:(BBMessageTableViewCell *)cell didTapAvatarView:(UIImageView *)avatarView;
-(void)tableViewCell:(BBMessageTableViewCell *)cell didTapHotword:(NSString *)hotword;

@end

@interface BBMessageTableViewCell : UITableViewCell

@property (weak, nonatomic) id <BBMessageTableViewCellDelegate> delegate;

@property (strong, nonatomic) Comment *comment;

@end
