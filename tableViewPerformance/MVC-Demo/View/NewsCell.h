//
//  NewsCell.h
//  MVC-Demo
//
//  Created by cs on 2019/4/11.
//  Copyright © 2019 cs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewsModel;

NS_ASSUME_NONNULL_BEGIN

@protocol NewsCellDelegate <NSObject>

// tap delete
- (void)didTapNewsCellDelete:(NewsModel *)newsModel;

// tap attention
- (void)didTapNewsCellAttention:(NewsModel *)newsModel;

// tap share
- (void)didTapNewsCellShare:(NewsModel *)newsModel;

// tap discuss
- (void)didTapNewsCellDiscuss:(NewsModel *)newsModel;

// tap like
- (void)didTapNewsCellLike:(NewsModel *)newsModel;

@end

@interface NewsCell : UITableViewCell

/** model */
@property(nonatomic, strong)NewsModel *model;

/** delegate */
@property(nonatomic,weak)id<NewsCellDelegate> delegate;

/// 开始绘制
- (void)draw;

/// 清空视图
- (void)clear;

@end

NS_ASSUME_NONNULL_END
