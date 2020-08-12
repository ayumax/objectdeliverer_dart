library objectdeliverer_dart;

class ObjectDelivererManager<T> : IAsyncDisposable
    {
        private ObjectDelivererProtocol? currentProtocol;
        private DeliveryBoxBase<T>? deliveryBox;
        private bool disposedValue = false;

        private Subject<ConnectedData> connected = new Subject<ConnectedData>();
        private Subject<ConnectedData> disconnected = new Subject<ConnectedData>();
        private Subject<DeliverData<T>> receiveData = new Subject<DeliverData<T>>();

        ObjectDelivererManager()
        {
        }

        IObservable<ConnectedData> Connected => this.connected;

        IObservable<ConnectedData> Disconnected => this.disconnected;

        IObservable<DeliverData<T>> ReceiveData => this.receiveData;

        bool IsConnected => this.ConnectedList.Count > 0;

        List<ObjectDelivererProtocol> ConnectedList { get; private set; } = new List<ObjectDelivererProtocol>();

        static ObjectDelivererManager<T> CreateObjectDelivererManager() => new ObjectDelivererManager<T>();

        ValueTask StartAsync(ObjectDelivererProtocol protocol, PacketRuleBase packetRule, DeliveryBoxBase<T>? deliveryBox = null)
        {
            if (protocol == null || packetRule == null) return default(ValueTask);

            this.currentProtocol = protocol;
            this.currentProtocol.SetPacketRule(packetRule);

            this.deliveryBox = deliveryBox;

            this.currentProtocol.Connected.Subscribe(x =>
            {
                this.ConnectedList.Add(x.Target);
                this.connected.OnNext(x);
            });

            this.currentProtocol.Disconnected.Subscribe(x =>
            {
                this.ConnectedList.Remove(x.Target);
                this.disconnected.OnNext(x);
            });

            this.currentProtocol.ReceiveData.Subscribe(x =>
            {
                var data = new DeliverData<T>()
                {
                    Sender = x.Sender,
                    Buffer = x.Buffer,
                };

                if (deliveryBox != null)
                {
                    data.Message = deliveryBox.BufferToMessage(x.Buffer);
                }

                this.receiveData.OnNext(data);
            });

            this.ConnectedList.Clear();

            return this.currentProtocol.StartAsync();
        }

        ValueTask SendAsync(ReadOnlyMemory<byte> dataBuffer)
        {
            if (this.currentProtocol == null || this.disposedValue) return default(ValueTask);

            return this.currentProtocol.SendAsync(dataBuffer);
        }

        ValueTask SendToAsync(ReadOnlyMemory<byte> dataBuffer, ObjectDelivererProtocol? target)
        {
            if (this.currentProtocol == null || this.disposedValue) return default(ValueTask);

            if (target != null)
            {
                return target.SendAsync(dataBuffer);
            }

            return default(ValueTask);
        }

        ValueTask SendMessageAsync(T message)
        {
            if (this.deliveryBox == null) return default(ValueTask);

            return this.SendAsync(this.deliveryBox.MakeSendBuffer(message));
        }

        ValueTask SendToMessageAsync(T message, ObjectDelivererProtocol target)
        {
            if (this.deliveryBox == null) return default(ValueTask);

            return this.SendToAsync(this.deliveryBox.MakeSendBuffer(message), target);
        }

        async ValueTask DisposeAsync()
        {
            if (!this.disposedValue)
            {
                this.disposedValue = true;

                if (this.currentProtocol == null) return;

                await this.currentProtocol.CloseAsync();

                this.currentProtocol.Dispose();

                this.currentProtocol = null;
            }
        }
    }

    class ObjectDelivererManager : ObjectDelivererManager<ReadOnlyMemory<byte>>