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
  @State Budget_Tip:string ='';
  private viewModel: BillViewModel = new BillViewModel();
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.dbHelper.initDatabase(getContext(this));
    await this.viewModel.init();
    await this.viewModel.loadBudget();
    this.currentBudget = CurrencyUtil.fenToYuan(this.viewModel.monthlyBudget);
    this.budgetInput = this.currentBudget;

    console.info('BudgetPage initialized, current budget:', this.currentBudget);
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
          //.type(InputType.Number)
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .maxLength(12)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding(12)
          .onChange((value: string) => {
            //this.checkoutInput();
            this.budgetInput = value;
            if (value.length > 0 && !CurrencyUtil.isValidAmount(value)) {
              this.inputError = '请输入有效金额（最多两位小数）';
            } else {
              this.inputError = '';
            }
          })

       /* Text(this.Budget_Tip)
          .fontColor('#F5222D')
          .fontSize(18)
          .margin(12)*/

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

        Button('保存预算')
          .width('60%')
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
      .margin({ top: 40 })
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
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .onClick(() => {
        this.budgetInput = amount;
        this.inputError = '';
      })
  }

  async saveBudget(): Promise<void> {
    console.info('saveBudget called, amount:', this.budgetInput);

    // 验证金额
    if (!this.budgetInput || this.budgetInput.trim().length === 0) {
      this.inputError = '请输入预算金额';
      console.error('Budget amount is empty');
      return;
    }

    if (!CurrencyUtil.isValidAmount(this.budgetInput)) {
      this.inputError = '请输入有效金额（最多两位小数）';
      console.error('Invalid budget amount:', this.budgetInput);
      return;
    }

    try {
      console.info('Setting budget:', this.budgetInput);
      const success = await this.viewModel.setBudget(this.budgetInput);
      console.info('Set budget result:', success);

      if (success) {
        // 添加成功弹窗
        AlertDialog.show({
          title: '保存成功',
          message: '预算设置已更新',
          confirm: {
            value: '确定',
            action: () => {
              console.info('Budget saved, going back');
              router.back(); // 关闭弹窗后返回上一页
            }
          },
          cancel: () => {} // 空取消回调
        });
      } else {
        console.error('Failed to save budget');
        this.inputError = '保存失败，请重试';
      }
    } catch (error) {
      console.error('Error saving budget:', error);
      this.inputError = '保存失败，请重试';
    }
  }

  /*private checkoutInput() {
    let num1 = Number(this.budgetInput);
    if ((isNaN(num1) || num1 < 0) && this.budgetInput != "") {
      this.Budget_Tip = "请输入大于 0 的数字";
    }
  }*/

}