// 月度消费洞察：报告生成与自然语言追问（DashScope 多轮对话）

import { dashScopeChatCompletionMessages, DashScopeChatMessage } from './DashScopeOpenAiClient';

// 👇 只加这 1 个接口，修复所有错误
interface InsightResponse {
  report: string;
  session: DashScopeChatMessage[];
}

interface ChatReply {
  reply: string;
  session: DashScopeChatMessage[];
}

const SYSTEM_PROMPT: string =
  '你是个人财务管理助手。用户将提供某月的记账原始汇总数据（预算、总支出、分类占比、大额账单等）。\n' +
    '你必须仅基于这些数据进行分析，不要编造不存在的记录。\n' +
    '请用简体中文输出。使用 Markdown 格式组织内容，包含以下小节（若当月无支出或无预算请如实说明）：\n\n' +
    '## 消费结构解读\n\n' +
    '(分析各分类占比，指出主要支出类别)\n\n' +
    '## 预算执行情况\n\n' +
    '(总支出 vs 预算，进度百分比，是否超支)\n\n' +
    '## 超支原因分析\n\n' +
    '(若存在超支：结合分类与大额账单，以条目式分析可能原因；若未超支则说明收支健康)\n\n' +
    '## 节流与改进建议\n\n' +
    '(具体的、可执行的小步骤，每条以 - 开头，避免空话)\n\n' +
    '格式要求：\n' +
    '- 小节标题用 ## 开头\n' +
    '- 列表项用 - 开头\n' +
    '- 重点数字用 **粗体** 包裹\n' +
    '语气务实、友好。';

function buildInitialInsightUserMessage(month: string, dataText: string): string {
  return `请根据下列「${month}」记账汇总生成完整分析报告。\n\n---数据---\n${dataText}\n\n---\n请严格按要求输出各小节。`;
}

/** 首次生成报告：返回助手正文 + 供后续追问使用的完整 messages（含 system）。 */
export async function generateMonthlyInsightReport(apiKey: string, month: string,
  dataText: string): Promise<InsightResponse> {

  const userMsg = buildInitialInsightUserMessage(month, dataText);
  const messages: DashScopeChatMessage[] = [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: userMsg }
  ];

  const report = await dashScopeChatCompletionMessages(apiKey, messages);
  messages.push({ role: 'assistant', content: report });

  return { report: report, session: messages };
}

/** 基于已有会话继续追问，返回助手回复与更新后的 messages。 */
export async function continueMonthlyInsightChat(apiKey: string,
  session: DashScopeChatMessage[], userQuestion: string): Promise<ChatReply> {

  const trimmed = userQuestion.trim();
  if (trimmed.length === 0) {
    throw new Error('提问内容为空');
  }

  const next: DashScopeChatMessage[] = [...session, { role: 'user', content: trimmed }];
  const reply = await dashScopeChatCompletionMessages(apiKey, next);
  next.push({ role: 'assistant', content: reply });

  return { reply: reply, session: next };
}