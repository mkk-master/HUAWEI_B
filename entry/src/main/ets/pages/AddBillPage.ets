// 文件路径: entry/src/main/ets/pages/AddBillPage.ets
import { BillViewModel } from '../viewmodel/BillViewModel';
import { CategoryType } from '../model/BillModel';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { LocalModelClassifier } from '../utils/LocalModelClassifier';
import { CloudAiConfig } from '../utils/CloudAiConfig';
import { predictBillCategoryCloud } from '../utils/CloudBillCategoryHelper';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import dataPreferences from '@ohos.data.preferences';
import { FastTextInference } from '../utils/FastTextInference';
const PREFERENCES_NAME: string = 'count1_prefs';
const PREF_KEY_DASHSCOPE_API: string = 'dashscope_api_key';

interface DatePickerResult {
  year: number;
  month: number;
  day: number;
}

@Entry
@Component
struct AddBillPage {
  @State amountInput: string = '';
  @State selectedCategory: CategoryType = CategoryType.FOOD;
  @State date: string = this.formatDate(new Date());
  @State remarkInput: string = '';
  @State remarkInitialized: boolean = false;
  @State amountError: string = '';
  @State isEdit: boolean = false;
  @State editBillId: number = -1;
  @State pageTitle: string = '记一笔';
  @State suggestedCategory: string = '';
  @State isPredicting: boolean = false;
  @State cloudApiKeyInput: string = 'sk-c32c4224bd084aa0baa79a0083200fcd';

  private viewModel: BillViewModel = new BillViewModel();
  private categoryArray: CategoryType[] = Object.values(CategoryType);
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();
  private classifier = LocalModelClassifier.getInstance();
  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private parseDate(dateStr: string): Date {
    if (!dateStr || dateStr.trim().length === 0) {
      return new Date();
    }

    const parts = dateStr.split('-');
    if (parts.length !== 3) {
      return new Date();
    }

    const year = Number(parts[0]);
    const month = Number(parts[1]);
    const day = Number(parts[2]);

    if (isNaN(year) || isNaN(month) || isNaN(day)) {
      return new Date();
    }

    return new Date(year, month - 1, day);
  }

  async aboutToAppear(): Promise<void> {
    await this.dbHelper.initDatabase(getContext(this));
    await this.viewModel.init();
    await this.loadCloudApiKeyFromPreferences();
    // 重置 TextInput 初始化标记（每次进入页面都重置）
    this.remarkInitialized = false;
    const fastText: FastTextInference = new FastTextInference();
    // 预加载词向量表
    try {
      await fastText.loadWordVectors(getContext(this));
    } catch (err) {
      console.error('词向量预加载失败:', JSON.stringify(err));
    }
    const params = router.getParams() as Record<string, Object>;

    if (params && params['billId'] !== undefined && params['billId'] !== null) {
      this.isEdit = true;
      this.pageTitle = '编辑账单';

      this.editBillId = Number(params['billId']);
      this.amountInput = String(params['amount'] || '');
      this.selectedCategory = params['category'] as CategoryType;

      const oldDate = String(params['date'] || '');
      if (oldDate.length > 0) {
        this.date = oldDate;
      } else {
        this.date = this.formatDate(new Date());
      }

      this.remarkInput = String(params['remark'] || '');

      console.info(`Edit bill page opened, billId=${this.editBillId}, date=${this.date}`);
    } else {
      this.isEdit = false;
      this.editBillId = -1;
      this.pageTitle = '记一笔';
      this.date = this.formatDate(new Date());
      this.remarkInput = '';
    }
  }

  async loadCloudApiKeyFromPreferences(): Promise<void> {
    try {
      const pref = await dataPreferences.getPreferences(getContext(this), PREFERENCES_NAME);
      const saved = await pref.get(PREF_KEY_DASHSCOPE_API, '') as string;
      const trimmed = saved.trim();
      if (trimmed.length > 0) {
        CloudAiConfig.apiKey = trimmed;
      }
      this.cloudApiKeyInput = CloudAiConfig.apiKey;
    } catch (e) {
      console.error('读取云端 AI Key 失败', e);
    }
  }

  async persistCloudApiKey(value: string): Promise<void> {
    try {
      const pref = await dataPreferences.getPreferences(getContext(this), PREFERENCES_NAME);
      await pref.put(PREF_KEY_DASHSCOPE_API, value);
      await pref.flush();
      CloudAiConfig.apiKey = value.trim();
    } catch (e) {
      console.error('保存云端 AI Key 失败', e);
    }
  }

  // 触发智能预测（同步入口，不会阻塞 onChange 状态更新）
  private triggerPredict(): void {
    const hasRemark: boolean = this.remarkInput.length >= 1;
    const hasAmount: boolean = parseFloat(this.amountInput) > 0;
    if (hasRemark && hasAmount) {
      this.smartPredict();
    }
  }

  // 备注变化：只触发预测，不修改 remark（已在 onChange 中赋值）
  onRemarkChange(_value: string): void {
    this.triggerPredict();
  }

  // 金额变化：只触发预测
  onAmountChange(_value: string): void {
    if (this.remarkInput.length > 2) {
      this.triggerPredict();
    }
  }

  async smartPredict() {
    if (this.isPredicting) return;

    this.isPredicting = true;
    const amountCent = Math.round(parseFloat(this.amountInput) * 100);

    try {
      let category: CategoryType | null = null;
      if (category === null) {
        category = await this.classifier.predictCategory(amountCent, this.remarkInput, getContext(this));
      }
      this.suggestedCategory = category;

      promptAction.showToast({
        message: `智能建议分类：${category}`,
        duration: 2000
      });
    } catch (err) {
      console.error('智能预测失败', err);
    } finally {
      this.isPredicting = false;
    }
  }

  build() {
    Scroll() {
      Column() {
        // 标题栏
        Row() {
          Button('取消')
            .backgroundColor('#00000000')
            .fontColor('#666666')
            .onClick(() => {
              router.back();
            })

          Text(this.pageTitle)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Button('保存')
            .backgroundColor('#4CAF50')
            .borderRadius(8)
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.saveBill();
            })
        }
        .width('90%')
        .height(48)
        .margin({ top: 8 })

        // 金额输入
        Column() {
          Text('金额')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)

          TextInput({
            placeholder: '0.00',
            text: this.amountInput
          })
            //.type(InputType.Number)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .height(60)
            .border({
              width: {
                bottom: this.amountError ? 2 : 1
              },
              color: this.amountError ? '#F44336' : '#E0E0E0'
            })
            .onChange((value: string) => {
              this.amountInput = value;
              this.onAmountChange(value);
              if (!value || value.trim().length === 0) {
                this.amountError = '';
                return;
              }

              if (!CurrencyUtil.isValidAmount(value)) {
                this.amountError = '请输入有效金额（最多两位小数）';
              } else {
                this.amountError = '';
              }
            })

          if (this.amountError) {
            Text(this.amountError)
              .fontSize(12)
              .fontColor('#F44336')
              .margin({ top: 4 })
          }
        }
        .width('90%')
        .margin({ top: 24 })

        // 分类选择
        Column() {
          Text('分类')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          Grid() {
            ForEach(this.categoryArray, (category: CategoryType) => {
              GridItem() {
                Text(category)
                  .fontSize(14)
                  .padding({
                    left: 12,
                    right: 12,
                    top: 6,
                    bottom: 6
                  })
                  .borderRadius(16)
                  .backgroundColor(this.selectedCategory === category ? '#4CAF50' : '#F5F5F5')
                  .fontColor(this.selectedCategory === category ? '#FFFFFF' : '#333333')
              }
              .onClick(() => {
                this.selectedCategory = category;
              })
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsGap(8)
          .columnsGap(8)
          .width('100%')
        }
        .width('90%')
        .margin({ top: 24 })

        // 日期选择
        Column() {
          Text('日期')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          DatePicker({
            start: new Date('2000-01-01'),
            end: new Date('2100-12-31'),
            selected: this.parseDate(this.date)
          })
            .onChange((value: DatePickerResult) => {
              this.date = `${value.year}-${String(value.month + 1).padStart(2, '0')}-${String(value.day).padStart(2, '0')}`;
            })

          Text(`当前选择日期：${this.date}`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .width('90%')
        .margin({ top: 24 })

        // 备注输入
        Column() {
          Text('备注')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          TextInput({
            placeholder: '添加备注（可选）',
            text: this.remarkInput
          })
            .maxLength(50)
            .fontSize(14)
            .height(44)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({
              left: 12,
              right: 12
            })
            .onChange((value: string) => {
              // 忽略 TextInput 初始化时框架触发的空 onChange
              if (!this.remarkInitialized) {
                this.remarkInitialized = true;
                return;
              }
              this.remarkInput = value;
              this.onRemarkChange(value);
            })
          if (this.suggestedCategory) {
            Row() {
              Text('推荐分类：')
                .fontSize(14)
              Text(this.suggestedCategory)
                .fontSize(14)
                .fontColor('#007DFF')
                .fontWeight(FontWeight.Bold)
            }
            .margin({ top: 8 })
          }

         /* Text('DashScope API Key（可选，优先云端分类；仅保存在本机）')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
            .margin({ top: 16 })

          TextInput({
            placeholder: 'sk-…',
            text: this.cloudApiKeyInput
          })
            .fontSize(12)
            .height(40)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => {
              this.cloudApiKeyInput = value;
              CloudAiConfig.apiKey = value.trim();
            })
            .onBlur(() => {
              void this.persistCloudApiKey(this.cloudApiKeyInput);
            })*/
        }
        .width('90%')
        .margin({ top: 24 })



        if (this.isEdit) {
          Button('删除账单')
            .width('60%')
            .height(48)
            .fontSize(16)
            .backgroundColor('#F44336')
            .borderRadius(24)
            .margin({ top: 32 })
            .onClick(async () => {
              if (this.editBillId < 0) {
                this.amountError = '账单编号错误，无法删除';
                return;
              }

              await this.viewModel.deleteBill(this.editBillId);
              router.back();
            })
        }

        Blank()
          .height(40)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  async saveBill(): Promise<void> {
    // 快照所有状态，避免保存过程中异步操作干扰 @State 变量
    const snapAmount: string = this.amountInput.trim();
    const snapCategory: CategoryType = this.selectedCategory;
    const snapDate: string = this.date.trim();
    const snapRemark: string = this.remarkInput.trim();
    const snapIsEdit: boolean = this.isEdit;
    const snapEditId: number = this.editBillId;

    console.info(`saveBill: isEdit=${snapIsEdit}, id=${snapEditId}, amount="${snapAmount}", category="${snapCategory}", date="${snapDate}", remark="${snapRemark}"`);

    if (!snapAmount || snapAmount.length === 0) {
      this.amountError = '请输入金额';
      return;
    }

    if (!CurrencyUtil.isValidAmount(snapAmount)) {
      this.amountError = '请输入有效金额（最多两位小数）';
      return;
    }

    if (!snapDate || snapDate.length === 0) {
      this.amountError = '请选择日期';
      return;
    }

    try {
      let success = false;

      if (snapIsEdit) {
        if (snapEditId < 0) {
          this.amountError = '账单编号错误，无法修改';
          return;
        }

        success = await this.viewModel.updateBill(
          snapEditId,
          snapAmount,
          snapCategory,
          snapDate,
          snapRemark
        );
      } else {
        success = await this.viewModel.addBill(
          snapAmount,
          snapCategory,
          snapDate,
          snapRemark
        );
      }

      if (success) {
        router.back();
      } else {
        this.amountError = '保存失败，请重试';
      }
    } catch (error) {
      console.error('Error saving bill:', error);
      this.amountError = '保存失败，请重试';
    }
  }
}
