// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using ObjectDeliverer.Protocol.IP;
using ObjectDeliverer.Utils;

namespace ObjectDeliverer.Protocol
{
    class ProtocolUdpSocketSender : ProtocolIPSocket
    {
        string DestinationIpAddress { get; set; } = "127.0.0.1";

        int DestinationPort { get; set; } = 0;

        override async ValueTask StartAsync()
        {
            this.IpClient = new UDPProtocolHelper(this.SendBufferSize);

            await this.IpClient.ConnectAsync(this.DestinationIpAddress, this.DestinationPort);

            this.DispatchConnected(this);
        }
    }
}