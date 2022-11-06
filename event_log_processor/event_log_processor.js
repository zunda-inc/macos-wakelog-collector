// Copyright 2022 ZUNDA Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import { S3Client, GetObjectCommand, PutObjectCommand, CopyObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import * as readline from 'node:readline';
import dayjs from 'dayjs';
import timezone from 'dayjs/plugin/timezone.js';
import { stringify } from 'csv-stringify/sync';
import { parse } from 'csv-parse/sync';

export const event_log_processor = async (bucket, key, aggregated, archived) => {
  dayjs.extend(timezone);
  dayjs.tz.setDefault(process.env.tz || "Asia/Tokyo");

  const s3Client = new S3Client({ region: process.env.aws_region });
  const getRawLogCommand = new GetObjectCommand({
    Bucket: bucket,
    Key: key,    
  });
  const getRawLogCommandResult = await s3Client.send(getRawLogCommand);
  const deviceSerial = getRawLogCommandResult.Metadata['device-serial'];
  const user = getRawLogCommandResult.Metadata['user'];
  const logType = getRawLogCommandResult.Metadata['log-type'];

  const reader = readline.createInterface(getRawLogCommandResult.Body);
  const newLogs = {};

  for await (const line of reader) {
    const eventFlag = line.match(/Display is turned (\w+)/) || line.match(/(reboot|shutdown|start)/);
    const timestamp = line.match(/\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2} .\d{4}/);
    if (eventFlag && timestamp) {
      const day = dayjs(timestamp);
      const yearMonth = day.format('YYYYMM');
      newLogs[yearMonth] ||= [];
      newLogs[yearMonth].push({
        timestamp: dayjs(timestamp).format('YYYY-MM-DD HH:mm:ss'),
        deviceSerial: deviceSerial,
        user: user,
        event: [logType, eventFlag[1]].join("-")
      });
    }
  }

  for(const yearMonth in newLogs) {
    const fileKey = yearMonth + '/' + deviceSerial + '.csv';
    const getAggregatedLogCommand = new GetObjectCommand({
      Bucket: aggregated,
      Key: fileKey,
    });
    let aggregatedLogs;
    try {
      const getAggregatedLogResult = await s3Client.send(getAggregatedLogCommand);
      const chunks = [];
      for await (const line of getAggregatedLogResult.Body) {
        chunks.push(line);
      }
      const records = parse(Buffer.concat(chunks), {
        columns: true,
        skip_empty_lines: true,
      });
      console.log('loaded', records);

      for (let i = 0, len = newLogs[yearMonth].length; i < len; i++) {
        const newItem = newLogs[yearMonth][i];
        for (let j = records.length - 1; j >= 0; j--) {
          const cursor = records[j];

          // 同じタイムスタンプの場合:
          // - 同一のイベントであればそのまま離脱
          // - 異なるイベントであればレコードを挿入してループ離脱
          if (newItem.timestamp == cursor.timestamp) {
            if (newItem.event != cursor.event) {
              records.splice(j + 1, 0, newItem);
            }
            break;
          }

          // タイムスタンプの比較
          if (dayjs(newItem.timestamp).isAfter(cursor.timestamp)) {
            records.splice(j + 1, 0, newItem);
            break;
          }

          // 先頭までカーソルが移動した場合は最先頭に要素を置く
          if (j == 0) {
            records.splice(j, 0, newItem);
          }
        }
      }
      aggregatedLogs = records;
    } catch(ex) {
      if (ex.Code == 'NoSuchKey') {
        console.log('NoSuchKey')
        aggregatedLogs = newLogs[yearMonth];
      } else {
        throw ex;
      }
    }

    console.log(aggregatedLogs);
    const csvString = stringify(aggregatedLogs, {
      header: true,
      quoted_string: true,
    });
    
    const putAggregatedLogCommand = new PutObjectCommand({
      Bucket: aggregated,
      Key: fileKey,
      Body: csvString,
    })

    await s3Client.send(putAggregatedLogCommand);
  }
  const copyRawLogCommand = new CopyObjectCommand({
    Bucket: archived,
    Key: key,
    CopySource: bucket + '/' + key
  });
  const copyRawLogCommandResult = await s3Client.send(copyRawLogCommand);
  if (copyRawLogCommandResult['$metadata'].httpStatusCode == 200) {
    const deleteRawLogCommand = new DeleteObjectCommand({
      Bucket: bucket,
      Key: key
    });
    await s3Client.send(deleteRawLogCommand);
  }

  return 1;
};