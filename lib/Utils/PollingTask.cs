// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

using System;
using System.Threading;
using System.Threading.Tasks;

namespace ObjectDeliverer.Utils
{
    class PollingTask : IAsyncDisposable
    {
        private ValueTask pollingTask = default(ValueTask);

        private CancellationTokenSource? canceler;

        PollingTask(Func<ValueTask<bool>> action)
        {
            this.canceler = new CancellationTokenSource();

            this.pollingTask = this.RunAsync(action);
        }

        ValueTask DisposeAsync()
        {
            if (this.pollingTask == null)return default(ValueTask);

            this.canceler?.Cancel();
            return this.pollingTask;
        }

        private async ValueTask RunAsync(Func<ValueTask<bool>> action)
        {
            while (this.canceler?.IsCancellationRequested == false)
            {
                if (await action.Invoke() == false)
                {
                    break;
                }

                await Task.Delay(1);
            }
        }
    }
}