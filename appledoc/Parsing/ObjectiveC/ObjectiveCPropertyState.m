//
//  ObjectiveCPropertyState.m
//  appledoc
//
//  Created by Tomaž Kragelj on 3/20/12.
//  Copyright (c) 2012 Tomaz Kragelj. All rights reserved.
//

#import "Objects.h"
#import "ObjectiveCPropertyState.h"

@implementation ObjectiveCPropertyState

- (NSUInteger)parseStream:(TokensStream *)stream forParser:(ObjectiveCParser *)parser store:(Store *)store {
	// Match property, then return to previous stream. If current stream position doesn't start a property, consume one token and return.
	LogParDebug(@"Matched property definition.");
	[store setCurrentSourceInfo:stream.current];
	[store beginPropertyDefinition];
	[stream consume:2];

	NSMutableString *declaration = [NSMutableString stringWithString:@"@property "];

	// Parse attributes.
	if ([stream matches:@"(", nil]) {
		LogParDebug(@"Matching attributes...");
		[store beginPropertyAttributes];
		NSArray *delimiters = [NSArray arrayWithObjects:@"(", @",", @")", nil];
		NSUInteger found = [stream matchStart:@"(" end:@")" block:^(PKToken *token, NSUInteger lookahead, BOOL *stop) {
			LogParDebug(@"Matched %@.", token);
			[declaration appendFormat:@"%@ ", token.stringValue];
			if ([token matches:delimiters]) return;
			[store appendType:token.stringValue];
		}];
		if (found == NSNotFound) {
			LogParDebug(@"Failed matching attributes, bailing out.");
			[store cancelCurrentObject]; // attribute types
			[store cancelCurrentObject]; // property definition
			[parser popState];
			return GBResultFailedMatch;
		}
		[store endCurrentObject];
	}
	
	// Parse declaration.
	LogParDebug(@"Matching types and name.");
	[store beginTypeDefinition];
	NSUInteger found = [stream matchUntil:@";" block:^(PKToken *token, NSUInteger lookahead, BOOL *stop) {
		LogParDebug(@"Matched %@.", token);
		if ([token matches:@";"]) {
			[declaration appendFormat:@"%@ ", token.stringValue];
			return;
		} else if ([[stream la:lookahead+1] matches:@";"]) {
			[store endCurrentObject];
			[store appendPropertyName:token.stringValue];
			[declaration appendFormat:@"%@ ", token.stringValue];
			return;
		}
		[store appendType:token.stringValue];
		[declaration appendFormat:@"%@ ", token.stringValue];
	}];
	if (found == NSNotFound) {
		LogParDebug(@"Failed matching type and name, bailing out.");
		[store cancelCurrentObject];
		[parser popState]; 
		return GBResultFailedMatch;
	}
	[store endCurrentObject];
	
	LogParVerbose(@"%@", declaration);
	[parser popState];
	return GBResultOk;
}

@end
