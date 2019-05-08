//
//  AsyncDrawViewController.m
//  MVC-Demo
//
//  Created by cs on 2019/5/6.
//  Copyright © 2019 cs. All rights reserved.
//

#import "AsyncDrawViewController.h"
#import "AsyncDrawNewsCell.h"
#import "NewsModel.h"
#import "NSString+Additions.h"

@interface AsyncDrawViewController ()<UITableViewDataSource, UITableViewDelegate, AsyncDrawNewsCellDelegate>
/** tableView */
@property(nonatomic, strong)UITableView *tableView;
/** dataSource */
@property(nonatomic, strong)NSMutableArray<NewsModel *> *dataSource;
@end

static NSString *cellId = @"NewsCellId";

@implementation AsyncDrawViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupData];
    // drawUI
    [self drawUI];
}

- (void)dealloc {
    NSLog(@"%s",__func__);
}

- (void)setupData {
    [self.dataSource addObjectsFromArray:[self getRandomData]];
}

- (void)drawUI {
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(64);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
    [self.tableView reloadData];
}

#pragma mark - loadData

- (void)refreshData {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView.pullToRefreshView stopAnimating];
        NSArray *datas = [self getRandomData];
        [self.dataSource removeAllObjects];
        [self.dataSource addObjectsFromArray:datas];
        [self.tableView reloadData];
    });
}

- (void)loadNextPage {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView.infiniteScrollingView stopAnimating];
        NSArray *newRows = [self getRandomData];
        [self.dataSource addObjectsFromArray:newRows];
        [self.tableView beginUpdates];
        
        NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
        NSInteger total = [self.tableView numberOfRowsInSection:0];
        for (NSUInteger i = (NSUInteger) total; i < self.dataSource.count; i++) {
            [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [self.tableView insertRowsAtIndexPaths:arrayWithIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    });
}

#pragma mark - get

- (NSArray *)getRandomData {
    NSMutableArray *models = [NSMutableArray array];
    int number = arc4random_uniform(30);
    for (int i = 0; i < 20 + number; i++) {
        NewsModel *model = [[NewsModel alloc] init];
        model.icon = [[NewsHandler shareInstance].icons objectAtIndex:arc4random_uniform(10)];
        model.title = [[NewsHandler shareInstance].titles objectAtIndex:arc4random_uniform(10)];
        model.subTitle = [[NewsHandler shareInstance].subTitles objectAtIndex:arc4random_uniform(10)];
        model.content = [[NewsHandler shareInstance].contents objectAtIndex:arc4random_uniform(20)];
        model.specialWord = [[NewsHandler shareInstance].specialWords objectAtIndex:arc4random_uniform(20)];
        model.link = [[NewsHandler shareInstance].links objectAtIndex:arc4random_uniform(10)];
        NSUInteger index = arc4random_uniform(6);
        NSMutableArray *imgs = [NSMutableArray array];
        for (int i = 0; i < index; i++) {
            [imgs addObject:[[NewsHandler shareInstance].imgs objectAtIndex:arc4random_uniform(20)]];
        }
        if (imgs.count > 0) {
            model.imgs = imgs.copy;
        }
        model.newsId = [NSString stringWithFormat:@"%@%d",[self getNowTimeTimestamp2],i];
        model.attention = arc4random_uniform(10) % 3 == 0;
        model.like = arc4random_uniform(10) % 2 == 0;
        model.shareNum = arc4random_uniform(100);
        model.discussNum = arc4random_uniform(100);
        model.likeNum = arc4random_uniform(100) + 1;
        
        // 计算 frame
        // 1.内容 + 图片预览
        {
            NSString *content = [NSString stringWithFormat:@"%@: %@ %@",model.specialWord,model.content,model.link];
            float width = kScreenWidth - SIZE_GAP_LEFT * 2;
            CGSize size = [content sizeWithConstrainedToWidth:width fromFont:FontWithSize(SIZE_FONT_SUBCONTENT) lineSpace:5];
            NSInteger sizeHeight = size.height + 0.5;
            model.textFrame = CGRectMake(SIZE_GAP_LEFT, SIZE_GAP_BIG, width, sizeHeight);
            sizeHeight += SIZE_GAP_BIG;
            
            if (model.imgs.count > 0) { // 图片
                sizeHeight += (SIZE_GAP_IMG + SIZE_IMAGE + SIZE_GAP_IMG);
            }
            sizeHeight += SIZE_GAP_BIG;
            model.contentFrame = CGRectMake(0, 64, width, sizeHeight);
        }
        
        // 2.计算 cell 的尺寸
        {
            NSInteger sizeHeight = 64;  // 顶部标题+副标题
            sizeHeight += (model.contentFrame.size.height);
            sizeHeight += 44;   // 底部评论+点赞按钮
            model.totalFrame = CGRectMake(0, 0, kScreenWidth, sizeHeight);
        }
        
        [models addObject:model];
    }
    return models.copy;
}

#pragma mark - updateData

- (void)updateNewsView:(NewsModel *)newsModel {
    __block NSUInteger index = NSNotFound;
    [self.dataSource enumerateObjectsUsingBlock:^(NewsModel *obj, NSUInteger idx, BOOL *stop) {
        if ([newsModel.newsId isEqualToString:obj.newsId]) {
            index = idx;
            *stop = YES;
        }
    }];
    if (index == NSNotFound) {
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsModel *model = [self.dataSource objectAtIndex:indexPath.row];
    AsyncDrawNewsCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    cell.delegate = self;   // VC作为Cell视图的代理对象
    cell.model = model;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsModel *model = [self.dataSource objectAtIndex:indexPath.row];
    return model.totalFrame.size.height;
}

#pragma mark - NewsCellDelegate

- (void)didTapNewsCellDelete:(NewsModel *)newsModel {
    [self.dataSource removeObject:newsModel];
    [self.tableView reloadData];
    
    [AlertUtils message:[NSString stringWithFormat:@"以后我们将减少 %@ 类推荐",newsModel.title]];
}

- (void)didTapNewsCellAttention:(NewsModel *)newsModel {
    __weak typeof(NewsModel *) weakNewsModel = newsModel;
    [newsModel addAttention:^(NSDictionary *json) {
        weakNewsModel.attention = YES;
        [AlertUtils message:[NSString stringWithFormat:@"关注 %@\n%@ 成功",weakNewsModel.title,weakNewsModel.subTitle]];
        [self updateNewsView:weakNewsModel];
    }];
}

- (void)didTapNewsCellShare:(NewsModel *)newsModel {
    [self alertMessage:newsModel preferredStyle:UIAlertControllerStyleActionSheet];
}

- (void)didTapNewsCellDiscuss:(NewsModel *)newsModel {
    [self alertMessage:newsModel preferredStyle:UIAlertControllerStyleActionSheet];
}

- (void)didTapNewsCellLike:(NewsModel *)newsModel {
    // 标准的MVC写法
    __weak typeof(NewsModel *) weakNewsModel = newsModel;
    [newsModel addLike:^(NSDictionary *json) {
        // 更新对应的视图
        [self updateNewsView:weakNewsModel];
    }];
    
    // 非标准的MVC写法
    //    [self postLikeNetwork:newsModel];
}

#pragma mark - like network + data dealwith

- (void)postLikeNetwork:(NewsModel *)newsModel {
    NSString *api = @"http://rap2api.taobao.org/app/mock/163155/gaoshilist"; // 告示
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionTask *task = [session dataTaskWithURL:[NSURL URLWithString:api] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error == nil) {
                [self dealwithLikeData:newsModel.newsId];
            }
        });
    }];
    [task resume];
}

- (void)dealwithLikeData:(NSString *)newsId {
    __block NewsModel *newsModel;
    [self.dataSource enumerateObjectsUsingBlock:^(NewsModel *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.newsId isEqualToString:newsId]) {
            newsModel = obj;
            *stop = YES;
        }
    }];
    if (newsModel) {
        newsModel.like = !newsModel.like;
        if (newsModel.like) {
            newsModel.likeNum += 1;
        } else {
            newsModel.likeNum -= 1;
        }
        [self updateNewsView:newsModel];
    }
}

#pragma mark - alert

- (void)alertMessage:(NewsModel *)newsModel preferredStyle:(UIAlertControllerStyle)preferredStyle {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@\n%@",newsModel.title,newsModel.subTitle] message:newsModel.content preferredStyle:preferredStyle];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    [alertVC addAction:okAction];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - private

// 获取时间戳 - new id
- (NSString *)getNowTimeTimestamp2{
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a=[dat timeIntervalSince1970];
    NSString*timeString = [NSString stringWithFormat:@"%0.f", a];//转为字符型
    return timeString;
}

#pragma mark - lazy

- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, kScreenWidth, kScreenHeight - 64) style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.scrollsToTop = true;
        _tableView.backgroundColor = [UIColor whiteColor];;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.scrollsToTop = YES;
        [_tableView registerClass:[AsyncDrawNewsCell class] forCellReuseIdentifier:cellId];
        __weak typeof(self) weakSelf = self;
        [_tableView addPullToRefreshWithActionHandler:^{
            [weakSelf refreshData];
        }];
        [_tableView addInfiniteScrollingWithActionHandler:^{
            [weakSelf loadNextPage];
        }];
    }
    return _tableView;
}

- (NSMutableArray<NewsModel *> *)dataSource {
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

@end
