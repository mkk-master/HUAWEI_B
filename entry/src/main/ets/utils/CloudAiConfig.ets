/**
 * 云端 AI（DashScope OpenAI 兼容模式）配置。
 * apiKey 必须由运行时注入（设置页、Preferences、环境构建脚本等），禁止写入仓库。
 */
export class CloudAiConfig {
  /** 阿里云 DashScope API Key，形如 sk-xxx */
  static apiKey: string = '';
  static readonly COMPAT_BASE_URL: string = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
  static readonly CHAT_MODEL: string = 'qwen3.6-plus';
}
