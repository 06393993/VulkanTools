/*
 * Copyright (c) 2020 Valve Corporation
 * Copyright (c) 2020 LunarG, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Authors:
 * - Christophe Riccio <christophe@lunarg.com>
 */

#include "../layer_setting_meta.h"
#include "../util.h"

#include <gtest/gtest.h>

TEST(test_layer_setting, find) {
    LayerSettingMeta layer_setting_a;
    layer_setting_a.key = "A";

    LayerSettingMeta layer_setting_b;
    layer_setting_b.key = "B";

    std::vector<LayerSettingMeta> settings;
    settings.push_back(layer_setting_a);
    settings.push_back(layer_setting_b);

    EXPECT_STREQ("A", FindByKey(settings, "A")->key.c_str());
    EXPECT_EQ(nullptr, FindByKey(settings, "NULL"));
}
