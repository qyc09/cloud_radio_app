#!/usr/bin/env node
/**
 * 方言跟读评分引擎（零依赖，node 跟读评分引擎示例.mjs 直接运行）
 *
 * 定位：ASR 转写之后、展示之前的纯算法层。
 * 接入方式：你的后端收到 ASR 文本后调用 scoreReading(reference, asrText, durations)
 *
 * 评分体系：
 *   准确度 accuracy —— 参考字中被正确读出的比例（逐字对齐）
 *   完整度 completeness —— 参考长度与识别长度的覆盖率
 *   流利度 fluency —— 语速比（1 = 恰好，允许 0.6~1.6 区间）
 *   总分 = 0.5*accuracy + 0.3*completeness + 0.2*fluency，映射为 1~5 星
 */

// ---------- 1. 编辑距离逐字对齐 ----------
// 返回：每个参考字的判定 ['hit' 读对 | 'wrong' 读错 | 'missing' 漏读]，外加多余字数
function align(reference, asrText) {
  const ref = [...reference.replace(/[，。？！、,\.\?! ]/g, '')];
  const hyp = [...asrText.replace(/[，。？！、,\.\?! ]/g, '')];
  const m = ref.length, n = hyp.length;

  // DP 编辑距离（代价：替换1/增删1），回溯取对齐路径
  const dp = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = Math.min(
        dp[i - 1][j] + 1,                            // 漏读
        dp[i][j - 1] + 1,                            // 多读
        dp[i - 1][j - 1] + (ref[i - 1] === hyp[j - 1] ? 0 : 1) // 对/错
      );

  // 回溯
  const verdict = new Array(m).fill('missing');
  let extra = 0, i = m, j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && dp[i][j] === dp[i - 1][j - 1] + (ref[i - 1] === hyp[j - 1] ? 0 : 1)) {
      verdict[i - 1] = ref[i - 1] === hyp[j - 1] ? 'hit' : 'wrong';
      i--; j--;
    } else if (i > 0 && dp[i][j] === dp[i - 1][j] + 1) {
      i--;                                        // 参考字漏读，保持 missing
    } else {
      extra++; j--;                               // 多读的字
    }
  }
  return { ref, hyp, verdict, extra };
}

// ---------- 2. 三项分数 ----------
function scoreReading(reference, asrText, { refDurationSec = null, userDurationSec = null } = {}) {
  const { ref, verdict, extra } = align(reference, asrText);
  const total = ref.length || 1;
  const hits = verdict.filter((v) => v === 'hit').length;
  const wrongs = verdict.filter((v) => v === 'wrong').length;

  const accuracy = hits / total;
  const completeness = (hits + wrongs) / total; // 至少读出来了

  let fluency = 1;
  if (refDurationSec && userDurationSec) {
    const ratio = userDurationSec / refDurationSec;
    // 语速比在 [0.6, 1.6] 内线性映射到 [0, 1]，1 为满分
    fluency = ratio < 1
      ? Math.max(0, (ratio - 0.4) / 0.6)
      : Math.max(0, (1.6 - ratio) / 0.6);
    fluency = Math.min(1, fluency);
  }

  const final = 0.5 * accuracy + 0.3 * completeness + 0.2 * fluency;
  const stars = final >= 0.9 ? 5 : final >= 0.75 ? 4 : final >= 0.6 ? 3 : final >= 0.4 ? 2 : 1;

  // 逐字反馈（前端高亮用）
  const perChar = ref.map((ch, idx) => ({ char: ch, result: verdict[idx] }));

  return {
    scores: {
      accuracy: round(accuracy),      // 0~1
      completeness: round(completeness),
      fluency: round(fluency),
      final: round(final),
      stars,
    },
    feedback: {
      perChar,                        // 高亮：绿=hit 红=wrong 灰=missing
      extraCount: extra,              // 多读了几个字
      missing: ref.filter((_, idx) => verdict[idx] === 'missing'),
      wrong: ref.filter((_, idx) => verdict[idx] === 'wrong'),
    },
  };
}

const round = (x) => Math.round(x * 1000) / 1000;

// ---------- 3. 演示 ----------
const cases = [
  { ref: '食粥未', hyp: '食粥未' },          // 满分
  { ref: '食粥未', hyp: '食粥咪' },          // 错一个字
  { ref: '食粥未', hyp: '食粥' },            // 漏读
  { ref: '你好，食未', hyp: '你好食未了', refDurationSec: 2, userDurationSec: 2.2 },
];
for (const c of cases) {
  const r = scoreReading(c.ref, c.hyp, { refDurationSec: 2, userDurationSec: 2.2 });
  console.log(`参考「${c.ref}」 识别「${c.hyp}」 →`, r.scores, '| 逐字:', r.feedback.perChar.map(p => `${p.char}:${p.result}`).join(' '));
}

export { align, scoreReading };
