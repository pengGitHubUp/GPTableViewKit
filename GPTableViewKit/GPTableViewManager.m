//
//  GPTableViewManager.m
//  GPTableViewKit
//
//  Created by peng on 16/6/27.
//  Copyright © 2016年 Wei Guopeng. All rights reserved.
//

#import "GPTableViewManager.h"
#import "GPTableView.h"

@interface GPTableViewManager ()<UITableViewDelegate, UITableViewDataSource>
/** section info */
@property (nonatomic, strong) NSMutableArray *sectionArray;
@end


@implementation GPTableViewManager

- (instancetype)initWithTableView:(UITableView *)tableView; {
    self = [super init];
    if (self) {
        _tableView = tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        
        _sectionArray = [[NSMutableArray alloc]init];
        
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            
        }
        
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.contentOffset = CGPointMake(0, -_tableView.contentInset.top);
        
    }
    return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView delegate:(id<GPTableViewManagerDelegate>)delegate; {
    
    self = [self initWithTableView:tableView];
    if (self) {
        _delegate = delegate;
    }
    return self;
    
}

- (NSArray *)sections {
    return _sectionArray;
}

#pragma mark 增／删/改  section
- (void)addSection:(GPTableViewSectionManager *)section; {
    
    [_sectionArray addObject:section];
    
}
- (void)insertSection:(id)section atIndex:(NSInteger)index {
    
    if (index<0 || index>_sectionArray.count) NSLog(@"index:%ld 超出当前section的范围\n已自动取就近索引",(long)index);
    
    index = index<0?0:index;
    index = index > _sectionArray.count?_sectionArray.count:index;
    
    [_sectionArray insertObject:section atIndex:index];
}

- (void)deleteSectionAtIndex:(NSInteger)index {
    
    if (index < 0 || index >= _sectionArray.count || _sectionArray.count == 0) {
        NSLog(@"index:%ld 超出当前section的范围\n已自动取就近索引",(long)index);
        return;
    }
    [_sectionArray removeObjectAtIndex:index];
}
- (void)replaceSectionsAtIndex:(NSInteger)index withSection:(id)section {
    [_sectionArray replaceObjectAtIndex:index withObject:section];
    [self.tableView reloadData];
}

- (void)removeAllSections; {
    [self.sectionArray removeAllObjects];
}

#pragma mark 刷新
- (void)reloadTableView; {
    
    if ([self.delegate respondsToSelector:@selector(tableViewDataSource:)]) {
        [self removeAllSections];
        [self.delegate tableViewDataSource:self];
    }
    
    [self.tableView reloadData];
}
- (void)reloadSection:(GPTableViewSectionManager *)section atIndex:(NSInteger)index; {
    
    if (self.sections.count > index) {
        [self replaceSectionsAtIndex:index withSection:section];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        NSLog(@"section：%ld不存在",(long)index);
    }
}



#pragma mark  - >> 获取cell <<
- (id)getCell:(NSString *)cell {
    
    if (cell.length == 0) {
        return nil;
    } else {
        for (int i = 0; i < self.sections.count; i++) {
            GPTableViewSectionManager *sectionModel = self.sections[i];
            for (int j = 0; j < sectionModel.rows.count; j++) {
                GPTableViewRowManager *rowModel = sectionModel.rows[j];
                if ([cell isEqualToString:rowModel.cellName]) {
                    return [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                }
            }
            
        }
        return nil;
    }
}


#pragma mark - tableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GPTableViewSectionManager *sectionModel = self.sections[indexPath.section];
    GPTableViewRowManager *rowModel = sectionModel.rows[indexPath.row];
    if (rowModel.didSelectRow) {
        rowModel.didSelectRow();
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath; {
    
    if (indexPath.section >= self.sections.count) {
        NSLog(@"\n -------- \n tableView error \n -------- \n");
        return 0;
    }
    GPTableViewSectionManager *sectionModel = self.sections[indexPath.section];
    GPTableViewRowManager *rowModel = sectionModel.rows[indexPath.row];
    
    return rowModel.rowHeight;
}

#pragma mark  - >> edit <<
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath; {
    GPTableViewSectionManager *sectionModel = self.sections[indexPath.section];
    GPTableViewRowManager *rowModel = sectionModel.rows[indexPath.row];
    
    if (rowModel.editingStyles.count == 0) {
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section >= self.sections.count) {
        return nil;
    }
    
    GPTableViewSectionManager *sectionModel = self.sections[indexPath.section];
    GPTableViewRowManager *rowModel = sectionModel.rows[indexPath.row];
    
    if (rowModel.editingStyles.count == 0) {
        return nil;
    } else {
        NSMutableArray *actions = [[NSMutableArray alloc] init];
        NSInteger index = 0;
        for (NSDictionary * dic in rowModel.editingStyles) {
            UITableViewRowAction *action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:[dic objectForKey:@"title"] handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                if (rowModel.didEditRow) {
                    rowModel.didEditRow(index);
                }
            }];
            action.backgroundColor = [dic objectForKey:@"color"];
            [actions addObject:action];
            index ++;
        }
        
        return actions;
    }
}

#pragma mark DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView; {
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section; {
    
    if (section >= self.sections.count) {
        return 0;
    }
    
    GPTableViewSectionManager *sectionModel = self.sections[section];
    return sectionModel.rows.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath; {
    
    GPTableViewRowManager *rowModel = nil;
    if (indexPath.section < self.sections.count) {
        
        GPTableViewSectionManager *sectionModel = self.sections[indexPath.section];
        rowModel = sectionModel.rows[indexPath.row];
    } else {
        NSLog(@"\n -------- \n tableView error \n -------- \n");
    }
    
    NSString *identifier = @"GPTableViewCell";
    NSString *cellName = @"GPTableViewCell";
    if (cellName.length > 0) {
        cellName = rowModel.cellName;
    }
    
    if (rowModel.reuseIdentifier.length > 0) {
        identifier = rowModel.reuseIdentifier;
    } else {
        identifier = cellName;
    }
    
    GPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    Class cellClass = NSClassFromString(cellName);
    if (!cell) {
        
        cell = [[cellClass?:[GPTableViewCell class] alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        
    }
    cell.selectionStyle = rowModel.selectStyle;
    
    cell.row = rowModel;
    cell.indexPath = indexPath;
    
    [cell cellWillAppear:rowModel.model];
    
    return cell;
}

#pragma mark  - ->> headers <<--

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section; {
    
    GPTableViewSectionManager *sectionModel = self.sections[section];
    if (sectionModel.header) {
        return sectionModel.header.headerHeight;
    }
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section; {
    GPTableViewSectionManager *sectionModel = self.sections[section];
    if (sectionModel.header) {
        return sectionModel.header.headerView;
    }
    return nil;
}


#pragma mark 滚动 UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if ([self.delegate respondsToSelector:@selector(tableViewDidScroll:)]) {
        UITableView *tableView = (UITableView *)scrollView;
        [self.delegate tableViewDidScroll:tableView];
    }
    
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView; {
    if ([self.delegate respondsToSelector:@selector(tableViewWillBeginDragging:)]) {
        UITableView *tableView = (UITableView *)scrollView;
        [self.delegate tableViewWillBeginDragging:tableView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(tableViewDidEndScroll:)]) {
        UITableView *tableView = (UITableView *)scrollView;
        [self.delegate tableViewDidEndScroll:tableView];
    }
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate; {
    
    if (!decelerate && [self.delegate respondsToSelector:@selector(tableViewDidEndScroll:)]) {
        UITableView *tableView = (UITableView *)scrollView;
        [self.delegate tableViewDidEndScroll:tableView];
    }
    
    if ([self.delegate respondsToSelector:@selector(tableViewDidEndDragging:willDecelerate:)]) {
        UITableView *tableView = (UITableView *)scrollView;
        
        [self.delegate tableViewDidEndDragging:tableView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView; {
    if ([self.delegate respondsToSelector:@selector(tableViewDidEndScroll:)]) {
        UITableView *tableView = (UITableView *)scrollView;
        [self.delegate tableViewDidEndScroll:tableView];
    }
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if ([self.delegate respondsToSelector:@selector(tableViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        UITableView *tableView = (UITableView *)scrollView;
        [self.delegate tableViewWillEndDragging:tableView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}


@end

