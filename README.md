# PropertyToDictionary

有时候需要打印一个对象的许多属性值，但是这个对象有没有实现 `description` 方法，我一般会将属性封装到一个字典中，然后将这个字典打印出来。例如有下面一个对象：

```objective-c
@interface Person: NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSUInteger age;

@end

```

我要查看其中的属性值，我会写如下的代码：

```objective-c
NSDictionary *msgDict = @{
                          @"name" : person.name,
                          @"age"  : person.age
                          };
```

然后将这个字典的内容打印出来，就能查看对象的属性值内容了。

当然用 runtime 来遍历打印属性值是一个省事的办法，但是有时只想关注对象中的一部分属性值，我觉得用字典的方式更为方便。

不过有时属性太多，写起来实在太累，于是就想到写一个工具来完成这个工作，于是便有了 PropertyToDictionary 。

使用很简单，指定字典名称、对象名称和属性声明

![](https://github.com/dragonsun7/PropertyToDictionary/blob/master/1.png?raw=true)

点击转换，OK！

![](https://github.com/dragonsun7/PropertyToDictionary/blob/master/2.png?raw=true)

