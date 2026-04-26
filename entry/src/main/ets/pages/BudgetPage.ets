// 文件路径: entry/src/main/ets/pages/BudgetPage.ets
import { BillViewModel } from '../viewmodel/BillViewModel';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import router from '@ohos.router';

@Entry
@Component
struct BudgetPage {
  @State budgetInput: string = '';
  @State currentBudget: string = '';
  @State inputError: string = '';
  private viewModel: BillViewModel = new BillViewModel();

  async aboutToAppear(): Promise<void> {
    await this.viewModel.loadBudget();
    this.currentBudget = CurrencyUtil.fenToYuan(this.viewModel.monthlyBudget);
    this.budgetInput = this.currentBudget;
  }

  build() {
    Column() {
      Row() {
        Button('返回')
          .backgroundColor('#00000000')
          .fontColor('#4CAF50')
          .onClick(() => router.back())

        Text('设置预算')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('90%')
      .height(48)

      Column() {
        Text(`${this.viewModel.currentMonth} 月度预算`)
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 16 })

        TextInput({ placeholder: '请输入预算金额', text: this.budgetInput })
          .type(InputType.Number)
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .maxLength(12)
          .onChange((value: string) => {
            this.budgetInput = value;
            if (!CurrencyUtil.isValidAmount(value)) {
              this.inputError = '请输入有效金额';
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

        Button('保存预算')
          .width('60%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#4CAF50')
          .borderRadius(24)
          .margin({ top: 32 })
          .enabled(!this.inputError && this.budgetInput.length > 0)
          .opacity(this.inputError || this.budgetInput.length === 0 ? 0.5 : 1)
          .onClick(async () => {
            const success = await this.viewModel.setBudget(this.budgetInput);
            if (success) {
              router.back();
            }
          })
      }
      .width('80%')
      .margin({ top: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}