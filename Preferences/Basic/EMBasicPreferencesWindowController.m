//
//  Created by Sergey Chikuyonok on 8/3/12.
//  Copyright (c) 2012 Аймобилко. All rights reserved.
//

#import "EMBasicPreferencesWindowController.h"
#import "Emmet.h"
#import "EMArrayTransformer.h"
#import "EMTildePathTransformer.h"
#import "EMUserDataLoader.h"

@interface EMBasicPreferencesWindowController ()
+ (NSArray *)loadOutputPreferences;
+ (void)storeOutputPreferences:(NSArray *)prefs;
- (void)setupOutputProfilesController;
@end

@implementation EMBasicPreferencesWindowController
@synthesize outputProfiles;

+ (void)initialize {
	EMArrayTransformer *caseTransformer = [[[EMArrayTransformer alloc] initWithArray:[NSArray arrayWithObjects:@"lower", @"upper", @"asis", nil]] autorelease];
	
	EMArrayTransformer *quotesTransformer = [[[EMArrayTransformer alloc] initWithArray:[NSArray arrayWithObjects:@"single", @"double", nil]] autorelease];
	
	EMArrayTransformer *tagNlTransformer = [[[EMArrayTransformer alloc] initWithArray:[NSArray arrayWithObjects:@"yes", @"no", @"decide", nil]] autorelease];
	
	EMArrayTransformer *selfClosingTransformer = [[[EMArrayTransformer alloc] initWithArray:[NSArray arrayWithObjects:@"html", @"xml", @"xhtml", nil]] autorelease];
	EMTildePathTransformer *pathTransformer = [[EMTildePathTransformer new] autorelease];
	
	
	[NSValueTransformer setValueTransformer:caseTransformer forName:@"EMCaseTransformer"];
	[NSValueTransformer setValueTransformer:quotesTransformer forName:@"EMQuotesTransformer"];
	[NSValueTransformer setValueTransformer:selfClosingTransformer forName:@"EMSelfClosingTransformer"];
	[NSValueTransformer setValueTransformer:pathTransformer forName:@"EMTildePathTransformer"];
	[NSValueTransformer setValueTransformer:tagNlTransformer forName:@"EMTagNewlineTransformer"];
}

+ (NSArray *)loadOutputPreferences {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *output = [defaults dictionaryForKey:Output];
	NSArray *syntax = [defaults arrayForKey:@"syntax"];
	
	NSMutableArray *outputProfiles = [NSMutableArray array];
	
	// add output profile to syntax list
	[syntax enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
		NSMutableDictionary *profileObj = [obj mutableCopy];
		NSString *syntaxId = [obj objectForKey:@"id"];
		if (syntaxId != nil && [output objectForKey:syntaxId] != nil) {
			[profileObj setObject:[[output objectForKey:syntaxId] mutableCopy] forKey:@"profile"];
		}
		
		[outputProfiles addObject:profileObj];
		[profileObj release];
	}];
	
	return outputProfiles;
}

+ (void)storeOutputPreferences:(NSArray *)prefs {
	NSMutableDictionary *profiles = [NSMutableDictionary dictionary];
	[prefs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[profiles setObject:[obj objectForKey:@"profile"] forKey:[obj objectForKey:@"id"]];
	}];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:profiles forKey:Output];
}

- (id)init {
    return [super initWithWindowNibName:@"BasicPreferences"];
}

- (void)awakeFromNib {
	[Emmet loadDefaults];
	[self setupOutputProfilesController];
}

- (void)hideTabExpanderControl {
	float __block offset = 0.0;
	NSView *parentView = [[self window] contentView];
	NSArray *subviews = [[parentView subviews] copy];
	[subviews enumerateObjectsUsingBlock:^(NSView *view, NSUInteger idx, BOOL *stop) {
		if (view.tag == 1) {
			float delta = 0.0;
			if (idx < [subviews count] - 1) {
				NSView *nextView = [subviews objectAtIndex:idx + 1];
				delta = nextView.frame.origin.y - view.frame.origin.y;

				// reposition all siblings
				[[subviews subarrayWithRange:NSMakeRange(idx + 1, [subviews count] - idx - 1)] enumerateObjectsUsingBlock:^(NSView *view, NSUInteger idx, BOOL *stop) {
					[view setFrameOrigin:NSMakePoint(view.frame.origin.x, view.frame.origin.y - delta)];
				}];
			} else {
				delta = view.frame.size.height;
			}
			
			[view setHidden:YES];
			
			offset += delta;
		}
	}];
	
	if (offset) {
		NSWindow *w = [self window];
		[w setFrame:NSMakeRect(w.frame.origin.x, w.frame.origin.y, w.frame.size.width, w.frame.size.height + offset) display:YES];
	}
}

- (IBAction)restoreDefaults:(id)sender {
	[EMUserDataLoader resetDefaults];
	[self setupOutputProfilesController];
}

- (IBAction)reloadExtensions:(id)sender {
	[[Emmet sharedInstance] reload];
}

- (void)windowDidLoad {
	NSWindow *window = [self window];
    [window setHidesOnDeactivate:NO];
    [window setExcludedFromWindowsMenu:YES];	
	[super windowDidLoad];
}

- (BOOL)windowShouldClose:(NSWindow *)window {
	 // validate editing
	[window makeFirstResponder:nil];
	
	// save output preferences
	[EMBasicPreferencesWindowController storeOutputPreferences:outputProfiles.content];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];
	
	[[Emmet sharedInstance] reload];
    return YES;
}

- (IBAction)pickExtensionsFolder:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
	[panel setAllowsMultipleSelection:NO];
	
	[panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
	    if (result == NSOKButton) {
			NSURL *url = [[panel URLs] objectAtIndex:0];
			if (url != nil) {
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				[defaults setValue:[url path] forKey:ExtensionsPath];
			}
	    }
	}];
}

- (void)setupOutputProfilesController {
	outputProfiles.content = [EMBasicPreferencesWindowController loadOutputPreferences];
}

- (void)dealloc {
	[super dealloc];
}

@end
