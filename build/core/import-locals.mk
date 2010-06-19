# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Handle local variable expor/import during the build
#

$(call assert-defined,LOCAL_MODULE)

# For LOCAL_CFLAGS, LOCAL_CPPFLAGS and LOCAL_C_INCLUDES, we need
# to use the exported definitions of the closure of all modules
# we depend on.
#
# I.e. If module 'foo' depends on 'bar' which depends on 'zoo',
# then 'foo' will get the CFLAGS/CPPFLAGS/C_INCLUDES of both 'bar'
# and 'zoo'
#

#
# The imported compiler flags are prepended to their LOCAL_XXXX value
# (this allows the module to override them).
#
all_depends := $(call module-get-all-dependencies,$(LOCAL_MODULE))
all_depends := $(filter-out $(LOCAL_MODULE),$(all_depends))

imported_CFLAGS     := $(call module-get-listed-export,$(all_depends),CFLAGS)
imported_CPPFLAGS   := $(call module-get-listed-export,$(all_depends),CPPFLAGS)
imported_C_INCLUDES := $(call module-get-listed-export,$(all_depends),C_INCLUDES)

ifdef NDK_DEBUG_IMPORTS
    $(info Imports for module $(LOCAL_MODULE):)
    $(info   CFLAGS='$(imported_CFLAGS)')
    $(info   CPPFLAGS='$(imported_CPPFLAGS)')
    $(info   C_INCLUDES='$(imported_C_INCLUDES)')
    $(info All depends='$(all_depends)')
endif

LOCAL_CFLAGS     := $(strip $(imported_CFLAGS) $(LOCAL_CFLAGS))
LOCAL_CPPFLAGS   := $(strip $(imported_CPPFLAGS) $(LOCAL_CPPFLAGS))
LOCAL_C_INCLUDES := $(strip $(imported_C_INCLUDES) $(LOCAL_C_INCLUDES))

# For LOCAL_LDLIBS, things are a bit different!
#
# You want the imported flags to appear _after_ the LOCAL_LDLIBS due to the way Unix
# linkers work.
#
imported_LDLIBS := $(call module-get-listed-export,$(all_depends),LDLIBS)

LOCAL_LDLIBS := $(strip $(LOCAL_LDLIBS) $(imported_LDLIBS))

# We're done here