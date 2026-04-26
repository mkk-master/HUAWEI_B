// 文件路径: entry/src/main/ets/pages/AddBillPage.ets
import { BillViewModel } from '../viewmodel/BillViewModel';
import { CategoryType } from '../model/BillModel';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import router from '@ohos.router';
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
  @State date: string = new Date().toISOString().split('T')[0];
  @State remark: string = '';
  @State amountError: string = '';
  private viewModel: BillViewModel = new BillViewModel();
  private categoryArray: CategoryType[] = Object.values(CategoryType);

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('取消')
          .backgroundColor('#00000000')
          .fontColor('#666666')
          .onClick(() => router.back())

        Text('记一笔')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button('保存')
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .fontColor('#FFFFFF')
          .onClick(() => this.saveBill())
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

        TextInput({ placeholder: '0.00', text: this.amountInput })
          .type(InputType.Number)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .height(60)
          .border({ width: { bottom: this.amountError ? 2 : 1 }, color: this.amountError ? '#F44336' : '#E0E0E0' })
          .onChange((value: string) => {
            this.amountInput = value;
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
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
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
      Row() {
        Text('日期')
          .fontSize(14)
          .fontColor('#666666')
        DatePicker({
          start: new Date('2000-1-1'),
          end: new Date('2100-12-31'),
          selected: new Date(this.date)
        })
          .onChange((value: DatePickerResult) => {
            this.date = `${value.year}-${String(value.month + 1).padStart(2, '0')}-${String(value.day).padStart(2, '0')}`;
          })
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 24 })

      // 备注输入
      Column() {
        Text('备注')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '添加备注（可选）', text: this.remark })
          .maxLength(50)
          .fontSize(14)
          .height(40)
          .border({ width: { bottom: 1 }, color: '#E0E0E0' })
          .onChange((value: string) => {
            this.remark = value;
          })
      }
      .width('90%')
      .margin({ top: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  async saveBill(): Promise<void> {
    if (!this.amountInput || this.amountError) {
      // 提示错误
      return;
    }

    const success = await this.viewModel.addBill(
      this.amountInput,
      this.selectedCategory,
      this.date,
      this.remark
    );

    if (success) {
      router.back();
    }
  }
}