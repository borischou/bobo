//
//  BBPhotoPickerCollectionView.h
//  Bobo
//
//  Created by Zhouboli on 15/8/28.
//  Copyright (c) 2015年 Zhouboli. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BBPhotoPickerCollectionView : UICollectionView

@property (copy, nonatomic) NSMutableArray *photos;
@property (copy, nonatomic) NSMutableArray *pickedOnes;
@property (copy, nonatomic) NSMutableArray *pickedStatuses;

@end
