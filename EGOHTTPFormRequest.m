//
//  EGOHTTPFormRequest.m
//  EGOHTTPRequest
//
//  Created by Shaun Harrison on 3/28/10.
//  Copyright (c) 2010 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOHTTPFormRequest.h"

#define kMultiPartFormBoundary @"----FormBoundary+2f552ede3c76ff0bbca9dfa8e"

@interface EGOHTTPFormRequest ()
- (void)buildFormDataPostBody;
@end

@implementation EGOHTTPFormRequest
@synthesize stringEncoding=_stringEncoding;

- (void)setPostValue:(id<NSObject>)value forKey:(NSString*)key {
	if(!_formData) {
		_formData = [[NSMutableDictionary alloc] init];
	}
	
	[_formData setObject:value forKey:key];
}

- (NSData*)formDataFromKey:(NSString*)key Value:(id)value{
	NSMutableData *body = [[NSMutableData alloc] init];
	if(![value isKindOfClass:[NSArray class]]){
		[body appendData:[[NSString stringWithFormat:@"--%@\r\n"
							"Content-Disposition: form-data; name=\"%@\"",
							kMultiPartFormBoundary, key] dataUsingEncoding:_stringEncoding]];
	}
	if([value isKindOfClass:[NSArray class]]) {
		for(id subvalue in value) {
			[body appendData:[self formDataFromKey:key Value:subvalue]];
		}
	} else if([value isKindOfClass:[NSData class]]) {
		[body appendData:[[NSString stringWithFormat:@"\r\n\r\n"] dataUsingEncoding:_stringEncoding]];
		[body appendData:value];
	} else if([value isKindOfClass:[UIImage class]]) {
		[body appendData:[[NSString stringWithFormat:@"; filename=\"image.jpg\";\r\n"
							"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:_stringEncoding]];
		[body appendData:UIImageJPEGRepresentation(value, 0.6)];
	} else {
		[body appendData:[[NSString stringWithFormat:@"\r\n\r\n"] dataUsingEncoding:_stringEncoding]];
		[body appendData:[[value description] dataUsingEncoding:_stringEncoding]];
	}
	if(![value isKindOfClass:[NSArray class]]){
		[body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:_stringEncoding]];
	}
	NSData *data = [NSData dataWithData:body];
	[body release];
	return data;
}

- (void)buildFormDataPostBody {
	if(self.requestMethod == nil)
		self.requestMethod = @"POST";
	if(!_formData) return;

	BOOL multipart=NO;
	for(id value in _formData.allValues) {
		if(![value isKindOfClass:[NSString class]]) {
			multipart=YES;
			break;
		}
	}
	
	if(_stringEncoding == 0) {
		_stringEncoding = NSUTF8StringEncoding;
	}

	if(!multipart) {
		NSMutableString* requestString = [[NSMutableString alloc] init];

		for(NSString* key in _formData) {
			NSString* value = [[_formData objectForKey:key] description];

			if(!value || value.length == 0) {
				[requestString appendFormat:@"%@=&", [key urlEncodedStringWithEncoding:_stringEncoding]];
			} else {
				[requestString appendFormat:@"%@=%@&", [key urlEncodedStringWithEncoding:_stringEncoding], [value urlEncodedStringWithEncoding:_stringEncoding]];
			}
		}

		if(requestString.length > 0) {
			[requestString replaceCharactersInRange:NSMakeRange(requestString.length-1, 1) withString:@""]; // Removes trailing &
			self.requestBody = [requestString dataUsingEncoding:_stringEncoding];

			NSString* charset = (NSString*)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(_stringEncoding));
			[self addRequestHeader:@"Content-Type" value:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]];
		}

		[requestString release];
	} else {
		NSMutableData *body=[[NSMutableData alloc] init];
		for(NSString *key in _formData.allKeys){
			[body appendData:[self formDataFromKey:key Value:[_formData objectForKey:key]]];
		}
		[body appendData:[[NSString stringWithFormat:@"--%@--\r\n", kMultiPartFormBoundary] dataUsingEncoding:_stringEncoding]];
		[self addRequestHeader:@"Content-Type" value:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",
		                                                                        kMultiPartFormBoundary]];
		[self addRequestHeader:@"Content-Length" value:[NSString stringWithFormat:@"%d", [body length]]];
		self.requestBody=[NSData dataWithData:body];
		[body release];
	}
}

- (void)startAsynchronous {
	[self buildFormDataPostBody];
	[super startAsynchronous];	
}

- (void)startSynchronous {
	[self buildFormDataPostBody];
	[super startSynchronous];
}

- (void)dealloc {
	[_formData release];
	[super dealloc];
}

@end

@implementation NSString (EGOHTTPFormRequest)

/**
 * @see http://github.com/pokeb/asi-http-request/raw/master/Classes/ASIFormDataRequest.m
 */

- (NSString*)urlEncodedString { 
	return [self urlEncodedStringWithEncoding:NSUTF8StringEncoding];
}

- (NSString*)urlEncodedStringWithEncoding:(NSStringEncoding)encoding { 
	NSString* newString = [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
	
	if (newString) {
		return newString;
	}
	
	return @"";
}

@end
