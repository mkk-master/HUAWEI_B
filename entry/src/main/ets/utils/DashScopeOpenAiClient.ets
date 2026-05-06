// DashScope OpenAI 兼容 HTTP 客户端（/v1/chat/completions）

import { http } from '@kit.NetworkKit';
import { CloudAiConfig } from './CloudAiConfig';

export interface DashScopeChatMessage {
  role: string;
  content: string;
}

interface ChatCompletionRequestBody {
  model: string;
  messages: DashScopeChatMessage[];
}

interface ChatCompletionMessage {
  role?: string;
  content?: string;
}

interface ChatCompletionChoice {
  message?: ChatCompletionMessage;
}

interface ChatCompletionResponse {
  choices?: ChatCompletionChoice[];
  error?: Record<string, string>;
}

/**
 * 调用 DashScope 兼容模式的 chat.completions（多轮 messages）。
 */
export async function dashScopeChatCompletionMessages(apiKey: string,
  messages: DashScopeChatMessage[]): Promise<string> {
  const trimmed = apiKey.trim();
  if (trimmed.length === 0) {
    throw new Error('DashScope apiKey 为空');
  }
  if (messages.length === 0) {
    throw new Error('messages 为空');
  }

  const url = `${CloudAiConfig.COMPAT_BASE_URL}/chat/completions`;
  const body: ChatCompletionRequestBody = {
    model: CloudAiConfig.CHAT_MODEL,
    messages: messages
  };

  const httpRequest = http.createHttp();
  try {
    const resp = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${trimmed}`
      },
      extraData: JSON.stringify(body),
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 60000,
      readTimeout: 120000
    });

    const raw = typeof resp.result === 'string' ? resp.result : String(resp.result);
    if (resp.responseCode !== 200) {
      throw new Error(`DashScope HTTP ${resp.responseCode}: ${raw}`);
    }

    const parsed = JSON.parse(raw) as ChatCompletionResponse;
    if (parsed.error !== undefined) {
      const errMsg = JSON.stringify(parsed.error);
      throw new Error(`DashScope API 错误: ${errMsg}`);
    }

    const content = parsed.choices?.[0]?.message?.content;
    if (content === undefined || content.length === 0) {
      throw new Error('DashScope 响应无 choices[0].message.content');
    }
    return content.trim();
  } finally {
    httpRequest.destroy();
  }
}

/**
 * 单条 user 消息的便捷封装。
 */
export async function dashScopeChatCompletion(apiKey: string, userContent: string): Promise<string> {
  return dashScopeChatCompletionMessages(apiKey, [{ role: 'user', content: userContent }]);
}
