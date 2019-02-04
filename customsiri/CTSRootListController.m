#import "CTSRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <objc/runtime.h>
#import <notify.h>

@interface PSSpecifier (PWithP)
+(id)specifierWithSpecifier:(id)arg1;
@end

@implementation CTSRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
		for (PSSpecifier* spec in _specifiers)
		{
			if ([[spec properties][@"bundle"] isKindOfClass:[NSString class]] && [[spec properties][@"bundle"] isEqualToString:@"LibActivator"])
			{
				templateSpec = spec;
				[_specifiers removeObject:spec];
			}
		}
	}

	return _specifiers;
}

-(id)init
{
	self = [super init];
	if (self)
	{
		UIBarButtonItem* plusBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
	    [self.navigationItem setRightBarButtonItem:plusBtn];

		//load activator bundle:
		NSBundle* activatorBndl = [NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/LibActivator.bundle"];
		if (!activatorBndl.loaded)
		{
			[activatorBndl load];
		}
	}
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	//load values from prefs:
	NSString* domain = @"com.squ1dd13.customsiri";
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	NSMutableArray* replies = [[prefs objectForKey:@"replies" inDomain:domain] mutableCopy];
	for (NSDictionary* rep in replies)
	{
		NSUInteger index = [rep[@"index"] integerValue];
		lastIndex = index - 1;
		[self addButtonPressed];
	}
}

-(void)addButtonPressed
{
	lastIndex++;
	//create command text field:
	PSSpecifier* commandSpec = [PSSpecifier preferenceSpecifierNamed:nil target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:14 edit:nil];
	NSDictionary* commandProp = @{
		@"placeholder" : @"Enter Command",
		@"height" : @"85",
		@"defaults" : @"com.squ1dd13.customsiri",
		@"cell" : @"PSEditTextViewCell",
		@"key" : @"command",
		@"cellClass" : objc_getClass("CTSTextEditCell"),
		@"title" : @"Command:",
		@"index" : @(lastIndex)
	};
	[commandSpec setProperties:[commandProp mutableCopy]];

	//create response text field:
	PSSpecifier* responseSpec = [PSSpecifier preferenceSpecifierNamed:nil target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:14 edit:nil];
	NSDictionary* responseProp = @{
		@"placeholder" : @"Enter Response",
		@"height" : @"85",
		@"defaults" : @"com.squ1dd13.customsiri",
		@"cell" : @"PSEditTextViewCell",
		@"key" : @"response",
		@"cellClass" : objc_getClass("CTSTextEditCell"),
		@"title" : @"Response:",
		@"index" : @(lastIndex)
	};
	[responseSpec setProperties:[responseProp mutableCopy]];

	//create activator cell:
	PSSpecifier* activatorSpec = [PSSpecifier preferenceSpecifierNamed:@"Activator Event" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:objc_getClass("ActivatorSettingsController") cell:1 edit:nil];
	[activatorSpec setProperties:[[templateSpec properties] mutableCopy]];
	[activatorSpec properties][@"activatorEvent"] = [NSString stringWithFormat:@"com.squ1dd13.customsiri-event%lu", (unsigned long)lastIndex];
	[activatorSpec properties][@"index"] = @(lastIndex);

	//create remove button:
	PSSpecifier* btnSpec = [PSSpecifier preferenceSpecifierNamed:@"Remove Command" target:self set:nil get:nil detail:nil cell:13 edit:nil];
	NSDictionary* btnProp = @{
		@"action" : @"remove:",
		@"cell" : @"PSButtonCell",
		@"label" : @"Remove Command",
		@"index" : @(lastIndex)
	};
	btnSpec.buttonAction = @selector(remove:);
	[btnSpec setProperties:[btnProp mutableCopy]];

	//create group cell:
	PSSpecifier* groupSpec = [PSSpecifier preferenceSpecifierNamed:nil target:nil set:nil get:nil detail:nil cell:0 edit:nil];
	NSDictionary* groupProp = @{
		@"cell" : @"PSGroupCell",
		@"index" : @(lastIndex + 1)
	};
	[groupSpec setProperties:[groupProp mutableCopy]];

	//show specifiers
	[self addSpecifier:commandSpec animated:YES];
	[self addSpecifier:responseSpec animated:YES];
	[self addSpecifier:activatorSpec animated:YES];
	[self addSpecifier:btnSpec animated:YES];
	[self addSpecifier:groupSpec animated:YES];

	//create dict in array
	NSString* domain = @"com.squ1dd13.customsiri";
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	NSMutableArray* replies = [[prefs objectForKey:@"replies" inDomain:domain] mutableCopy];
	BOOL new = YES;
	for (NSDictionary* rep in replies)
	{
		if ([rep[@"index"] integerValue] == lastIndex)
		{
			new = NO;
			break;
		}
	}
	if (new)
	{
		replies = replies ? replies : [NSMutableArray new];
		NSDictionary* newReply = @{
			@"index" : @(lastIndex),
			@"command" : @"",
			@"response" : @"",
			@"event" : [NSString stringWithFormat:@"com.squ1dd13.customsiri-event%lu", (unsigned long)lastIndex]
		};
		[replies addObject:newReply];
		[prefs setObject:replies forKey:@"replies" inDomain:domain];
	}
}

-(void)remove:(PSSpecifier*)spec
{
	NSInteger index = [[spec properties][@"index"] integerValue];
	//find specifiers to remove:
	for (PSSpecifier* otherSpec in _specifiers)
	{
		if ([otherSpec properties][@"index"] && [[otherSpec properties][@"index"] integerValue] == index)
		{
			[self removeSpecifier:otherSpec animated:YES];
		}
	}

	//remove from array:
	NSString* domain = @"com.squ1dd13.customsiri";
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	NSMutableArray* replies = [[prefs objectForKey:@"replies" inDomain:domain] mutableCopy];
	replies = replies ? replies : [NSMutableArray new];
	for (int i = 0; i < replies.count; i++)
	{
		NSDictionary* rep = replies[i];
		if ([rep[@"index"] integerValue] == index)
		{
			[replies removeObject:rep];
			break;
		}
	}
	[prefs setObject:[replies copy] forKey:@"replies" inDomain:domain];
}

-(void)setPreferenceValue:(id)arg1 specifier:(PSSpecifier*)spec
{
	NSMutableDictionary* prop = [spec properties];
	if (!prop[@"index"])
	{
		[super setPreferenceValue:arg1 specifier:spec];
		return;
	}

	NSUInteger index = [prop[@"index"] integerValue];
	NSString* domain = prop[@"defaults"];
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	NSMutableArray* replies = [[prefs objectForKey:@"replies" inDomain:domain] mutableCopy];
	replies = replies ? replies : [NSMutableArray new];
	NSDictionary* rep;
	for (NSDictionary* r in replies)
	{
		if ([r[@"index"] integerValue] == index)
		{
			rep = r;
			break;
		}
	}
	if (rep)
	{
		[replies removeObject:rep];
	}
	NSMutableDictionary* reply = rep ? [rep mutableCopy] : [NSMutableDictionary new];
	reply[@"index"] = @(index);
	reply[@"event"] = [NSString stringWithFormat:@"com.squ1dd13.customsiri-event%lu", (unsigned long)index];
	reply[prop[@"key"]] = arg1;

	[replies addObject:[reply copy]];
	[prefs setObject:[replies copy] forKey:@"replies" inDomain:domain];
	notify_post("com.squ1dd13.customsiri-prefschanged");
}

-(id)readPreferenceValue:(PSSpecifier*)spec
{
	NSMutableDictionary* prop = [spec properties];
	if (!prop[@"index"])
	{
		return [super readPreferenceValue:spec];
	}

	NSUInteger index = [prop[@"index"] integerValue];
	NSString* domain = prop[@"defaults"];
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	NSMutableArray* replies = [[prefs objectForKey:@"replies" inDomain:domain] mutableCopy];
	for (NSDictionary* r in replies)
	{
		if ([r[@"index"] integerValue] == index)
		{
			return r[prop[@"key"]];
		}
	}
	return nil;
}

@end

@implementation CTSTextEditCell
-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier*)spec {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:spec];
	if (self)
	{
		((UITextContentView *)self.textView).font = [UIFont systemFontOfSize:12];
		((UITextContentView *)self.textView).delegate = self;
		NSMutableDictionary* prop = [spec properties];
		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, [prop[@"height"] integerValue])];
		titleLabel.text = prop[@"title"];
		[self addSubview:titleLabel];
		[titleLabel sizeToFit];
	}
	return self;
}
- (void)layoutSubviews {
	[super layoutSubviews];
	((UITextContentView *)self.textView).frame = CGRectMake(110, 5, ((UITextContentView *)self.textView).frame.size.width - 110, ((UITextContentView *)self.textView).frame.size.height);
	((UITextContentView *)self.textView).font = [UIFont systemFontOfSize:12];
}
- (BOOL)textContentView:(id)arg1 shouldChangeTextInRange:(NSRange)arg2 replacementText:(id)arg3{
	if ([arg3 isEqualToString:@"\n"]) {
		[((UITextContentView *)self.textView) resignFirstResponder];
		return NO;
	}
	else {
		return YES;
	}
}
@end
