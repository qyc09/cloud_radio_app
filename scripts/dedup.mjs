#!/usr/bin/env node
/**
 * 电台方言数据自动校验脚本（零依赖，Node 18+ 直接运行）
 * 用法：node scripts/dedup.mjs [数据文件路径...]
 * 不传参数时自动校验仓库根目录下所有 电台方言初判*.json
 *
 * 校验内容：
 *   1. JSON 可解析，且包含 stations 数组
 *   2. 每个电台必填字段齐全（name / languages / dialectShare / confidence）
 *   3. languages、dialectShare、confidence 均为合法枚举值（schema 校验）
 *   4. contentId（若存在）全库唯一 —— 去重
 *   5. name 全库唯一 —— 去重
 */
import fs from 'node:fs';
import path from 'node:path';

const LANGUAGES = new Set(['yue', 'hakka', 'teochew', 'mandarin']);
const SHARE = new Set(['primary', 'mixed', 'low']);
const CONF = new Set(['high', 'medium', 'low']);

const args = process.argv.slice(2);
const files = args.length
  ? args
  : collectJsonFiles(process.cwd()).filter((f) => /电台方言/.test(path.basename(f)));

if (files.length === 0) {
  console.error('✗ 未找到任何电台方言数据 JSON 文件');
  process.exit(1);
}

const seenContentId = new Map(); // contentId -> 位置
const seenName = new Map(); // name -> 文件
let errors = 0;

function fail(msg) {
  errors++;
  console.error('  ✗ ' + msg);
}

function collectJsonFiles(dir) {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name.startsWith('.') || e.name === 'node_modules') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...collectJsonFiles(p));
    else if (e.name.endsWith('.json')) out.push(p);
  }
  return out;
}

for (const file of files) {
  const rel = path.relative(process.cwd(), file);
  console.log('▶ 校验 ' + rel);
  let data;
  try {
    data = JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (e) {
    fail('JSON 解析失败：' + e.message);
    continue;
  }
  if (!Array.isArray(data.stations)) {
    fail('缺少 stations 数组（顶层数据结构必须是对象 + stations 数组）');
    continue;
  }
  data.stations.forEach((st, i) => {
    const tag = `stations[${i}] ${st.name || '(无名)'}`;
    if (!st.name || typeof st.name !== 'string') fail(`${tag}: name 必填且为字符串`);
    if (!Array.isArray(st.languages) || st.languages.length === 0)
      fail(`${tag}: languages 必须是非空数组`);
    else
      for (const l of st.languages)
        if (!LANGUAGES.has(l)) fail(`${tag}: 非法语言枚举 "${l}"（允许: yue/hakka/teochew/mandarin）`);
    if (!SHARE.has(st.dialectShare)) fail(`${tag}: dialectShare 非法 "${st.dialectShare}"（允许: primary/mixed/low）`);
    if (!CONF.has(st.confidence)) fail(`${tag}: confidence 非法 "${st.confidence}"（允许: high/medium/low）`);
    if (st.contentId != null) {
      const key = String(st.contentId);
      if (seenContentId.has(key))
        fail(`contentId 重复：${key} 已出现在 ${seenContentId.get(key)}`);
      else seenContentId.set(key, rel + ' ' + tag);
    }
    if (seenName.has(st.name))
      fail(`电台名重复：${st.name} 已出现在 ${seenName.get(st.name)}`);
    else seenName.set(st.name, rel);
  });
}

if (errors > 0) {
  console.error(`\n✗ 校验失败，共 ${errors} 处错误。请修正后重新提交 PR。`);
  process.exit(1);
}
console.log(`\n✓ 全部通过：${files.length} 个文件，${seenName.size} 个电台，无重复、无非法字段。`);
