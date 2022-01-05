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

#import "SimulatorTaskUtils.h"

#import "SimDevice.h"
#import "SimulatorInfo.h"
#import "TaskUtil.h"
#import "XCToolUtil.h"

NSTask *CreateTaskForSimulatorExecutable(NSString *sdkName,
                                         SimulatorInfo *simulatorInfo,
                                         NSString *launchPath,
                                         NSArray *arguments,
                                         NSDictionary *environment)
{
  NSTask *task = CreateTaskInSameProcessGroup();
  NSMutableArray *taskArgs = [NSMutableArray array];
  NSMutableDictionary *taskEnv = [NSMutableDictionary dictionary];

  if ([sdkName hasPrefix:@"iphonesimulator"] ||
      [sdkName hasPrefix:@"appletvsimulator"]) {
    SimDevice *simulatedDevice = [simulatorInfo simulatedDevice];
    [taskArgs addObject: @"spawn"];
    // Airbnb: force to run x86_64 xctest on M1 machine.
    // This breaks test bundles that are built natively for arm64, but we don't have any of them for now.
    [taskArgs addObject: @"--arch=x86_64"];
    if (ToolchainIsXcode10OrBetter() && [simulatedDevice state] != SimDeviceStateBooted) {
      // If simulator is not booted, pass --standalone option, which is required by Xcode 11.
      [taskArgs addObject: @"--standalone"];
    }
    [taskArgs addObject: [[simulatedDevice UDID] UUIDString]];
    [taskArgs addObject:launchPath];
    [taskArgs addObjectsFromArray:arguments];

    [environment enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *stop){
      // simctl has a bug where it hangs if an empty child environment variable is set.
      if ([(NSString *)val length] == 0) {
        return;
      }

      // simctl will look for all vars prefixed with SIMCTL_CHILD_ and add them
      // to the spawned process's environment (with the prefix removed).
      NSString *newKey = [@"SIMCTL_CHILD_" stringByAppendingString:key];
      taskEnv[newKey] = val;
    }];

    [task setLaunchPath:[XcodeDeveloperDirPath() stringByAppendingPathComponent:@"usr/bin/simctl"]];
  } else {
    [task setLaunchPath:launchPath];
    [taskArgs addObjectsFromArray:arguments];
    [taskEnv addEntriesFromDictionary:environment];
  }

  [task setArguments:taskArgs];
  [task setEnvironment:taskEnv];

  return task;
}
