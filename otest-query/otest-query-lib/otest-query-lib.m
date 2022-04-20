//
// Copyright 2004-present Facebook. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "OtestQuery.h"

__attribute__((constructor)) static void EntryPoint(void)
{
  NSString *otestQueryBundlePath = [[[NSProcessInfo processInfo] environment] objectForKey:@"OtestQueryBundlePath"];
  NSCAssert(otestQueryBundlePath != nil,
            @"The environment variable 'OtestQueryBundlePath' is missing.");


  // HAX: on iOS 15, there's strangeness around load orders that need to be worked around. This
  // lets the bundle loader logic work without deadlocking.
  dispatch_block_t queryBlock =  ^{ [OtestQuery queryTestBundlePath:otestQueryBundlePath]; };
  if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){15,0,0}]) {
    dispatch_async(dispatch_get_main_queue(), queryBlock);
  }
  else {
    queryBlock();
  }
}
