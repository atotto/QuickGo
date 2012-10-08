#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import  <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    @autoreleasepool {
        
        NSDictionary *regexpDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"(?<!\\w)(break|default|func|interface|select|case|defer|go|map|struct|chan|else|goto|package|switch|const|fallthrough|if|range|type|continue|for|import|return|var)(?!\\w)", @"keyword",
                                          @"(?<!\\w)(bool|byte|complex64|complex128|error|float32|float64|int|int8|int16|int32|int64|rune|string|uint|uint8|uint16|uint32|uint64|uintptr)(?!\\w)", @"types",
                                          @"(?<!\\w)(true|false|iota)(?!\\w)", @"constants",
                                          @"(?<!\\w)(nil)(?!\\w)", @"zero",
                                          @"(?<!\\w)(append|cap|close|complex|copy|delete|imag|len|make|new|panic|print|println|real|recover)(?!\\w)", @"functions",
                                          @"(?<!https?:)(//.*?$)", @"comment",
                                          @"/\\*(.*?)\\*/", @"docComment",
                                          @"(@?\"(?:[^\"\\\\]|\\\\.)*\")", @"string",
                                          @"(@?`(?:[^`\\\\]|\\\\.)*`)", @"rawLiteral",
                                          @"('.')", @"character",
                                          //@"(\\.[a-zA-Z]+)", @"attribute",
                                          //@"(\\d)", @"number",
                                          @"((https?://)([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([/\\w \\.-]*)*/?)", @"url",
                                          nil
                                          ];
        
        NSDictionary *replaceDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"<span class='HighlightKeyword'>$1</span>", @"keyword",
                                           @"<span class='HighlightTypes'>$1</span>", @"types",
                                           @"<span class='HighlightConstants'>$1</span>", @"constants",
                                           @"<span class='HighlightZero'>$1</span>", @"zero",
                                           @"<span class='HighlightFunction'>$1</span>", @"functions",
                                           @"<span class='HighlightComment'>$1</span>", @"comment",
                                           @"<span class='HighlightDocComment'>$0</span>", @"docComment",
                                           @"<span class='HighlightString'>$1</span>", @"string",
                                           @"<span class='HighlightString'>$1</span>", @"rawLiteral",
                                           @"<span class='HighlightCharacter'>$1</span>", @"character",
                                           //@"<span class='HighlightAttribute'>$1</span>", @"attribute",
                                           //@"<span class='HighlightNumber'>$1</span>", @"number",
                                           @"<span class='HighlightURL'><a href=\'$0\'>$0</a></span>", @"url",
                                           nil
                                           ];
        
        NSDictionary *htmlEscape = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"&amp;", @"&",
                                           @"&lt;", @"<",
                                           @"&gt;", @">",
                                           nil
                                           ];
        
        NSString *source = [NSString stringWithContentsOfURL:(__bridge NSURL *)url encoding:NSUTF8StringEncoding error:nil];

        
        NSString* escaped = source.copy;
        
        for(NSString* key in htmlEscape) {            
            NSRange range = NSMakeRange(0,[escaped length]);
            
            NSRegularExpression *regexp = [NSRegularExpression
                                           regularExpressionWithPattern:key
                                           options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionAnchorsMatchLines
                                           error:nil
                                           ];
            
            NSString *tmp = [regexp
                             stringByReplacingMatchesInString:escaped
                             options:NSMatchingReportProgress
                             range:range
                             withTemplate:[htmlEscape objectForKey:key]
                             ];
            
            escaped = tmp.copy;
        }

        
        
        NSString* coloredString = escaped.copy;
        
        
        for(NSString* key in regexpDictionary) {
            
            NSRange range = NSMakeRange(0,[coloredString length]);
            
            NSString* expression = [regexpDictionary objectForKey:key];
            
            NSRegularExpression *regexp = [NSRegularExpression
                                           regularExpressionWithPattern:expression
                                           options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionAnchorsMatchLines
                                           error:nil
                                           ];
            
            NSString *tmp = [regexp
                                  stringByReplacingMatchesInString:coloredString
                                  options:NSMatchingReportProgress
                                  range:range
                                  withTemplate:[replaceDictionary objectForKey:key]
                                  ];
            
            coloredString = tmp.copy;
        }
        

        //NSString* path = [[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:@"style.css"];
        NSString* path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/QuickLook/QuickGo.qlgenerator/Contents/Resources/style.css"];
       
        NSError* err;
        NSString* css = [NSString
                         stringWithContentsOfFile:path
                         encoding:NSUTF8StringEncoding
                         error:&err];
        
        NSMutableString *html = [[NSMutableString alloc] init];
        [html appendString:@"<html>"];
        [html appendString:@"<head>"];
        [html appendString:@"<meta charset=\"UTF-8\" />"];
        
        [html appendString:@"<style type=\"text/css\">"];
        [html appendString:css];
        [html appendString:@"</style>"];
        [html appendString:@"</head>"];
        [html appendString:@"<body>"];
        [html appendString:@"<pre class=\"code\">"];
        [html appendString:coloredString];
        [html appendString:@"</pre>"];
        [html appendString:@"<p>This source code is <a href=\"http://golang.org/\">The Go Programming Language</a>.</p>"];
        
        [html appendString:@"</body></html>"];
                
        QLPreviewRequestSetDataRepresentation(preview,(__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],kUTTypeHTML,NULL);
    }
    
    return noErr;
}


void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
