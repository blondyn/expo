/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ABI12_0_0RCTParserUtils.h"

#import "ABI12_0_0RCTLog.h"

@implementation ABI12_0_0RCTParserUtils

BOOL ABI12_0_0RCTReadChar(const char **input, char c)
{
  if (**input == c) {
    (*input)++;
    return YES;
  }
  return NO;
}

BOOL ABI12_0_0RCTReadString(const char **input, const char *string)
{
  int i;
  for (i = 0; string[i] != 0; i++) {
    if (string[i] != (*input)[i]) {
      return NO;
    }
  }
  *input += i;
  return YES;
}

void ABI12_0_0RCTSkipWhitespace(const char **input)
{
  while (isspace(**input)) {
    (*input)++;
  }
}

static BOOL ABI12_0_0RCTIsIdentifierHead(const char c)
{
  return isalpha(c) || c == '_';
}

static BOOL ABI12_0_0RCTIsIdentifierTail(const char c)
{
  return isalnum(c) || c == '_';
}

BOOL ABI12_0_0RCTParseIdentifier(const char **input, NSString **string)
{
  const char *start = *input;
  if (!ABI12_0_0RCTIsIdentifierHead(**input)) {
    return NO;
  }
  (*input)++;
  while (ABI12_0_0RCTIsIdentifierTail(**input)) {
    (*input)++;
  }
  if (string) {
    *string = [[NSString alloc] initWithBytes:start
                                       length:(NSInteger)(*input - start)
                                     encoding:NSASCIIStringEncoding];
  }
  return YES;
}

static BOOL ABI12_0_0RCTIsCollectionType(NSString *type)
{
  static NSSet *collectionTypes;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    collectionTypes = [[NSSet alloc] initWithObjects:
                       @"NSArray", @"NSSet", @"NSDictionary", nil];
  });
  return [collectionTypes containsObject:type];
}

NSString *ABI12_0_0RCTParseType(const char **input)
{
  NSString *type;
  ABI12_0_0RCTParseIdentifier(input, &type);
  ABI12_0_0RCTSkipWhitespace(input);
  if (ABI12_0_0RCTReadChar(input, '<')) {
    ABI12_0_0RCTSkipWhitespace(input);
    NSString *subtype = ABI12_0_0RCTParseType(input);
    if (ABI12_0_0RCTIsCollectionType(type)) {
      if ([type isEqualToString:@"NSDictionary"]) {
        // Dictionaries have both a key *and* value type, but the key type has
        // to be a string for JSON, so we only care about the value type
        if (ABI12_0_0RCT_DEBUG && ![subtype isEqualToString:@"NSString"]) {
          ABI12_0_0RCTLogError(@"%@ is not a valid key type for a JSON dictionary", subtype);
        }
        ABI12_0_0RCTSkipWhitespace(input);
        ABI12_0_0RCTReadChar(input, ',');
        ABI12_0_0RCTSkipWhitespace(input);
        subtype = ABI12_0_0RCTParseType(input);
      }
      if (![subtype isEqualToString:@"id"]) {
        type = [type stringByReplacingCharactersInRange:(NSRange){0, 2 /* "NS" */}
                                             withString:subtype];
      }
    } else {
      // It's a protocol rather than a generic collection - ignore it
    }
    ABI12_0_0RCTSkipWhitespace(input);
    ABI12_0_0RCTReadChar(input, '>');
  }
  ABI12_0_0RCTSkipWhitespace(input);
  ABI12_0_0RCTReadChar(input, '*');
  return type;
}

@end
