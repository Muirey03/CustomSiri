#include <vector>
#import "RemoteLog.h"

@interface AceObject : NSObject
@property(copy, nonatomic) NSString *refId;
@property(copy, nonatomic) NSString *aceId;
- (id)properties;
- (id)dictionary;
+ (id)aceObjectWithDictionary:(id)arg1 context:(id)arg2;
@end

@interface AFConnection : NSObject
@property (nonatomic, copy) NSString *userSpeech;
@end

@interface AFConnectionClientServiceDelegate : NSObject
@end

struct Reply
{
	NSString* command;
	NSString* response;
};

static std::vector<Reply> makeRepliesVector(NSDictionary* repliesDict)
{
	NSArray<NSDictionary*>* repArr = repliesDict[@"replies"];
	std::vector<struct Reply> replies(repArr.count);
	for (int i = 0; i < repArr.count; i++)
	{
		struct Reply r = { repArr[i][@"command"], repArr[i][@"response"] };
		replies[i] = r;
	}
	return replies;
}

static NSDictionary* makePlistDict(std::vector<struct Reply> replies)
{
	NSMutableDictionary* dict = [NSMutableDictionary new];
	NSMutableArray* repArr = [NSMutableArray new];
	for (int i = 0; i < replies.size(); i++)
	{
		struct Reply rep = replies[i];
		NSDictionary* rDict = @{@"command" : rep.command, @"response" : rep.response};
		[repArr addObject:rDict];
	}
	dict[@"replies"] = [repArr copy];
	return [dict copy];
}

static std::vector<struct Reply> customReplies;

static void loadPrefs()
{
	struct Reply r;
	r.command = @"welcome";
	r.response = @"To Jurassic Park.";
	customReplies.push_back(r);
}

#pragma mark Getting User Speech
%hook AFConnectionClientServiceDelegate
-(void)speechRecognized:(NSObject*)arg1 {
	//arg1 --> recognition --> phrases --> object --> interpretations --> object --> tokens --> object --> text
	NSMutableString *fullPhrase = [NSMutableString string];
	NSArray *phrases = [arg1 valueForKeyPath:@"recognition.phrases"];
	if([phrases count] > 0) {
		for(id phrase in phrases) {
			NSArray *interpretations = [(NSObject *)phrase valueForKey:@"interpretations"];
			if([interpretations count] > 0) {
				id interpretation = interpretations[0];
				NSArray *tokens = [(NSObject *)interpretation valueForKey:@"tokens"];
				if([tokens count] > 0) {
					for(id token in tokens) {
						NSLog(@"%@", [(NSObject *)token valueForKey:@"text"]);
						[fullPhrase appendString:[[(NSObject *)token valueForKey:@"text"] stringByAppendingString:@" "]];
					}
				}
			}
		}
	}
	NSString *speech = [[[fullPhrase copy] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
	[[self valueForKey:@"_connection"] setValue:speech forKey:@"userSpeech"];
	%orig;
}
%end

#pragma mark Custom reply
%hook AFConnection
%property (nonatomic, copy) NSString *userSpeech;

-(void)_doCommand:(id)arg1 reply:(/*^block*/id)arg2 {
	//work out if we should be giving a custom reply
	NSString *stringToSpeak = @"rreeeeeee";

	BOOL hasReply = NO;
	for (int i = 0; i < customReplies.size(); i++)
	{
		if ([[customReplies[i].command lowercaseString] isEqualToString:[self.userSpeech lowercaseString]])
		{
			hasReply = YES;
			stringToSpeak = customReplies[i].response;
			break;
		}
	}

	if (!hasReply) {
		//say the original and quit
		%orig;
		return;
	}

	//create a context for the ace object
	Class context = %c(BasicAceContext);
	NSObject* object = arg1;

	//get the original dictionary
	NSMutableDictionary *dict = [[object valueForKey:@"dictionary"] mutableCopy];

	/*
	How it works:
	Siri processes what the user says to it, and then cooks up a reply. It then synthesizes the speech for the reply, while displaying a view with the spoken text.
	To give custom replies, we need to a) change the string that is synthesized, and b) change the text of the view.
	*/

	//change the text on the views
	if([dict objectForKey:@"views"]) {
		NSArray *views = [dict objectForKey:@"views"];
		NSMutableArray *modifiedViews = [NSMutableArray array];

		//views is an array of dictionaries
		for(NSDictionary *view in views) {
			NSMutableDictionary *mutableView = [view mutableCopy];
			[mutableView setValue:stringToSpeak forKey:@"speakableText"];
			[mutableView setValue:stringToSpeak forKey:@"text"];
			[modifiedViews addObject:[mutableView copy]];
		}

		[dict setValue:[modifiedViews copy] forKey:@"views"];
	}

	//change the speech string
	if([dict objectForKey:@"dialogStrings"]) {
		[dict setValue:@[stringToSpeak] forKey:@"dialogStrings"];
	}

	//create a new ace object with the modified dictionary
	AceObject *aceObject = [%c(AceObject) aceObjectWithDictionary:[dict copy] context:context];

	//run normally with the modified ace object and the original block
	%orig(aceObject, arg2);

	//reset
	self.userSpeech = @"";
}
%end

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)arg1
{
	%orig;
	loadPrefs();
}
%end
