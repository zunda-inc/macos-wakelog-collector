// Copyright 2022 ZUNDA Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import { event_log_processor } from "./event_log_processor.js";

export const dequeue = async (event) => {
    for (const messageRawData of event['Records']) {
        const message = JSON.parse(messageRawData['body'])
        for (const messageEvent of message.Records) {
            if (messageEvent.eventName == "ObjectCreated:Put") {
                await event_log_processor(
                    messageEvent.s3.bucket.name,
                    messageEvent.s3.object.key,
                    process.env.aws_s3_aggregated_log_bucket,
                    process.env.aws_s3_log_archive_bucket
                )
            }
        }
    }
    
    return {};
};
