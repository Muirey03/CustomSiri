#import <Preferences/PSListController.h>
#import <Preferences/PSTextViewTableCell.h>
@class PSSpecifier;

@interface CTSRootListController : PSListController
{
    NSUInteger lastIndex;
    PSSpecifier* templateSpec;
}
-(void)addButtonPressed;
@end

@interface UITextContentView : UIView
@property (nonatomic, retain) UIFont *font;
@property (nonatomic) id delegate;
- (BOOL)resignFirstResponder;
@end
@interface CTSTextEditCell : PSTextViewTableCell
{
    UILabel* titleLabel;
}
@end

@interface NSUserDefaults (internal)
-(void)setObject:(id)arg1 forKey:(id)arg2 inDomain:(id)arg3;
-(id)objectForKey:(id)arg1 inDomain:(id)arg2;
@end
