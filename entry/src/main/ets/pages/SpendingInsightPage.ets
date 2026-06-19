// AI 月度消费洞察：报告 + 自然语言追问

import { BillViewModel } from '../viewmodel/BillViewModel';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import { CloudAiConfig } from '../utils/CloudAiConfig';
import { generateMonthlyInsightReport, continueMonthlyInsightChat } from '../utils/MonthlyInsightAiService';
import { DashScopeChatMessage } from '../utils/DashScopeOpenAiClient';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import dataPreferences from '@ohos.data.preferences';

interface InsightChatTurn {
  question: string;
  answer: string;
}

const PREFERENCES_NAME: string = 'count1_prefs';
const PREF_KEY_DASHSCOPE_API: string = 'dashscope_api_key';

@Entry
@Component
struct SpendingInsightPage {
  @State monthStr: string = '';
  @State dataPayload: string = '';
  @State reportText: string = '';
  @State chatTurns: InsightChatTurn[] = [];
  @State questionInput: string = '';
  @State loadingReport: boolean = false;
  @State loadingChat: boolean = false;
  @State hintText: string = '';

  private viewModel: BillViewModel = new BillViewModel();
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();
  private apiSession: DashScopeChatMessage[] = [];

  async aboutToAppear(): Promise<void> {
    await this.dbHelper.initDatabase(getContext(this));
    await this.viewModel.init();

    const params = router.getParams() as Record<string, Object>;
    let m = '';
    if (params !== null && params !== undefined && params['month'] !== undefined && params['month'] !== null) {
      m = String(params['month']);
    }
    if (m.length !== 7) {
      m = this.viewModel.currentMonth;
    }
    this.monthStr = m;

    await this.viewModel.changeMonth(this.monthStr, '', '');
    await this.viewModel.loadBudget();
    await this.loadCloudApiKeyFromPreferences();
    await this.refreshDataPayload();
    //await this.onGenerateReport();
  }

  async loadCloudApiKeyFromPreferences(): Promise<void> {
    try {
      const pref = await dataPreferences.getPreferences(getContext(this), PREFERENCES_NAME);
      const saved = await pref.get(PREF_KEY_DASHSCOPE_API, '') as string;
      const trimmed = saved.trim();
      if (trimmed.length > 0) {
        CloudAiConfig.apiKey = trimmed;
      }
      if (CloudAiConfig.apiKey.length === 0) {
        this.hintText = '请先在「记一笔」页填写 DashScope API Key，或在本页生成报告前完成配置。';
      } else {
        this.hintText = '';
      }
    } catch (e) {
      console.error('读取云端 AI Key 失败', e);
    }
  }

  async refreshDataPayload(): Promise<void> {
    this.dataPayload = await this.viewModel.buildMonthlyInsightDataText(this.monthStr);
  }

  async onGenerateReport(): Promise<void> {
    await this.loadCloudApiKeyFromPreferences();
    if (CloudAiConfig.apiKey.length === 0) {
      promptAction.showToast({ message: '请先配置 DashScope API Key（记一笔页面）', duration: 2500 });
      return;
    }

    this.loadingReport = true;
    try {
      await this.refreshDataPayload();
      const result = await generateMonthlyInsightReport(CloudAiConfig.apiKey, this.monthStr, this.dataPayload);
      this.reportText = result.report;
      this.apiSession = result.session;
      this.chatTurns = [];
      promptAction.showToast({ message: '分析报告已生成', duration: 2000 });
    } catch (e) {
      console.error('生成报告失败', e);
      promptAction.showToast({ message: '生成失败，请检查网络与 Key', duration: 2500 });
    } finally {
      this.loadingReport = false;
    }
  }

  async onSendQuestion(): Promise<void> {
    const q = this.questionInput.trim();
    if (q.length === 0) {
      promptAction.showToast({ message: '请输入问题', duration: 1500 });
      return;
    }
    if (this.apiSession.length === 0) {
      promptAction.showToast({ message: '请先生成分析报告', duration: 2000 });
      return;
    }
    await this.loadCloudApiKeyFromPreferences();
    if (CloudAiConfig.apiKey.length === 0) {
      promptAction.showToast({ message: 'API Key 未配置', duration: 2000 });
      return;
    }

    this.loadingChat = true;
    try {
      const result = await continueMonthlyInsightChat(CloudAiConfig.apiKey, this.apiSession, q);
      this.apiSession = result.session;
      const nextTurns: InsightChatTurn[] = [...this.chatTurns];
      nextTurns.push({ question: q, answer: result.reply });
      this.chatTurns = nextTurns;
      this.questionInput = '';
    } catch (e) {
      console.error('追问失败', e);
      promptAction.showToast({ message: '提问失败，请稍后重试', duration: 2500 });
    } finally {
      this.loadingChat = false;
    }
  }

  build() {
    Column() {
      Row() {
        Button('返回')
          .backgroundColor('#00000000')
          .fontColor('#4CAF50')
          .onClick(() => {
            router.back();
          })

        Text('AI 消费洞察')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(56)
      }
      .width('90%')
      .height(48)

      Scroll() {
        Column() {
          Text(`分析月份：${this.monthStr}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })


          if (this.hintText.length > 0) {
            Text(this.hintText)
              .fontSize(12)
              .fontColor('#FF9800')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })
          }

          Button(this.loadingReport ? '生成中…' : '生成消费分析报告')
            .width('100%')
            .height(44)
            .backgroundColor('#4CAF50')
            .enabled(!this.loadingReport && !this.loadingChat)
            .onClick(() => {
              void this.onGenerateReport();
            })

          Text('数据摘要（发给模型的依据）')
            .fontSize(13)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ top: 16, bottom: 6 })

          Text(this.dataPayload.length > 0 ? this.dataPayload : '暂无数据')
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)

          Text('分析报告')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ top: 20, bottom: 8 })

          Text(this.reportText.length > 0 ? this.reportText : '点击上方按钮生成报告（含消费结构、预算执行、超支原因与节流建议）')
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .lineHeight(22)
            .padding(12)
            .backgroundColor('#FAFAFA')
            .borderRadius(8)

          Text('自然语言追问')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ top: 24, bottom: 8 })

          Text('基于上方数据与报告继续提问，例如：「餐饮能不能再省一点」「大额支出主要在哪」')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          ForEach(this.chatTurns, (turn: InsightChatTurn, index: number) => {
            Column() {
              Text(`Q${index + 1}：${turn.question}`)
                .fontSize(13)
                .fontColor('#1976D2')
                .width('100%')
                .margin({ bottom: 6 })

              Text(turn.answer)
                .fontSize(14)
                .fontColor('#333333')
                .width('100%')
                .lineHeight(22)
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ bottom: 10 })
          }, (turn: InsightChatTurn, index: number) => `${index}-${turn.question}`)

          Row() {
            TextInput({
              placeholder: '输入你的问题…',
              text: this.questionInput
            })
              .layoutWeight(1)
              .height(44)
              .fontSize(14)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((v: string) => {
                this.questionInput = v;
              })

            Button(this.loadingChat ? '…' : '发送')
              .width(72)
              .height(44)
              .margin({ left: 8 })
              .backgroundColor('#2196F3')
              .enabled(!this.loadingChat && !this.loadingReport)
              .onClick(() => {
                void this.onSendQuestion();
              })
          }
          .width('100%')
          .margin({ top: 8, bottom: 32 })
        }
        .width('90%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
