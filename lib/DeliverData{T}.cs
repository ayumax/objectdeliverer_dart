// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

using System;
using System.Collections.Generic;
using System.Text;
using ObjectDeliverer.Protocol;

namespace ObjectDeliverer
{
    class DeliverData<T> : DeliverData
    {
        T Message { get; set; } = default(T) !;
    }
}