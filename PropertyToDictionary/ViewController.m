//
//  ViewController.m
//  PropertyToDictionary
//
//  Created by Dragon Sun on 2017/8/7.
//  Copyright © 2017年 Dragon Sun. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak) IBOutlet NSTextFieldCell *dictionaryNameTextField;
@property (weak) IBOutlet NSTextFieldCell *objectNameTextField;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation ViewController

- (IBAction)convertAction:(id)sender {
    self.textView.string = [self dictionaryStringFromDictionaryName:self.dictionaryNameTextField.title
                                                         ObjectName:self.objectNameTextField.title
                                                       PropertyText:self.textView.string];
}


/**
 向字符串尾部追加指定数量个相同的字符串

 @param string 字符串
 @param appendString 要追加的字符串
 @param time 追加的次数
 */
- (void)string:(NSMutableString *)string appendString:(NSString *)appendString time:(NSUInteger)time {
    for (NSUInteger i = 0; i < time; i++) {
        [string appendString:appendString];
    }
}


/**
 根据属性声明生成对应的内容字典代码字符串
 
 例如：
    传入字典名称：
        dict
    传入属性声明字符串：
        @property(retain, nonatomic) NSMutableDictionary *m_dicForwardParas;
        @property(nonatomic) unsigned int m_forwardType; // @synthesize m_forwardType=_m_forwardType;
        @property(nonatomic) _Bool m_bIsBrandSendMass;
    输出：
        NSDictionary *dict = @{
                               @"m_dicForwardParas"  : object.m_dicForwardParas    ,
                               @"m_forwardType"      : @(object.m_forwardType)     ,
                               @"m_bIsBrandSendMass" : @(object.m_bIsBrandSendMass)
                               }

 @param dictionaryName 字典名称
 @param objectName 对象名称
 @param propertyText 属性声明字符串
 @return 内容字典代码字符串
 */
- (NSString *)dictionaryStringFromDictionaryName:(NSString *)dictionaryName ObjectName:(NSString *)objectName PropertyText:(NSString *)propertyText {
    // 将输入的文本按照分行符拆分到数组
    NSArray *lineArr = [propertyText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // 只保留包含'@proeprty'、')'、';'的项
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self CONTAINS '@property' AND self CONTAINS ')' AND self CONTAINS ';'"];
    lineArr = [lineArr filteredArrayUsingPredicate:predicate];
    
    // 循环处理每一项
    NSMutableArray *propertyArr = [NSMutableArray array];
    NSMutableArray *isObjectArr = [NSMutableArray array];
    NSUInteger propertyMaxLength = 0;
    BOOL haveNoObject = NO;
    NSString *s;
    NSRange range;
    BOOL isObject;
    for (NSString *line in lineArr) {
        s = line;
        
        // 将')'之前以及自己删除
        range = [s rangeOfString:@")"];
        s = [s substringFromIndex:range.location + 1];
        
        // 将';'之后以及自己删除
        range = [s rangeOfString:@";"];
        s = [s substringToIndex:range.location];
        
        // 去除两头的空白字符
        s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // 判断是否为对象(是否包含*)
        range = [s rangeOfString:@"*"];
        isObject = (NSNotFound != range.location);
        
        // 按照空格进行拆分
        NSArray *tokenArr = [s componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // 如果第一部分是空字符串，则代表该行格式不正确，忽略掉
        if ([tokenArr[0] isEqualToString:@""]) continue;
        
        // 如果第一部分是'id'，则为对象
        if ([tokenArr[0] isEqualToString:@"id"])
            isObject = YES;
        
        // 最后一部分就是属性名
        s = [tokenArr lastObject];
        
        // 如果有'*'，则把*去掉
        range = [s rangeOfString:@"*"];
        if (NSNotFound != range.location) {
            s = [NSString stringWithFormat:@"%@%@", [s substringToIndex:range.location], [s substringFromIndex:range.location + range.length]];
        }
        
        // 记录属性名最大长度
        propertyMaxLength = MAX(propertyMaxLength, s.length);

        // 记录信息
        [propertyArr addObject:s];
        [isObjectArr addObject:@(isObject)];
        
        // 记录是否有非对象的属性
        haveNoObject = haveNoObject || (!isObject);
    }
    
    // 组合成字典
    NSMutableArray *retArr = [NSMutableArray array];
    NSUInteger suffixMaxLength = propertyMaxLength + objectName.length + 1;
    if (haveNoObject) suffixMaxLength += 3;     // 不是对象需要加上@()，所以有非对象的属性，则长度需要加3
    
    // 第一项
    NSString *dictName = [dictionaryName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *firstLine = [NSString stringWithFormat:@"NSDictionary *%@ = @{", dictName];
    [retArr addObject:firstLine];
    NSUInteger spaceCount = ({ NSString *s = retArr[0]; s.length; });
    
    // 最后一项
    NSMutableString *lastLine = [NSMutableString string];
    [self string:lastLine appendString:@" " time:spaceCount];
    [lastLine appendString:@"};"];
    [retArr addObject:lastLine];

    // 中间的项
    for (NSUInteger i = 0; i < propertyArr.count; i++) {
        NSLog(@"%ld", i);
        s = propertyArr[i];
        isObject = [isObjectArr[i] boolValue];
        NSMutableString *formatString = [NSMutableString string];
        
        // 格式化字符串头部添加spaceCount个空格
        [self string:formatString appendString:@" " time:spaceCount];
        
        // 格式化字符串追加'@"%@"'
        [formatString appendString:@"@\"%@\""];
        
        // 格式化字符串key部分对齐
        [self string:formatString appendString:@" " time:(propertyMaxLength - s.length)];
        
        // 格式化字符串追加' : '
        [formatString appendString:@" : "];
        
        // 格式化字符串追加'%@'，如果是对象，则追加'@(%@)'
        if (isObject) {
            [formatString appendString:@"%@"];
        } else {
            [formatString appendString:@"@(%@)"];
        }
        
        // 生成字典项value字符串
        objectName = [objectName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *valueString = [NSString stringWithFormat:@"%@.%@", objectName, s];
        
        // 如果不是最后一行，则尾部空格对齐后添加','
        if (i < propertyArr.count - 1) {
            NSUInteger time = suffixMaxLength - valueString.length;
            if (!isObject && haveNoObject) time -= 3;   // 不是对象因为要添加'@()'，多了3个字符，所以后面的空格要少加3个
            [self string:formatString appendString:@" " time:time];
            [formatString appendString:@","];
        }
        
        // 生成行
        s = [NSString stringWithFormat:formatString, s, valueString];
        
        // 插入到数组中
        [retArr insertObject:s atIndex:retArr.count - 1];
    }
    
    return [retArr componentsJoinedByString:@"\n"];
}

@end
