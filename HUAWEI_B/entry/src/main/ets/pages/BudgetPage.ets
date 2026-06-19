// 文件路径: entry/src/main/ets/pages/BudgetPage.ets
import { BillViewModel } from '../viewmodel/BillViewModel';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import { DatabaseHelper } from '../database/DatabaseHelper';
import router from '@ohos.router';

@Entry
@Component
struct BudgetPage {
  @State budgetInput: string = '';
  @State currentBudget: string = '';
  @State inputError: string = '';
  @State Budget_Tip: string = '';
  @State selectedMonth: string = this.formatMonth(new Date());
  @State refreshFlag: number = 0;

  private viewModel: BillViewModel = new BillViewModel();
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  private formatMonth(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    return `${year}-${month}`;
  }

  private parseMonth(month: string): Date {
    const parts = month.split('-');

    if (parts.length !== 2) {
      return new Date();
    }

    const year = Number(parts[0]);
    const monthIndex = Number(parts[1]) - 1;

    if (isNaN(year) || isNaN(monthIndex)) {
      return new Date();
    }

    return new Date(year, monthIndex, 1);
  }

  private fenToPlainYuan(fen: number): string {
    return (fen / 100).toFixed(2);
  }

  async aboutToAppear(): Promise<void> {
    await this.dbHelper.initDatabase(getContext(this));
    await this.viewModel.init();

    this.selectedMonth = this.viewModel.currentMonth;

    const params = router.getParams() as Record<string, Object>;
    if (params && params['month']) {
      const monthParam = String(params['month']);
      if (monthParam.length === 7) {
        this.selectedMonth = monthParam;
      }
    }

    await this.loadSelectedMonthBudget();

    console.info('BudgetPage initialized, selected month:', this.selectedMonth, 'current budget:', this.currentBudget);
  }

  async loadSelectedMonthBudget(): Promise<void> {
    const budgetFen = await this.viewModel.getBudgetForMonth(this.selectedMonth);

    this.currentBudget = this.fenToPlainYuan(budgetFen);

    if (budgetFen > 0) {
      this.budgetInput = this.currentBudget;
    } else {
      this.budgetInput = '';
    }

    this.inputError = '';
    this.refreshFlag++;
  }

  async goPreviousMonth(): Promise<void> {
    const date = this.parseMonth(this.selectedMonth);
    date.setMonth(date.getMonth() - 1);
    this.selectedMonth = this.formatMonth(date);

    await this.loadSelectedMonthBudget();
  }

  async goNextMonth(): Promise<void> {
    const date = this.parseMonth(this.selectedMonth);
    date.setMonth(date.getMonth() + 1);
    this.selectedMonth = this.formatMonth(date);

    await this.loadSelectedMonthBudget();
  }

  async goCurrentMonth(): Promise<void> {
    this.selectedMonth = this.formatMonth(new Date());

    await this.loadSelectedMonthBudget();
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

        Text('设置预算')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(56)
      }
      .width('90%')
      .height(48)

      Row() {
        Button('上月')
          .fontSize(13)
          .height(36)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .borderRadius(18)
          .onClick(async () => {
            await this.goPreviousMonth();
          })

        Blank()

        Text(this.selectedMonth)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Button('下月')
          .fontSize(13)
          .height(36)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .borderRadius(18)
          .onClick(async () => {
            await this.goNextMonth();
          })

        Button('本月')
          .fontSize(13)
          .height(36)
          .backgroundColor('#4CAF50')
          .fontColor('#FFFFFF')
          .borderRadius(18)
          .margin({ left: 8 })
          .onClick(async () => {
            await this.goCurrentMonth();
          })
      }
      .width('90%')
      .height(44)
      .margin({
        top: 12,
        bottom: 16
      })

      Column() {
        Text(`${this.selectedMonth} 月度预算`)
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 16 })

        if (this.currentBudget !== '0.00') {
          Text(`当前预算：${this.currentBudget} 元`)
            .fontSize(14)
            .fontColor('#999999')
            .margin({ bottom: 16 })
        } else {
          Text('当前月份还没有设置预算')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ bottom: 16 })
        }

        TextInput({
          placeholder: '请输入预算金额',
          text: this.budgetInput
        })
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .maxLength(12)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding(12)
          .onChange((value: string) => {
            this.budgetInput = value;

            if (value.length > 0 && !CurrencyUtil.isValidAmount(value)) {
              this.inputError = '请输入有效金额（最多两位小数）';
            } else {
              this.inputError = '';
            }
          })

        if (this.inputError) {
          Text(this.inputError)
            .fontSize(14)
            .fontColor('#F44336')
            .margin({ top: 8 })
        }

        Row() {
          this.buildQuickAmountButton('1000')
          this.buildQuickAmountButton('2000')
          this.buildQuickAmountButton('5000')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ top: 24 })

        Button(`保存 ${this.selectedMonth} 预算`)
          .width('70%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#4CAF50')
          .borderRadius(24)
          .margin({ top: 32 })
          .enabled(!this.inputError && this.budgetInput.length > 0)
          .opacity(this.inputError || this.budgetInput.length === 0 ? 0.5 : 1)
          .onClick(() => {
            this.saveBudget();
          })
      }
      .width('80%')
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildQuickAmountButton(amount: string) {
    Button(`${amount}元`)
      .fontSize(14)
      .backgroundColor('#E3F2FD')
      .fontColor('#1976D2')
      .borderRadius(8)
      .padding({
        left: 12,
        right: 12,
        top: 6,
        bottom: 6
      })
      .onClick(() => {
        this.budgetInput = amount;
        this.inputError = '';
      })
  }

  async saveBudget(): Promise<void> {
    console.info('saveBudget called, month:', this.selectedMonth, 'amount:', this.budgetInput);

    if (!this.budgetInput || this.budgetInput.trim().length === 0) {
      this.inputError = '请输入预算金额';
      return;
    }

    if (!CurrencyUtil.isValidAmount(this.budgetInput)) {
      this.inputError = '请输入有效金额（最多两位小数）';
      return;
    }

    try {
      const success = await this.viewModel.setBudgetForMonth(
        this.selectedMonth,
        this.budgetInput.trim()
      );

      if (success) {
        await this.loadSelectedMonthBudget();

        AlertDialog.show({
          title: '保存成功',
          message: `${this.selectedMonth} 的预算已更新`,
          confirm: {
            value: '确定',
            action: () => {
              router.back();
            }
          },
          cancel: () => {}
        });
      } else {
        this.inputError = '保存失败，请重试';
      }
    } catch (error) {
      console.error('Error saving budget:', error);
      this.inputError = '保存失败，请重试';
    }
  }
}