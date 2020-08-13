// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

 import 'objectdeliverer_protocol.dart';
import 'protocol_ip_Socket.dart';

class ProtocolTcpIpClient extends ProtocolIPSocket
    {
        Future<void> _connectTask;

        String ipAddress = '127.0.0.1';

        int port;

        bool autoConnectAfterDisconnect = false;

        @override
        Future<void> startAsync() async
        {
            await super.startAsync();

            startConnect();
        }

        @override 
        Future<void> closeAsync() async
        {
            await super.closeAsync();

            await _connectTask;
        }

        @override 
        void dispatchDisconnected(ObjectDelivererProtocol delivererProtocol)
        {
            super.dispatchDisconnected(delivererProtocol);

            if (autoConnectAfterDisconnect)
            {
                _startConnect();
            }
        }

        @override
        Future<void> receivedDatas() async
        {
            if (this.IpClient == null)
            {
                this.DispatchDisconnected(this);
                return;
            }

            this.Canceler = new CancellationTokenSource();

            while (this.Canceler!.IsCancellationRequested == false)
            {
                if (this.IpClient?.Available > 0)
                {
                    int wantSize = this.PacketRule.WantSize;

                    if (wantSize > 0)
                    {
                        if (this.IpClient.Available < wantSize)continue;
                    }

                    var receiveSize = wantSize == 0 ? this.IpClient.Available : wantSize;

                    this.ReceiveBuffer.SetBufferSize(receiveSize);

                    if (this.IpClient == null)
                    {
                        this.NotifyDisconnect();
                        return;
                    }

                    if (await this.IpClient.ReadAsync(this.ReceiveBuffer.MemoryBuffer) <= 0)
                    {
                        this.NotifyDisconnect();
                        return;
                    }

                    foreach (var receivedMemory in this.PacketRule.MakeReceivedPacket(this.ReceiveBuffer.MemoryBuffer))
                    {
                        this.DispatchReceiveData(new DeliverData()
                        {
                            Sender = this,
                                Buffer = receivedMemory,
                        });
                    }
                }
                else
                {
                    if (this.IpClient?.IsEnable == false)
                    {
                        _notifyDisconnect();
                        return;
                    }

                    await Task.Delay(1);
                }
            }
        }

        void _notifyDisconnect()
        {
            if (!isSelfClose)
            {
                this.IpClient?.Close();
                dispatchDisconnected(this);
            }
        }

        void _startConnect()
        {
            Future<void> _connectAsync() async
            {
                await closeAsync();
                isSelfClose = false;

                this.IpClient = new TCPProtocolHelper(this.ReceiveBufferSize, this.SendBufferSize);

                while (isSelfClose == false)
                {
                    try
                    {
                        await this.IpClient.ConnectAsync(this.IpAddress, this.Port);

                        dispatchConnected(this);

                        startPollingForReceive(this.IpClient);

                        break;
                    }
                    catch (SocketException)
                    {
                        // Wait a minute and then try to reconnect.
                        await Task.Delay(1000);
                    }
                }
            }

            _connectTask = _connectAsync();
        }
    }