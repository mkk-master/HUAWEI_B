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
    '请用简体中文输出，结构清晰，包含以下小节（若当月无支出或无预算请如实说明）：\n' +
    '一、消费结构解读\n' +
    '二、预算执行情况\n' +
    '三、若存在超支：结合分类与大额账单，简要分析可能原因（条目式）\n' +
    '四、可执行的节流与改进建议（具体、小步骤，避免空话）\n' +
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